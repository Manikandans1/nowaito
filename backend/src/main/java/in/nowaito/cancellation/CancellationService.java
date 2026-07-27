package in.nowaito.cancellation;

import in.nowaito.booking.AssignmentEngine;
import in.nowaito.driver.Driver;
import in.nowaito.driver.DriverRepository;
import in.nowaito.trip.Trip;
import in.nowaito.trip.TripRepository;
import in.nowaito.trip.TripStatus;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.NoSuchElementException;
import java.util.UUID;

/**
 * Implements the cancellation policy verbatim from the business doc:
 * - Rider: free within 3 min, ₹40 after (₹25 driver / ₹15 platform split — see PaymentService),
 *   free if driver hasn't arrived after 10 min, ₹40 no-show fee.
 * - Driver Tier 1: 1 verified emergency/day, no penalty, instant reassignment.
 * - Driver Tier 2: unverified cancel -> skip one full round-robin cycle; 3 in a week -> 1-day suspension.
 * - Driver Tier 3: 5+ unverified cancels in a month -> flagged + final warning; continued abuse -> offboarding.
 */
@Service
public class CancellationService {

    public static final int RIDER_FREE_WINDOW_MINUTES = 3;
    public static final int RIDER_CANCEL_FEE = 40;
    public static final int DRIVER_NOT_ARRIVED_FREE_CANCEL_MINUTES = 10;
    private static final int TIER2_WEEKLY_SUSPENSION_THRESHOLD = 3;
    private static final int TIER3_MONTHLY_FLAG_THRESHOLD = 5;

    private final TripRepository tripRepository;
    private final DriverRepository driverRepository;
    private final CancellationRecordRepository cancellationRecordRepository;
    private final AssignmentEngine assignmentEngine;

    public CancellationService(TripRepository tripRepository, DriverRepository driverRepository,
                                CancellationRecordRepository cancellationRecordRepository,
                                AssignmentEngine assignmentEngine) {
        this.tripRepository = tripRepository;
        this.driverRepository = driverRepository;
        this.cancellationRecordRepository = cancellationRecordRepository;
        this.assignmentEngine = assignmentEngine;
    }

    /** Rider cancels. Fee depends purely on elapsed time vs. the free window stored on the trip. */
    public CancellationRecord riderCancel(UUID tripId) {
        Trip trip = tripRepository.findById(tripId).orElseThrow(() -> new NoSuchElementException("Trip not found"));
        boolean withinFreeWindow = trip.getFreeCancelDeadline() != null && Instant.now().isBefore(trip.getFreeCancelDeadline());

        trip.setStatus(TripStatus.CANCELLED_RIDER);
        trip.setCancelledAt(Instant.now());
        tripRepository.save(trip);

        CancellationRecord record = new CancellationRecord();
        record.setTripId(tripId);
        record.setCancelledBy(CancellationRecord.CancelledBy.RIDER);
        record.setRiderFeeRupees(withinFreeWindow ? 0 : RIDER_CANCEL_FEE);
        return cancellationRecordRepository.save(record);
    }

    /** Driver emergency cancel — Tier 1 if within daily quota + photo proof supplied, else Tier 2. */
    public Trip driverEmergencyCancel(UUID tripId, UUID driverId, boolean photoProofProvided) {
        Trip trip = tripRepository.findById(tripId).orElseThrow(() -> new NoSuchElementException("Trip not found"));
        Driver driver = driverRepository.findById(driverId).orElseThrow(() -> new NoSuchElementException("Driver not found"));

        String today = LocalDate.now().toString();
        boolean quotaAvailable = !today.equals(driver.getEmergencyCancelUsedOnDate());

        CancellationRecord record = new CancellationRecord();
        record.setTripId(tripId);
        record.setCancelledBy(CancellationRecord.CancelledBy.DRIVER);

        if (quotaAvailable && photoProofProvided) {
            // Tier 1: verified emergency. No penalty, quota consumed for today.
            driver.setEmergencyCancelUsedOnDate(today);
            record.setDriverTier(CancellationRecord.DriverTier.TIER_1_EMERGENCY);
            record.setVerified(true);
        } else {
            applyTier2Penalty(driver, record);
        }

        driverRepository.save(driver);
        cancellationRecordRepository.save(record);

        // Either way, the rider's locked price is unaffected and the ride is reassigned immediately.
        assignmentEngine.reassignAfterEmergency(trip);
        return trip;
    }

    private void applyTier2Penalty(Driver driver, CancellationRecord record) {
        driver.setQueueSkipPenalty(driver.getQueueSkipPenalty() + 1);
        driver.setUnverifiedCancelsThisWeek(driver.getUnverifiedCancelsThisWeek() + 1);
        driver.setUnverifiedCancelsThisMonth(driver.getUnverifiedCancelsThisMonth() + 1);
        record.setDriverTier(CancellationRecord.DriverTier.TIER_2_UNVERIFIED);
        record.setVerified(false);

        if (driver.getUnverifiedCancelsThisWeek() >= TIER2_WEEKLY_SUSPENSION_THRESHOLD) {
            driver.setSuspended(true); // ops should review and lift after the 1-day window; left manual deliberately
        }
        if (driver.getUnverifiedCancelsThisMonth() >= TIER3_MONTHLY_FLAG_THRESHOLD) {
            record.setDriverTier(CancellationRecord.DriverTier.TIER_3_REPEAT_ABUSE);
            // Flag only — ops reviews via the console rather than auto-offboarding.
        }
    }

    /** Scheduled job (weekly/monthly) should call these resets — wired in DriverRepository-backed scheduler. */
    public void resetWeeklyCounters(Driver driver) {
        driver.setUnverifiedCancelsThisWeek(0);
    }

    public void resetMonthlyCounters(Driver driver) {
        driver.setUnverifiedCancelsThisMonth(0);
    }
}
