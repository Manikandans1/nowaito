package in.nowaito.booking;

import in.nowaito.payment.PaymentService;
import in.nowaito.trip.Trip;
import in.nowaito.trip.TripRepository;
import in.nowaito.trip.TripStatus;
import in.nowaito.vehicle.PricingEngine;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Service
public class BookingService {

    private final PricingEngine pricingEngine;
    private final AssignmentEngine assignmentEngine;
    private final TripRepository tripRepository;
    private final PaymentService paymentService;

    private static final int FREE_CANCEL_WINDOW_MINUTES = 3;

    public BookingService(PricingEngine pricingEngine, AssignmentEngine assignmentEngine,
                           TripRepository tripRepository, PaymentService paymentService) {
        this.pricingEngine = pricingEngine;
        this.assignmentEngine = assignmentEngine;
        this.tripRepository = tripRepository;
        this.paymentService = paymentService;
    }

    /** Step 1+2 of the business doc: rider books, fare is locked, zone identified by the caller. */
    public PricingEngine.Quote getQuote(in.nowaito.vehicle.VehicleType vehicleType, double distanceKm, boolean peakActive) {
        return pricingEngine.quote(vehicleType, distanceKm, peakActive);
    }

    /** Confirms the booking at the exact quoted price, then hands off to the assignment engine. */
    public Trip createBooking(BookingRequest req) {
        PricingEngine.Quote quote = pricingEngine.quote(req.vehicleType(), req.distanceKm(), req.peakActive());

        Trip trip = new Trip();
        trip.setRiderId(req.riderId());
        trip.setZoneId(req.zoneId());
        trip.setVehicleType(req.vehicleType());
        trip.setPickupLat(req.pickupLat());
        trip.setPickupLng(req.pickupLng());
        trip.setPickupLabel(req.pickupLabel());
        trip.setDropLat(req.dropLat());
        trip.setDropLng(req.dropLng());
        trip.setDropLabel(req.dropLabel());
        trip.setDistanceKm(req.distanceKm());
        trip.setLockedFare(quote.fare());
        trip.setGuaranteeFee(quote.guaranteeFee());
        trip.setPeakRateApplied(quote.peakActive());
        trip.setStatus(TripStatus.SEARCHING);
        trip.setFreeCancelDeadline(Instant.now().plus(FREE_CANCEL_WINDOW_MINUTES, ChronoUnit.MINUTES));
        trip = tripRepository.save(trip);

        // Pre-authorize (hold, not yet charged) the rider's payment method for fare + guarantee fee.
        paymentService.preAuthorize(trip.getId(), quote.total());

        // Round-robin assignment happens immediately — no waiting for a driver to "accept".
        return assignmentEngine.assign(trip);
    }

    public record BookingRequest(
            java.util.UUID riderId,
            java.util.UUID zoneId,
            in.nowaito.vehicle.VehicleType vehicleType,
            double pickupLat, double pickupLng, String pickupLabel,
            double dropLat, double dropLng, String dropLabel,
            double distanceKm,
            boolean peakActive
    ) {}
}
