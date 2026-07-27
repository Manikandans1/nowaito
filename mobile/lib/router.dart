import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'screens/auth_screen.dart';
// Rider
import 'screens/rider/rider_home_screen.dart';
import 'screens/rider/rider_active_trip_screen.dart';
import 'screens/rider/rider_trip_complete_screen.dart';
import 'screens/rider/rider_trips_screen.dart';
import 'screens/rider/rider_wallet_screen.dart';
import 'screens/rider/rider_profile_screen.dart';
// Driver
import 'screens/driver/driver_home_screen.dart';
import 'screens/driver/driver_active_ride_screen.dart';
import 'screens/driver/driver_earnings_screen.dart';
import 'screens/driver/driver_profile_screen.dart';

import 'services/session_provider.dart';

GoRouter buildRouter() => GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = context.read<SessionProvider>();
    final loggedIn = session.isLoggedIn;
    final loc = state.uri.path;

    // Not logged in, trying to reach app screens → root
    final appPrefixes = ['/rider/', '/driver/'];
    if (!loggedIn && appPrefixes.any((p) => loc.startsWith(p))) {
      return '/';
    }

    // Logged in, at root → go straight to home
    if (loggedIn && loc == '/') {
      return session.isRider ? '/rider/home' : '/driver/home';
    }
    return null;
  },
  routes: [

    // ── Root ─────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (_, __) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: '/rider-login',
      builder: (_, __) => const LoginScreen(role: 'RIDER'),
    ),
    GoRoute(
      path: '/driver-login',
      builder: (_, __) => const LoginScreen(role: 'DRIVER'),
    ),

    // ── Rider ─────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/rider/home',
      builder: (_, __) => const RiderHomeScreen(),
    ),
    GoRoute(
      path: '/rider/active-trip',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return RiderActiveTripScreen(
          tripId:  extra['tripId']  as String? ?? '',
          vehicle: extra['vehicle'] as String? ?? 'CAR',
        );
      },
    ),
    GoRoute(
      path: '/rider/trip-complete',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return RiderTripCompleteScreen(
          tripId:  extra['tripId']  as String? ?? '',
          vehicle: extra['vehicle'] as String? ?? 'CAR',
        );
      },
    ),
    GoRoute(
      path: '/rider/trips',
      builder: (_, __) => const RiderTripsScreen(),
    ),
    GoRoute(
      path: '/rider/wallet',
      builder: (_, __) => const RiderWalletScreen(),
    ),
    GoRoute(
      path: '/rider/profile',
      builder: (_, __) => const RiderProfileScreen(),
    ),

    // ── Driver ────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/driver/home',
      builder: (_, __) => const DriverHomeScreen(),
    ),
    GoRoute(
      path: '/driver/active-ride',
      builder: (_, __) => const DriverActiveRideScreen(),
    ),
    GoRoute(
      path: '/driver/earnings',
      builder: (_, __) => const DriverEarningsScreen(),
    ),
    GoRoute(
      path: '/driver/profile',
      builder: (_, __) => const DriverProfileScreen(),
    ),
  ],
);
