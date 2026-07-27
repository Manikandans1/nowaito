package in.nowaito.driver;

import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/drivers")
public class DriverController {

    private final DriverRepository driverRepository;
    private final DriverQueueService queueService;

    public DriverController(DriverRepository driverRepository, DriverQueueService queueService) {
        this.driverRepository = driverRepository;
        this.queueService = queueService;
    }

    @GetMapping("/{id}")
    public Driver get(@PathVariable UUID id) {
        return driverRepository.findById(id).orElseThrow();
    }

    /** Convenience for local/pilot testing - lets you find the seeded demo driver IDs easily. */
    @GetMapping
    public java.util.List<Driver> all() {
        return driverRepository.findAll();
    }

    @PostMapping
    public Driver create(@RequestBody Driver driver) {
        return driverRepository.save(driver);
    }

    /** Driver toggles online - joins the zone+vehicle-type round-robin queue. */
    @PostMapping("/{id}/online")
    public Driver goOnline(@PathVariable UUID id) {
        Driver driver = driverRepository.findById(id).orElseThrow();
        if (driver.getVerificationStatus() != Driver.VerificationStatus.VERIFIED) {
            throw new IllegalStateException("Driver KYC not verified yet");
        }
        if (driver.isSuspended()) {
            throw new IllegalStateException("Driver is currently suspended");
        }
        driver.setOnline(true);
        driverRepository.save(driver);
        queueService.joinQueue(driver.getId(), driver.getHomeZoneId(), driver.getVehicleType());
        return driver;
    }

    @PostMapping("/{id}/offline")
    public Driver goOffline(@PathVariable UUID id) {
        Driver driver = driverRepository.findById(id).orElseThrow();
        driver.setOnline(false);
        driverRepository.save(driver);
        queueService.leaveQueue(driver.getId(), driver.getHomeZoneId(), driver.getVehicleType());
        return driver;
    }

    @GetMapping("/{id}/queue-position")
    public long queuePosition(@PathVariable UUID id) {
        Driver driver = driverRepository.findById(id).orElseThrow();
        return queueService.queuePosition(driver.getId(), driver.getHomeZoneId(), driver.getVehicleType());
    }

    @PostMapping("/{id}/distance-preference")
    public Driver setDistancePreference(@PathVariable UUID id, @RequestParam DistanceBand band) {
        Driver driver = driverRepository.findById(id).orElseThrow();
        driver.setDistancePreference(band);
        return driverRepository.save(driver);
    }
}
