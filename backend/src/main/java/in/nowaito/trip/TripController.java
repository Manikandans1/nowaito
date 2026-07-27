package in.nowaito.trip;

import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/trips")
public class TripController {

    private final TripService tripService;

    public TripController(TripService tripService) {
        this.tripService = tripService;
    }

    @GetMapping("/{id}")
    public Trip get(@PathVariable UUID id) {
        return tripService.get(id);
    }

    @GetMapping("/driver/{driverId}/active")
    public Trip activeForDriver(@PathVariable UUID driverId) {
        return tripService.activeForDriver(driverId);
    }

    @PostMapping("/{id}/arrived")
    public Trip arrived(@PathVariable UUID id) {
        return tripService.markArrived(id);
    }

    @PostMapping("/{id}/start")
    public Trip start(@PathVariable UUID id) {
        return tripService.start(id);
    }

    @PostMapping("/{id}/complete")
    public Trip complete(@PathVariable UUID id) {
        return tripService.complete(id);
    }

    @PostMapping("/{id}/no-show")
    public Trip noShow(@PathVariable UUID id) {
        return tripService.driverNoShow(id);
    }
}
