package in.nowaito.cancellation;

import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/cancellations")
public class CancellationController {

    private final CancellationService cancellationService;

    public CancellationController(CancellationService cancellationService) {
        this.cancellationService = cancellationService;
    }

    @PostMapping("/rider/{tripId}")
    public CancellationRecord riderCancel(@PathVariable UUID tripId) {
        return cancellationService.riderCancel(tripId);
    }

    @PostMapping("/driver/{tripId}/emergency")
    public Object driverEmergencyCancel(@PathVariable UUID tripId,
                                         @RequestParam UUID driverId,
                                         @RequestParam(defaultValue = "false") boolean photoProofProvided) {
        return cancellationService.driverEmergencyCancel(tripId, driverId, photoProofProvided);
    }
}
