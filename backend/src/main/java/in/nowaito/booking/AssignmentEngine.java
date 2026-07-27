package in.nowaito.booking;

import in.nowaito.driver.Driver;
import in.nowaito.driver.DriverQueueService;
import in.nowaito.driver.DriverRepository;
import in.nowaito.trip.Trip;
import in.nowaito.trip.TripRepository;
import in.nowaito.trip.TripStatus;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * AssignmentEngine — NoWaito's core differentiator.
 * <p>
 * Step 1 (Rider Books) and Step 2 (Zone Identified) happen in BookingService
 * before this is called. This class implements steps 3-6 from the business
 * doc: queue check, distance-band filter, instant assignment, and the
 * 90-second emergency reassignment guarantee.
 */
@Service
public class AssignmentEngine {

    /** Business-doc promise: reassign within this window after a driver emergency-cancels. */
    public static final int REASSIGNMENT_TARGET_SECONDS = 90;

    private final DriverQueueService queueService;
    private final DriverRepository driverRepository;
    private final TripRepository tripRepository;

    public AssignmentEngine(DriverQueueService queueService, DriverRepository driverRepository, TripRepository tripRepository) {
        this.queueService = queueService;
        this.driverRepository = driverRepository;
        this.tripRepository = tripRepository;
    }

    /**
     * Attempts to assign the next eligible driver to a trip that's already
     * been priced and saved with status SEARCHING. Mutates and persists the
     * Trip. Returns the updated Trip either way (status reflects outcome).
     */
    public Trip assign(Trip trip) {
        Optional<UUID> driverId = queueService.assignNextDriver(
                trip.getZoneId(), trip.getVehicleType(), driverRequiredBand(trip));

        if (driverId.isEmpty()) {
            trip.setStatus(TripStatus.NO_DRIVER_AVAILABLE);
            return tripRepository.save(trip);
        }

        trip.setDriverId(driverId.get());
        trip.setStatus(TripStatus.DRIVER_ASSIGNED);
        trip.setAssignedAt(Instant.now());
        return tripRepository.save(trip);
    }

    /**
     * Called when a driver emergency-cancels mid-trip (Tier 1, verified).
     * Puts the trip back into SEARCHING and immediately tries the next
     * driver in queue — this is the "within 90 seconds" guarantee. The
     * caller (CancellationService) is responsible for measuring/logging
     * actual elapsed time against {@link #REASSIGNMENT_TARGET_SECONDS}
     * so it shows up in your pilot metrics, not just as a marketing claim.
     */
    public Trip reassignAfterEmergency(Trip trip) {
        trip.setDriverId(null);
        trip.setStatus(TripStatus.SEARCHING);
        trip.setReassignmentCount(trip.getReassignmentCount() + 1);
        return assign(trip);
    }

    private in.nowaito.driver.DistanceBand driverRequiredBand(Trip trip) {
        double km = trip.getDistanceKm();
        if (km <= 8) return in.nowaito.driver.DistanceBand.SHORT;
        if (km <= 20) return in.nowaito.driver.DistanceBand.MEDIUM;
        return in.nowaito.driver.DistanceBand.LONG;
    }
}
