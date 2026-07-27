package in.nowaito.driver;

import in.nowaito.vehicle.VehicleType;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Round-robin queue per (zone, vehicleType), backed by a Redis sorted set.
 * <p>
 * Score = the epoch-millis timestamp the driver last became eligible
 * (joined the queue, or finished their last ride). Lowest score = next
 * in line. This single mechanism is what removes driver cherry-picking:
 * there is no "accept" step, just "who's been waiting longest".
 */
@Service
public class DriverQueueService {

    private final StringRedisTemplate redis;
    private final DriverRepository driverRepository;

    public DriverQueueService(StringRedisTemplate redis, DriverRepository driverRepository) {
        this.redis = redis;
        this.driverRepository = driverRepository;
    }

    private String key(UUID zoneId, VehicleType vehicleType) {
        return "queue:" + zoneId + ":" + vehicleType;
    }

    /** Driver goes online / re-enters the queue (also used when they return from a ride). */
    public void joinQueue(UUID driverId, UUID zoneId, VehicleType vehicleType) {
        redis.opsForZSet().add(key(zoneId, vehicleType), driverId.toString(), System.currentTimeMillis());
    }

    /** Driver goes offline. */
    public void leaveQueue(UUID driverId, UUID zoneId, VehicleType vehicleType) {
        redis.opsForZSet().remove(key(zoneId, vehicleType), driverId.toString());
    }

    public long queuePosition(UUID driverId, UUID zoneId, VehicleType vehicleType) {
        Long rank = redis.opsForZSet().rank(key(zoneId, vehicleType), driverId.toString());
        return rank == null ? -1 : rank + 1;
    }

    public long queueSize(UUID zoneId, VehicleType vehicleType) {
        Long size = redis.opsForZSet().zCard(key(zoneId, vehicleType));
        return size == null ? 0 : size;
    }

    /**
     * Finds and removes the next eligible driver for a ride: lowest score first,
     * filtered by the rider's distance band matching the driver's preference,
     * skipping any driver currently serving a Tier-2 penalty (and decrementing it).
     * The chosen driver is removed from the queue (they're now "busy") and is
     * re-added by {@link #returnToBackOfQueue} once the trip completes.
     */
    public Optional<UUID> assignNextDriver(UUID zoneId, VehicleType vehicleType, DistanceBand requiredBand) {
        ZSetOperations<String, String> zset = redis.opsForZSet();
        Set<String> candidates = zset.range(key(zoneId, vehicleType), 0, 49); // look at the next 50 in line
        if (candidates == null) return Optional.empty();

        for (String candidateId : candidates) {
            UUID driverId = UUID.fromString(candidateId);
            Optional<Driver> driverOpt = driverRepository.findById(driverId);
            if (driverOpt.isEmpty()) {
                zset.remove(key(zoneId, vehicleType), candidateId);
                continue;
            }
            Driver driver = driverOpt.get();

            if (driver.isSuspended()) {
                zset.remove(key(zoneId, vehicleType), candidateId);
                continue;
            }
            if (driver.getQueueSkipPenalty() > 0) {
                // Tier-2 penalty: this driver is skipped one full round-robin cycle.
                driver.setQueueSkipPenalty(driver.getQueueSkipPenalty() - 1);
                driverRepository.save(driver);
                continue;
            }
            if (driver.getDistancePreference() != requiredBand) {
                continue;
            }

            // Eligible: remove from queue (now busy) and hand them the ride.
            zset.remove(key(zoneId, vehicleType), candidateId);
            return Optional.of(driverId);
        }
        return Optional.empty();
    }

    /** Called when a trip completes (or a driver is "No Show" cleared) — sends them to the back of the line. */
    public void returnToBackOfQueue(UUID driverId, UUID zoneId, VehicleType vehicleType) {
        joinQueue(driverId, zoneId, vehicleType);
    }
}
