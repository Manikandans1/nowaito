package in.nowaito.zone;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "zones")
@Getter
@Setter
@NoArgsConstructor
public class Zone {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false, unique = true)
    private String name; // e.g. "Koramangala"

    @Column(nullable = false)
    private String city; // "Bangalore" | "Chennai"

    /** Whether bikes are permitted in this zone's state/city (regulatory gate). */
    @Column(nullable = false)
    private boolean bikesAllowed = false;

    @Column(nullable = false)
    private boolean active = false;

    private double centerLat;
    private double centerLng;
    private double radiusKm = 4.0;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    public Zone(String name, String city, boolean bikesAllowed, double centerLat, double centerLng) {
        this.name = name;
        this.city = city;
        this.bikesAllowed = bikesAllowed;
        this.centerLat = centerLat;
        this.centerLng = centerLng;
    }
}
