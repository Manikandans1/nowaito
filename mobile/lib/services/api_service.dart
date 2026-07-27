import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();
  late final Dio _dio;

  void init() {
    final base = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';
    _dio = Dio(BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
      onError: (err, handler) {
        final data = err.response?.data;
        if (data is Map && data['message'] != null) {
          return handler.reject(DioException(
            requestOptions: err.requestOptions,
            message: data['message'] as String,
            type: err.type,
            response: err.response,
          ));
        }
        return handler.next(err);
      },
    ));
  }

  // ── Auth ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final res = await _dio.post('/api/auth/request-otp', data: {'phone': phone});
    return res.data as Map<String, dynamic>;
  }

  Future<AuthResponse> verifyOtp(String phone, String code, String role) async {
    final res = await _dio.post('/api/auth/verify-otp', data: {
      'phone': phone, 'code': code, 'role': role,
    });
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Pricing ────────────────────────────────────────────────────────────────
  Future<Quote> getQuote(String vehicleType, double distanceKm, {bool peakActive = false}) async {
    final res = await _dio.get('/api/bookings/quote', queryParameters: {
      'vehicleType': vehicleType,
      'distanceKm': distanceKm,
      'peakActive': peakActive,
    });
    return Quote.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Trip> createBooking(Map<String, dynamic> payload) async {
    final res = await _dio.post('/api/bookings', data: payload);
    return Trip.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Trips ──────────────────────────────────────────────────────────────────
  Future<Trip> getTrip(String tripId) async {
    final res = await _dio.get('/api/trips/$tripId');
    return Trip.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Trip?> getActiveTripForDriver(String driverId) async {
    try {
      final res = await _dio.get('/api/trips/driver/$driverId/active');
      if (res.data == null) return null;
      return Trip.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 204) return null;
      rethrow;
    }
  }

  Future<Trip> driverArrived(String tripId) async =>
      Trip.fromJson((await _dio.post('/api/trips/$tripId/arrived')).data as Map<String, dynamic>);

  Future<Trip> startTrip(String tripId) async =>
      Trip.fromJson((await _dio.post('/api/trips/$tripId/start')).data as Map<String, dynamic>);

  Future<Trip> completeTrip(String tripId) async =>
      Trip.fromJson((await _dio.post('/api/trips/$tripId/complete')).data as Map<String, dynamic>);

  Future<Trip> driverNoShow(String tripId) async =>
      Trip.fromJson((await _dio.post('/api/trips/$tripId/no-show')).data as Map<String, dynamic>);

  // ── Cancellations ──────────────────────────────────────────────────────────
  Future<void> riderCancel(String tripId) async =>
      _dio.post('/api/cancellations/rider/$tripId');

  Future<void> driverEmergencyCancel(String tripId, String driverId, {bool photoProof = true}) async =>
      _dio.post('/api/cancellations/driver/$tripId/emergency',
          queryParameters: {'driverId': driverId, 'photoProofProvided': photoProof});

  // ── Drivers ────────────────────────────────────────────────────────────────
  Future<Driver> getDriver(String driverId) async {
    final res = await _dio.get('/api/drivers/$driverId');
    return Driver.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Driver> goOnline(String driverId) async =>
      Driver.fromJson((await _dio.post('/api/drivers/$driverId/online')).data as Map<String, dynamic>);

  Future<Driver> goOffline(String driverId) async =>
      Driver.fromJson((await _dio.post('/api/drivers/$driverId/offline')).data as Map<String, dynamic>);

  Future<int> queuePosition(String driverId) async {
    final res = await _dio.get('/api/drivers/$driverId/queue-position');
    return (res.data as num).toInt();
  }

  Future<List<Driver>> listDrivers() async {
    final res = await _dio.get('/api/drivers');
    return (res.data as List).map((d) => Driver.fromJson(d as Map<String, dynamic>)).toList();
  }

  // ── Zones ──────────────────────────────────────────────────────────────────
  Future<List<Zone>> listZones() async {
    final res = await _dio.get('/api/zones');
    return (res.data as List).map((z) => Zone.fromJson(z as Map<String, dynamic>)).toList();
  }
}
