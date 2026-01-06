import 'dart:math' as math;
import 'package:equatable/equatable.dart';

class ShelterLocation extends Equatable {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final int petCount;
  final String? logoUrl;

  const ShelterLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    required this.petCount,
    this.logoUrl,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        latitude,
        longitude,
        phone,
        petCount,
        logoUrl,
      ];

  /// Calculate distance to user in km
  double distanceTo(double userLat, double userLon) {
    // Haversine formula simplificada para distancias cortas
    const double radiusEarth = 6371; // km
    final dLat = _toRadians(userLat - latitude);
    final dLon = _toRadians(userLon - longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(userLat)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return radiusEarth * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }
}
