package in.nowaito.auth;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Random;

/**
 * Local/free-tier OTP flow: generates a 4-digit code, stores it in Redis
 * with a 5-minute TTL, and (for now) just logs it to the console instead
 * of sending a real SMS — so the pilot runs at zero SMS cost. Once you
 * move to Firebase Auth's free phone-OTP quota, replace requestOtp/verifyOtp
 * internals with the Firebase Admin SDK call; AuthController doesn't need
 * to change.
 */
@Service
public class OtpService {

    private final StringRedisTemplate redis;
    private final Random random = new Random();

    public OtpService(StringRedisTemplate redis) {
        this.redis = redis;
    }

    private String key(String phone) {
        return "otp:" + phone;
    }

    public String requestOtp(String phone) {
        String code = String.format("%04d", random.nextInt(10000));
        redis.opsForValue().set(key(phone), code, Duration.ofMinutes(5));
        // TODO (paid upgrade): send via Firebase Auth / Twilio / Gupshup instead of logging.
        System.out.println("[DEV OTP] " + phone + " -> " + code);
        return code; // returned only in local/dev profile responses for easy testing
    }

    public boolean verifyOtp(String phone, String code) {
        String stored = redis.opsForValue().get(key(phone));
        boolean ok = stored != null && stored.equals(code);
        if (ok) redis.delete(key(phone));
        return ok;
    }
}
