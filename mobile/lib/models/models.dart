class Quote {
  final int fare;
  final int guaranteeFee;
  final int total;
  final bool peakActive;
  const Quote({required this.fare, required this.guaranteeFee, required this.total, required this.peakActive});
  factory Quote.fromJson(Map<String, dynamic> j) => Quote(
    fare: j['fare'] as int,
    guaranteeFee: j['guaranteeFee'] as int,
    total: j['total'] as int,
    peakActive: j['peakActive'] as bool? ?? false,
  );
}

class Trip {
  final String id;
  final String? driverId;
  final String status;
  final int lockedFare;
  final int guaranteeFee;
  final String vehicleType;
  final String pickupLabel;
  final String dropLabel;
  final String? freeCancelDeadline;

  const Trip({
    required this.id, this.driverId,
    required this.status, required this.lockedFare,
    required this.guaranteeFee, required this.vehicleType,
    required this.pickupLabel, required this.dropLabel,
    this.freeCancelDeadline,
  });

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
    id: j['id'] as String,
    driverId: j['driverId'] as String?,
    status: j['status'] as String,
    lockedFare: j['lockedFare'] as int,
    guaranteeFee: j['guaranteeFee'] as int,
    vehicleType: j['vehicleType'] as String,
    pickupLabel: j['pickupLabel'] as String? ?? '',
    dropLabel: j['dropLabel'] as String? ?? '',
    freeCancelDeadline: j['freeCancelDeadline'] as String?,
  );

  int get total => lockedFare + guaranteeFee;
  bool get isSearching  => status == 'SEARCHING';
  bool get isAssigned   => status == 'DRIVER_ASSIGNED';
  bool get isArrived    => status == 'ARRIVED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isCompleted  => status == 'COMPLETED';
  bool get isCancelled  => status == 'CANCELLED_RIDER' || status == 'CANCELLED_DRIVER';
}

class Driver {
  final String id;
  final String name;
  final String vehicleType;
  final String vehicleLabel;
  final String plateNumber;
  final bool online;
  final String verificationStatus;
  final String? zonePassExpiresAt;
  final int unverifiedCancelsThisWeek;
  final String? emergencyCancelUsedOnDate;

  const Driver({
    required this.id, required this.name,
    required this.vehicleType, required this.vehicleLabel,
    required this.plateNumber, required this.online,
    required this.verificationStatus,
    this.zonePassExpiresAt,
    this.unverifiedCancelsThisWeek = 0,
    this.emergencyCancelUsedOnDate,
  });

  factory Driver.fromJson(Map<String, dynamic> j) => Driver(
    id: j['id'] as String,
    name: j['name'] as String,
    vehicleType: j['vehicleType'] as String,
    vehicleLabel: j['vehicleLabel'] as String? ?? '',
    plateNumber: j['plateNumber'] as String? ?? '',
    online: j['online'] as bool? ?? false,
    verificationStatus: j['verificationStatus'] as String? ?? 'PENDING',
    zonePassExpiresAt: j['zonePassExpiresAt'] as String?,
    unverifiedCancelsThisWeek: j['unverifiedCancelsThisWeek'] as int? ?? 0,
    emergencyCancelUsedOnDate: j['emergencyCancelUsedOnDate'] as String?,
  );

  // Emergency cancel is available if not already used today
  bool get emergencyCancelAvailable {
    if (emergencyCancelUsedOnDate == null) return true;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return emergencyCancelUsedOnDate != today;
  }
}

class Zone {
  final String id;
  final String name;
  final String city;
  final bool bikesAllowed;
  const Zone({required this.id, required this.name, required this.city, required this.bikesAllowed});
  factory Zone.fromJson(Map<String, dynamic> j) => Zone(
    id: j['id'] as String,
    name: j['name'] as String,
    city: j['city'] as String,
    bikesAllowed: j['bikesAllowed'] as bool? ?? false,
  );
}

class AuthResponse {
  final String token;
  final String userId;
  final bool isNewUser;
  const AuthResponse({required this.token, required this.userId, required this.isNewUser});
  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
    token: j['token'] as String,
    userId: j['userId'] as String,
    isNewUser: j['isNewUser'] as bool? ?? false,
  );
}
