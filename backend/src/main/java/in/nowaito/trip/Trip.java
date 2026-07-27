package in.nowaito.trip;

import in.nowaito.vehicle.VehicleType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "trips")
@Getter
@Setter
@NoArgsConstructor
public class Trip {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false)
    private UUID riderId;

    private UUID driverId; // null until assigned

    @Column(nullable = false)
    private UUID zoneId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VehicleType vehicleType;

    private double pickupLat;
    private double pickupLng;
    private String pickupLabel;

    private double dropLat;
    private double dropLng;
    private String dropLabel;

    private double distanceKm;

    /** Locked at booking time. NEVER recalculated after this point, regardless of traffic/weather/demand. */
    @Column(nullable = false)
    private int lockedFare;

    @Column(nullable = false)
    private int guaranteeFee;

    @Column(nullable = false)
    private boolean peakRateApplied;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TripStatus status = TripStatus.SEARCHING;

    /** How many times the assignment engine has had to reassign after a driver emergency-cancelled. */
    private int reassignmentCount = 0;

    @Column(nullable = false)
    private Instant requestedAt = Instant.now();
    private Instant assignedAt;
    private Instant startedAt;
    private Instant completedAt;
    private Instant cancelledAt;

    /** Free-cancellation window deadline for the rider (requestedAt + N minutes). */
    private Instant freeCancelDeadline;
}
