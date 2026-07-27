package in.nowaito.cancellation;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "cancellation_records")
@Getter
@Setter
@NoArgsConstructor
public class CancellationRecord {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false)
    private UUID tripId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CancelledBy cancelledBy;

    @Enumerated(EnumType.STRING)
    private DriverTier driverTier; // null if cancelledBy = RIDER

    private boolean verified; // driver Tier-1 emergency with photo proof inside the 2-min window

    /** Rider-side fee charged (0 or 40), per the business doc rules. */
    private int riderFeeRupees;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    public enum CancelledBy { RIDER, DRIVER }
    public enum DriverTier { TIER_1_EMERGENCY, TIER_2_UNVERIFIED, TIER_3_REPEAT_ABUSE }
}
