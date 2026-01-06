import 'package:equatable/equatable.dart';
import '../../domain/entities/pet_entity.dart';

/// Estados para el PetsBloc
sealed class PetsState extends Equatable {
  const PetsState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PetsInitial extends PetsState {}

/// Estado de carga
class PetsLoading extends PetsState {}

/// Estado cuando las mascotas están cargadas
class PetsLoaded extends PetsState {
  final List<PetEntity> pets;

  const PetsLoaded(this.pets);

  @override
  List<Object?> get props => [pets];
}

/// Estado de éxito en operación (crear/actualizar/eliminar)
class PetsOperationSuccess extends PetsState {
  final String message;
  final PetEntity?
      createdPet; // El pet recién creado con su ID (solo para create)

  const PetsOperationSuccess(this.message, {this.createdPet});

  @override
  List<Object?> get props => [message, createdPet];
}

/// Estado de error
class PetsError extends PetsState {
  final String message;

  const PetsError(this.message);

  @override
  List<Object?> get props => [message];
}
