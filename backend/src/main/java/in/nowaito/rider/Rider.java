package in.nowaito.rider;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "riders")
@Getter
@Setter
@NoArgsConstructor
public class Rider {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false, unique = true)
    private String phone;

    private String name;

    /** Safe Pass tier, null if not subscribed. "BASIC" or "PLUS". */
    private String safePassTier;

    private Instant safePassExpiresAt;

    /** Late cancels / no-shows in the current rolling 7 days — drives the Tier-2/3 rider rules. */
    private int lateCancelsThisWeek = 0;
    private int lateCancelsThisMonth = 0;

    @Column(nullable = false)
    private boolean offPeakRestricted = false;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();
}
