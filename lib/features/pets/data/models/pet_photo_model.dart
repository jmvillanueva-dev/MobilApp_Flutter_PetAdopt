import '../../domain/entities/pet_photo_entity.dart';

/// Modelo de datos para fotos de mascotas.
class PetPhotoModel extends PetPhotoEntity {
  const PetPhotoModel({
    required super.id,
    required super.petId,
    required super.photoUrl,
    required super.displayOrder,
    required super.createdAt,
  });

  /// Crea un PetPhotoModel desde un Map (respuesta de Supabase)
  factory PetPhotoModel.fromJson(Map<String, dynamic> json) {
    return PetPhotoModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      photoUrl: json['photo_url'] as String,
      displayOrder: json['display_order'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convierte el modelo a Map (para enviar a Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'photo_url': photoUrl,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convierte el modelo a entidad
  PetPhotoEntity toEntity() {
    return PetPhotoEntity(
      id: id,
      petId: petId,
      photoUrl: photoUrl,
      displayOrder: displayOrder,
      createdAt: createdAt,
    );
  }
}
