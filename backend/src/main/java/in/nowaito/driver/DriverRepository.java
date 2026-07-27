package in.nowaito.driver;

import in.nowaito.vehicle.VehicleType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DriverRepository extends JpaRepository<Driver, UUID> {
    Optional<Driver> findByPhone(String phone);
    long countByHomeZoneIdAndOnlineTrue(UUID zoneId);
    List<Driver> findByHomeZoneIdAndVehicleType(UUID zoneId, VehicleType vehicleType);
}
