import 'package:equatable/equatable.dart';

class AdoptionRequestEntity extends Equatable {
  final String id;
  final String petId;
  final String adopterId;
  final String shelterId;
  final String status; // 'pendiente', 'aprobada', 'rechazada'
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Datos adicionales para la UI (opcionales, se llenan con joins)
  final String? petName;
  final String? petPhotoUrl;
  final String? adopterNamr;
  final String? adopterEmail;

  const AdoptionRequestEntity({
    required this.id,
    required this.petId,
    required this.adopterId,
    required this.shelterId,
    required this.status,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.petName,
    this.petPhotoUrl,
    this.adopterNamr,
    this.adopterEmail,
  });

  @override
  List<Object?> get props => [
        id,
        petId,
        adopterId,
        shelterId,
        status,
        message,
        createdAt,
        updatedAt,
        petName,
        petPhotoUrl,
        adopterNamr,
        adopterEmail,
      ];
}
