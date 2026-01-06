import 'package:equatable/equatable.dart';
import '../../domain/entities/pet_entity.dart';

/// Eventos para el PetsBloc
sealed class PetsEvent extends Equatable {
  const PetsEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar las mascotas de un refugio
class PetsLoadRequested extends PetsEvent {
  final String shelterId;

  const PetsLoadRequested(this.shelterId);

  @override
  List<Object?> get props => [shelterId];
}

/// Evento para crear una nueva mascota
class PetCreateRequested extends PetsEvent {
  final PetEntity pet;

  const PetCreateRequested(this.pet);

  @override
  List<Object?> get props => [pet];
}

/// Evento para actualizar una mascota (Fase 2)
class PetUpdateRequested extends PetsEvent {
  final PetEntity pet;

  const PetUpdateRequested(this.pet);

  @override
  List<Object?> get props => [pet];
}

/// Evento para eliminar una mascota (Fase 2)
class PetDeleteRequested extends PetsEvent {
  final String petId;

  const PetDeleteRequested(this.petId);

  @override
  List<Object?> get props => [petId];
}
