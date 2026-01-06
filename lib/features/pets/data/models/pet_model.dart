import '../../domain/entities/pet_entity.dart';

/// Modelo de datos para mascotas que extiende PetEntity.
///
/// Maneja la serialización/deserialización desde/hacia Supabase.
class PetModel extends PetEntity {
  const PetModel({
    required super.id,
    required super.shelterId,
    super.shelterName,
    super.shelterPhone,
    super.shelterAddress,
    required super.name,
    required super.species,
    super.breed,
    super.ageYears,
    super.ageMonths,
    super.sex,
    super.size,
    super.description,
    super.vaccinated,
    super.dewormed,
    super.sterilized,
    super.microchip,
    super.specialCare,
    super.healthNotes,
    super.status,
    super.primaryPhotoUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Crea un PetModel desde un Map (respuesta de Supabase)
  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String,
      shelterId: json['shelter_id'] as String,
      shelterName: json['profiles']?['display_name'] as String?,
      shelterPhone: json['profiles']?['phone_number'] as String?,
      shelterAddress: json['profiles']?['address'] as String?,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String?,
      ageYears: json['age_years'] as int?,
      ageMonths: json['age_months'] as int?,
      sex: json['sex'] as String?,
      size: json['size'] as String?,
      description: json['description'] as String?,
      vaccinated: json['vaccinated'] as bool? ?? false,
      dewormed: json['dewormed'] as bool? ?? false,
      sterilized: json['sterilized'] as bool? ?? false,
      microchip: json['microchip'] as bool? ?? false,
      specialCare: json['special_care'] as bool? ?? false,
      healthNotes: json['health_notes'] as String?,
      status: json['status'] as String? ?? 'disponible',
      primaryPhotoUrl: json['primary_photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convierte el modelo a Map (para enviar a Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shelter_id': shelterId,
      'name': name,
      'species': species,
      'breed': breed,
      'age_years': ageYears,
      'age_months': ageMonths,
      'sex': sex,
      'size': size,
      'description': description,
      'vaccinated': vaccinated,
      'dewormed': dewormed,
      'sterilized': sterilized,
      'microchip': microchip,
      'special_care': specialCare,
      'health_notes': healthNotes,
      'status': status,
      'primary_photo_url': primaryPhotoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convierte el modelo a entidad
  PetEntity toEntity() {
    return PetEntity(
      id: id,
      shelterId: shelterId,
      shelterName: shelterName,
      shelterPhone: shelterPhone,
      shelterAddress: shelterAddress,
      name: name,
      species: species,
      breed: breed,
      ageYears: ageYears,
      ageMonths: ageMonths,
      sex: sex,
      size: size,
      description: description,
      vaccinated: vaccinated,
      dewormed: dewormed,
      sterilized: sterilized,
      microchip: microchip,
      specialCare: specialCare,
      healthNotes: healthNotes,
      status: status,
      primaryPhotoUrl: primaryPhotoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Crea un PetModel desde una entidad
  factory PetModel.fromEntity(PetEntity entity) {
    return PetModel(
      id: entity.id,
      shelterId: entity.shelterId,
      shelterName: entity.shelterName,
      shelterPhone: entity.shelterPhone,
      shelterAddress: entity.shelterAddress,
      name: entity.name,
      species: entity.species,
      breed: entity.breed,
      ageYears: entity.ageYears,
      ageMonths: entity.ageMonths,
      sex: entity.sex,
      size: entity.size,
      description: entity.description,
      vaccinated: entity.vaccinated,
      dewormed: entity.dewormed,
      sterilized: entity.sterilized,
      microchip: entity.microchip,
      specialCare: entity.specialCare,
      healthNotes: entity.healthNotes,
      status: entity.status,
      primaryPhotoUrl: entity.primaryPhotoUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
