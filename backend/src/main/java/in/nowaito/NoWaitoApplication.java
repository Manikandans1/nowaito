package in.nowaito;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * NoWaito core API.
 * <p>
 * Boots the modular monolith: zones, driver queueing & the round-robin
 * assignment engine, pricing/price-lock, bookings, trip lifecycle,
 * cancellation tiers and payment settlement.
 */
@SpringBootApplication
@EnableScheduling
public class NoWaitoApplication {
    public static void main(String[] args) {
        SpringApplication.run(NoWaitoApplication.class, args);
    }
}
