package in.nowaito.zone;

import in.nowaito.driver.DriverRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class ZoneService {

    private final ZoneRepository zoneRepository;
    private final DriverRepository driverRepository;

    @Value("${nowaito.zone.min-drivers-to-launch:20}")
    private int minDriversToLaunch;

    @Value("${nowaito.zone.health-floor:10}")
    private int healthFloor;

    public ZoneService(ZoneRepository zoneRepository, DriverRepository driverRepository) {
        this.zoneRepository = zoneRepository;
        this.driverRepository = driverRepository;
    }

    public List<Zone> all() {
        return zoneRepository.findAll();
    }

    public record ZoneHealth(UUID zoneId, String name, long activeDrivers, boolean healthy, boolean readyToLaunch) {}

    public ZoneHealth health(Zone zone) {
        long activeDrivers = driverRepository.countByHomeZoneIdAndOnlineTrue(zone.getId());
        boolean healthy = activeDrivers >= healthFloor;
        boolean readyToLaunch = activeDrivers >= minDriversToLaunch;
        return new ZoneHealth(zone.getId(), zone.getName(), activeDrivers, healthy, readyToLaunch);
    }

    public List<ZoneHealth> allZoneHealth() {
        return zoneRepository.findAll().stream().map(this::health).toList();
    }
}
