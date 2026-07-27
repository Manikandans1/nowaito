package in.nowaito.config;

import in.nowaito.driver.Driver;
import in.nowaito.driver.DistanceBand;
import in.nowaito.driver.DriverRepository;
import in.nowaito.vehicle.VehicleType;
import in.nowaito.zone.Zone;
import in.nowaito.zone.ZoneRepository;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
public class DevDataSeeder {

    private final ZoneRepository zoneRepository;
    private final DriverRepository driverRepository;

    public DevDataSeeder(ZoneRepository zoneRepository, DriverRepository driverRepository) {
        this.zoneRepository = zoneRepository;
        this.driverRepository = driverRepository;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void seed() {
        if (zoneRepository.count() > 0) return; // already seeded

        Zone koramangala = zoneRepository.save(new Zone("Koramangala", "Bangalore", false, 12.9352, 77.6146));
        Zone tnagar = zoneRepository.save(new Zone("T. Nagar", "Chennai", true, 13.0418, 80.2341));

        seedDriver("Manjunath R.", "9000000001", VehicleType.CAR, "Wagon R", "KA 05 MJ 8821", koramangala.getId());
        seedDriver("Suresh M.", "9000000002", VehicleType.AUTO, "Bajaj Auto", "TN 09 AU 7745", tnagar.getId());
        seedDriver("Ravi K.", "9000000003", VehicleType.BIKE, "Honda Activa", "TN 09 BK 2210", tnagar.getId());

        System.out.println("[DevDataSeeder] Seeded 2 zones (Koramangala, T. Nagar) and 3 demo drivers.");
    }

    private void seedDriver(String name, String phone, VehicleType type, String label, String plate, java.util.UUID zoneId) {
        Driver d = new Driver();
        d.setName(name);
        d.setPhone(phone);
        d.setVehicleType(type);
        d.setVehicleLabel(label);
        d.setPlateNumber(plate);
        d.setHomeZoneId(zoneId);
        d.setDistancePreference(DistanceBand.MEDIUM);
        d.setVerificationStatus(Driver.VerificationStatus.VERIFIED);
        driverRepository.save(d);
    }
}
