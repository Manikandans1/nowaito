package in.nowaito.booking;

import in.nowaito.trip.Trip;
import in.nowaito.vehicle.PricingEngine;
import in.nowaito.vehicle.VehicleType;
import jakarta.validation.constraints.NotNull;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/bookings")
public class BookingController {

    private final BookingService bookingService;

    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    /** Mirrors the rider Home screen's vehicle-selection sheet: one quote per vehicle type. */
    @GetMapping("/quote")
    public PricingEngine.Quote quote(
            @RequestParam VehicleType vehicleType,
            @RequestParam double distanceKm,
            @RequestParam(defaultValue = "false") boolean peakActive) {
        return bookingService.getQuote(vehicleType, distanceKm, peakActive);
    }

    @PostMapping
    public Trip createBooking(@org.springframework.web.bind.annotation.RequestBody @NotNull CreateBookingDto dto) {
        var req = new BookingService.BookingRequest(
                dto.riderId(), dto.zoneId(), dto.vehicleType(),
                dto.pickupLat(), dto.pickupLng(), dto.pickupLabel(),
                dto.dropLat(), dto.dropLng(), dto.dropLabel(),
                dto.distanceKm(), dto.peakActive());
        return bookingService.createBooking(req);
    }

    public record CreateBookingDto(
            UUID riderId, UUID zoneId, VehicleType vehicleType,
            double pickupLat, double pickupLng, String pickupLabel,
            double dropLat, double dropLng, String dropLabel,
            double distanceKm, boolean peakActive
    ) {}
}
