package in.nowaito.auth;

import in.nowaito.rider.Rider;
import in.nowaito.rider.RiderRepository;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final OtpService otpService;
    private final JwtUtil jwtUtil;
    private final RiderRepository riderRepository;

    public AuthController(OtpService otpService, JwtUtil jwtUtil, RiderRepository riderRepository) {
        this.otpService = otpService;
        this.jwtUtil = jwtUtil;
        this.riderRepository = riderRepository;
    }

    public record RequestOtpDto(String phone) {}
    public record VerifyOtpDto(String phone, String code, String role) {} // role: "RIDER" | "DRIVER"
    public record AuthResponse(String token, String userId, boolean isNewUser) {}

    @PostMapping("/request-otp")
    public java.util.Map<String, String> requestOtp(@RequestBody RequestOtpDto dto) {
        String devCode = otpService.requestOtp(dto.phone());
        // devCode is only useful while you're on the free/local profile without real SMS wired up.
        return java.util.Map.of("status", "sent", "devOnlyCode", devCode);
    }

    @PostMapping("/verify-otp")
    public AuthResponse verifyOtp(@RequestBody VerifyOtpDto dto) {
        boolean valid = otpService.verifyOtp(dto.phone(), dto.code());
        if (!valid) throw new IllegalArgumentException("Invalid or expired OTP");

        if ("DRIVER".equalsIgnoreCase(dto.role())) {
            String token = jwtUtil.issueToken(dto.phone(), "DRIVER");
            return new AuthResponse(token, dto.phone(), false);
        }

        Rider rider = riderRepository.findByPhone(dto.phone()).orElseGet(() -> {
            Rider r = new Rider();
            r.setPhone(dto.phone());
            return riderRepository.save(r);
        });
        String token = jwtUtil.issueToken(rider.getId().toString(), "RIDER");
        return new AuthResponse(token, rider.getId().toString(), true);
    }
}
