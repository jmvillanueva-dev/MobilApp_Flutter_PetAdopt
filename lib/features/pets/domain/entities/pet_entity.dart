import 'package:equatable/equatable.dart';

/// Entidad que representa una mascota en el sistema.
///
/// Esta entidad encapsula toda la información relevante de una mascota
/// que está disponible para adopción en un refugio.
class PetEntity extends Equatable {
  final String id;
  final String shelterId;

  // Información del refugio
  final String? shelterName;
  final String? shelterPhone;
  final String? shelterAddress;

  // Información básica
  final String name;
  final String species; // 'perro' o 'gato'
  final String? breed;
  final int? ageYears;
  final int? ageMonths;
  final String? sex; // 'macho' o 'hembra'
  final String? size; // 'pequeño', 'mediano', 'grande'

  // Descripción
  final String? description;

  // Estado de salud
  final bool vaccinated;
  final bool dewormed;
  final bool sterilized;
  final bool microchip;
  final bool specialCare;
  final String? healthNotes;

  // Estado de adopción
  final String status; // 'disponible', 'en_proceso', 'adoptado', 'inactivo'

  // Foto principal
  final String? primaryPhotoUrl;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const PetEntity({
    required this.id,
    required this.shelterId,
    this.shelterName,
    this.shelterPhone,
    this.shelterAddress,
    required this.name,
    required this.species,
    this.breed,
    this.ageYears,
    this.ageMonths,
    this.sex,
    this.size,
    this.description,
    this.vaccinated = false,
    this.dewormed = false,
    this.sterilized = false,
    this.microchip = false,
    this.specialCare = false,
    this.healthNotes,
    this.status = 'disponible',
    this.primaryPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Retorna la edad en formato legible
  String get ageDisplay {
    if (ageYears == null && ageMonths == null) return 'Edad desconocida';

    final years = ageYears ?? 0;
    final months = ageMonths ?? 0;

    if (years > 0 && months > 0) {
      return '$years año${years > 1 ? 's' : ''} y $months mes${months > 1 ? 'es' : ''}';
    } else if (years > 0) {
      return '$years año${years > 1 ? 's' : ''}';
    } else {
      return '$months mes${months > 1 ? 'es' : ''}';
    }
  }

  @override
  List<Object?> get props => [
        id,
        shelterId,
        shelterName,
        shelterPhone,
        shelterAddress,
        name,
        species,
        breed,
        ageYears,
        ageMonths,
        sex,
        size,
        description,
        vaccinated,
        dewormed,
        sterilized,
        microchip,
        specialCare,
        healthNotes,
        status,
        primaryPhotoUrl,
        createdAt,
        updatedAt,
      ];
}
