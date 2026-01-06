import '../../domain/entities/adoption_request_entity.dart';

class AdoptionRequestModel extends AdoptionRequestEntity {
  const AdoptionRequestModel({
    required super.id,
    required super.petId,
    required super.adopterId,
    required super.shelterId,
    required super.status,
    super.message,
    required super.createdAt,
    required super.updatedAt,
    super.petName,
    super.petPhotoUrl,
    super.adopterNamr,
    super.adopterEmail,
  });

  factory AdoptionRequestModel.fromJson(Map<String, dynamic> json) {
    return AdoptionRequestModel(
      id: json['id'],
      petId: json['pet_id'],
      adopterId: json['adopter_id'],
      shelterId: json['shelter_id'],
      status: json['status'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      petName: json['pets']?['name'],
      petPhotoUrl: json['pets']?['primary_photo_url'],
      adopterNamr: json['profiles']?['display_name'], // Nombre del adoptante
      adopterEmail: json['profiles']?['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'adopter_id': adopterId,
      'shelter_id': shelterId,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AdoptionRequestEntity toEntity() {
    return AdoptionRequestEntity(
      id: id,
      petId: petId,
      adopterId: adopterId,
      shelterId: shelterId,
      status: status,
      message: message,
      createdAt: createdAt,
      updatedAt: updatedAt,
      petName: petName,
      petPhotoUrl: petPhotoUrl,
      adopterNamr: adopterNamr,
      adopterEmail: adopterEmail,
    );
  }
}
