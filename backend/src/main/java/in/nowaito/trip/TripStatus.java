package in.nowaito.trip;

public enum TripStatus {
    SEARCHING,       // assignment engine looking for a driver
    DRIVER_ASSIGNED, // driver matched, heading to pickup
    ARRIVED,         // driver at pickup, waiting on rider
    IN_PROGRESS,     // trip underway
    COMPLETED,       // dropped off, payment captured
    CANCELLED_RIDER,
    CANCELLED_DRIVER,
    NO_DRIVER_AVAILABLE
}
