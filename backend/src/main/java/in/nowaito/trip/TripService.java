package in.nowaito.trip;

import in.nowaito.driver.DriverQueueService;
import in.nowaito.driver.DriverRepository;
import in.nowaito.payment.PaymentService;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.NoSuchElementException;
import java.util.UUID;

@Service
public class TripService {

    private final TripRepository tripRepository;
    private final DriverQueueService queueService;
    private final DriverRepository driverRepository;
    private final PaymentService paymentService;

    public TripService(TripRepository tripRepository, DriverQueueService queueService,
                        DriverRepository driverRepository, PaymentService paymentService) {
        this.tripRepository = tripRepository;
        this.queueService = queueService;
        this.driverRepository = driverRepository;
        this.paymentService = paymentService;
    }

    public Trip get(UUID tripId) {
        return tripRepository.findById(tripId).orElseThrow(() -> new NoSuchElementException("Trip not found"));
    }

    /** Used by the driver app to discover its currently-assigned trip (in place of a push notification in this MVP). */
    public Trip activeForDriver(UUID driverId) {
        return tripRepository.findByDriverIdOrderByRequestedAtDesc(driverId).stream()
                .filter(t -> t.getStatus() == TripStatus.DRIVER_ASSIGNED || t.getStatus() == TripStatus.ARRIVED || t.getStatus() == TripStatus.IN_PROGRESS)
                .findFirst()
                .orElse(null);
    }

    /** Driver taps "Arrived" at pickup. */
    public Trip markArrived(UUID tripId) {
        Trip trip = get(tripId);
        trip.setStatus(TripStatus.ARRIVED);
        return tripRepository.save(trip);
    }

    /** Driver taps "Start Trip" after rider verification (photo + plate check). */
    public Trip start(UUID tripId) {
        Trip trip = get(tripId);
        trip.setStatus(TripStatus.IN_PROGRESS);
        trip.setStartedAt(Instant.now());
        return tripRepository.save(trip);
    }

    /** Drop-off: locked fare is captured (see PaymentService), driver returns to the back of the queue. */
    public Trip complete(UUID tripId) {
        Trip trip = get(tripId);
        trip.setStatus(TripStatus.COMPLETED);
        trip.setCompletedAt(Instant.now());
        tripRepository.save(trip);

        paymentService.capture("order_mock_" + trip.getId(), trip.getLockedFare() + trip.getGuaranteeFee());

        if (trip.getDriverId() != null) {
            driverRepository.findById(trip.getDriverId()).ifPresent(driver ->
                    queueService.returnToBackOfQueue(driver.getId(), trip.getZoneId(), trip.getVehicleType()));
        }
        return trip;
    }

    /** Driver taps "No Show" after the 5-minute wait — returns to queue, no penalty. */
    public Trip driverNoShow(UUID tripId) {
        Trip trip = get(tripId);
        trip.setStatus(TripStatus.CANCELLED_RIDER);
        trip.setCancelledAt(Instant.now());
        tripRepository.save(trip);

        if (trip.getDriverId() != null) {
            driverRepository.findById(trip.getDriverId()).ifPresent(driver ->
                    queueService.returnToBackOfQueue(driver.getId(), trip.getZoneId(), trip.getVehicleType()));
        }
        return trip;
    }
}
