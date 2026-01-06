import 'package:equatable/equatable.dart';

/// Entidad que representa una foto de una mascota.
///
/// Las mascotas pueden tener múltiples fotos (máximo 5).
/// La primera foto (display_order = 0) es la foto principal.
class PetPhotoEntity extends Equatable {
  final String id;
  final String petId;
  final String photoUrl;
  final int displayOrder;
  final DateTime createdAt;

  const PetPhotoEntity({
    required this.id,
    required this.petId,
    required this.photoUrl,
    required this.displayOrder,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, petId, photoUrl, displayOrder, createdAt];
}
