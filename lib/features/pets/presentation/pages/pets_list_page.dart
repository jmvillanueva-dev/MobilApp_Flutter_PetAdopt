import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/pets_bloc.dart';
import '../bloc/pets_event.dart';
import '../bloc/pets_state.dart';
import 'pet_form_page.dart';
import 'pet_detail_page.dart';

/// Página que muestra la lista de mascotas de un refugio.
///
/// Parte de la navegación principal para usuarios con rol "refugio".
class PetsListPage extends StatelessWidget {
  final UserEntity user;

  const PetsListPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mascotas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocConsumer<PetsBloc, PetsState>(
        listener: (context, state) {
          if (state is PetsOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.secondary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is PetsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PetsInitial || state is PetsLoading) {
            return Center(
                child: CircularProgressIndicator(color: colorScheme.primary));
          }

          if (state is PetsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}', style: textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<PetsBloc>().add(
                          PetsLoadRequested(user.id),
                        ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is PetsLoaded) {
            if (state.pets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pets,
                        size: 64,
                        color: colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes mascotas registradas',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toca el botón + para agregar una',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.pets.length,
              itemBuilder: (context, index) {
                final pet = state.pets[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          pet.species == 'perro'
                              ? Icons.pets
                              : Icons.catching_pokemon,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      pet.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${pet.species.toUpperCase()} • ${pet.breed ?? 'N/A'}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    trailing: _buildStatusChip(pet.status, context),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<PetsBloc>(),
                            child: PetDetailPage(pet: pet),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<PetsBloc>(),
                child: PetFormPage(shelterId: user.id),
              ),
            ),
          );
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    String label;
    Color textColor = Colors.white;

    switch (status) {
      case 'disponible':
        color = colorScheme.secondary; // Teal/Cyan for Success/Available
        label = 'Disponible';
        break;
      case 'en_proceso':
        color = colorScheme.primary; // Orange for Process
        label = 'En proceso';
        break;
      case 'adoptado':
        color = colorScheme.onSurface.withOpacity(0.1);
        textColor = colorScheme.onSurface.withOpacity(0.6);
        label = 'Adoptado';
        break;
      default:
        color = Colors.grey;
        label = 'Inactivo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
