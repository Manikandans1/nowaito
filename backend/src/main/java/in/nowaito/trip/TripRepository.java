package in.nowaito.trip;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TripRepository extends JpaRepository<Trip, UUID> {
    List<Trip> findByRiderIdOrderByRequestedAtDesc(UUID riderId);
    List<Trip> findByDriverIdOrderByRequestedAtDesc(UUID driverId);
}
