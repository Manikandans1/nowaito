package in.nowaito.driver;

import in.nowaito.vehicle.VehicleType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "drivers")
@Getter
@Setter
@NoArgsConstructor
public class Driver {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String phone;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VehicleType vehicleType;

    private String vehicleLabel;   // e.g. "Wagon R", "Honda Activa"
    private String plateNumber;

    @Column(nullable = false)
    private UUID homeZoneId;

    @Enumerated(EnumType.STRING)
    private DistanceBand distancePreference = DistanceBand.MEDIUM;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VerificationStatus verificationStatus = VerificationStatus.PENDING;

    @Column(nullable = false)
    private boolean online = false;

    /** Active Zone Pass (weekly/monthly) expiry; null/past = must renew before going online. */
    private Instant zonePassExpiresAt;

    /** Tier-2 penalty: skip N upcoming round-robin turns. */
    private int queueSkipPenalty = 0;

    /** Unverified cancels in the current rolling week (reset by a scheduled job). */
    private int unverifiedCancelsThisWeek = 0;

    /** Unverified cancels in the current rolling month. */
    private int unverifiedCancelsThisMonth = 0;

    private boolean suspended = false;

    /** Date (LocalDate.toString()) the Tier-1 emergency cancel quota was last used; resets daily. */
    private String emergencyCancelUsedOnDate;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    public enum VerificationStatus { PENDING, VERIFIED, REJECTED }
}
