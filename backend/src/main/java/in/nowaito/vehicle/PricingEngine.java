package in.nowaito.vehicle;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Pricing engine: base rate + per-km rate + peak buffer = the fare shown at
 * search. Once a rider confirms, the controller stores this exact figure as
 * the Booking's lockedFare — it must never be recalculated after that point.
 */
@Service
public class PricingEngine {

    private final PricingProperties pricingProperties;

    // base fare (rupees), per-km rate (rupees), per the original business model.
    private static final BigDecimal BIKE_BASE = BigDecimal.valueOf(20);
    private static final BigDecimal BIKE_PER_KM = BigDecimal.valueOf(6);
    private static final BigDecimal AUTO_BASE = BigDecimal.valueOf(30);
    private static final BigDecimal AUTO_PER_KM = BigDecimal.valueOf(11);
    private static final BigDecimal CAR_BASE = BigDecimal.valueOf(40);
    private static final BigDecimal CAR_PER_KM = BigDecimal.valueOf(15);

    /** Every base price includes this profitability buffer for moderate peak periods. */
    private static final BigDecimal BASE_BUFFER_MULTIPLIER = BigDecimal.valueOf(1.18);

    /** Applied on top only when the zone is flagged "peak" (e.g. by live demand/supply ratio). */
    private static final BigDecimal PEAK_MULTIPLIER = BigDecimal.valueOf(1.25);

    public PricingEngine(PricingProperties pricingProperties) {
        this.pricingProperties = pricingProperties;
    }

    public record Quote(int fare, int guaranteeFee, int total, boolean peakActive) {}

    public Quote quote(VehicleType vehicleType, double distanceKm, boolean peakActive) {
        BigDecimal base;
        BigDecimal perKm;
        switch (vehicleType) {
            case BIKE -> { base = BIKE_BASE; perKm = BIKE_PER_KM; }
            case AUTO -> { base = AUTO_BASE; perKm = AUTO_PER_KM; }
            default -> { base = CAR_BASE; perKm = CAR_PER_KM; }
        }

        BigDecimal raw = base.add(perKm.multiply(BigDecimal.valueOf(distanceKm)));
        BigDecimal withBuffer = raw.multiply(BASE_BUFFER_MULTIPLIER);
        BigDecimal finalFare = peakActive ? withBuffer.multiply(PEAK_MULTIPLIER) : withBuffer;

        int fareRounded = finalFare.setScale(0, RoundingMode.HALF_UP).intValue();
        int fee = pricingProperties.feeFor(vehicleType);
        return new Quote(fareRounded, fee, fareRounded + fee, peakActive);
    }
}
