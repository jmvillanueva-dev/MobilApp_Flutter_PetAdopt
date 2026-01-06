import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/pet_entity.dart';
import '../../domain/entities/pet_photo_entity.dart';
import '../../domain/repositories/pets_repository.dart';
import '../bloc/pets_bloc.dart';
import '../bloc/pets_event.dart';
import 'pet_form_page.dart';
import '../../../../injection_container.dart';

/// Página de detalle de una mascota con actualizaciones en tiempo real.
class PetDetailPage extends StatefulWidget {
  final PetEntity pet;

  const PetDetailPage({super.key, required this.pet});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  late Stream<PetEntity> _petStream;
  late Stream<List<PetPhotoEntity>> _photosStream;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    final repository = getIt<PetsRepository>();
    _petStream = repository.watchPet(widget.pet.id);
    _photosStream = repository.watchPetPhotos(widget.pet.id);
  }

  void _showDeleteConfirmation(BuildContext context, String petName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Mascota'),
        content: Text('¿Estás seguro de eliminar a $petName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<PetsBloc>().add(PetDeleteRequested(widget.pet.id));
              Navigator.of(dialogContext).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver a lista
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<PetEntity>(
      stream: _petStream,
      initialData: widget.pet,
      builder: (context, petSnapshot) {
        if (petSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${petSnapshot.error}')),
          );
        }

        if (!petSnapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(color: colorScheme.primary));
        }

        final pet = petSnapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(pet.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.edit, color: colorScheme.primary),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<PetsBloc>(),
                        child: PetFormPage(
                          shelterId: pet.shelterId,
                          petToEdit: pet,
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: colorScheme.error),
                onPressed: () => _showDeleteConfirmation(context, pet.name),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carrusel de fotos (Stream separado)
                StreamBuilder<List<PetPhotoEntity>>(
                  stream: _photosStream,
                  builder: (context, photosSnapshot) {
                    final photos = photosSnapshot.data ?? [];
                    final photoUrls = photos.isNotEmpty
                        ? photos.map((p) => p.photoUrl).toSet().toList()
                        : (pet.primaryPhotoUrl != null
                            ? [pet.primaryPhotoUrl!]
                            : <String>[]);

                    return Center(
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: photoUrls.isEmpty
                                ? Icon(
                                    pet.species == 'perro'
                                        ? Icons.pets
                                        : Icons.catching_pokemon,
                                    size: 100,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.2),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: PageView.builder(
                                      key: ValueKey(photoUrls
                                          .join()), // Forzar reconstrucción si cambian las fotos
                                      itemCount: photoUrls.length,
                                      onPageChanged: (index) {
                                        setState(
                                            () => _currentPhotoIndex = index);
                                      },
                                      itemBuilder: (context, index) {
                                        return Image.network(
                                          photoUrls[index],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              pet.species == 'perro'
                                                  ? Icons.pets
                                                  : Icons.catching_pokemon,
                                              size: 100,
                                              color: Colors.grey.shade600,
                                            );
                                          },
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                color: colorScheme.primary,
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                          ),
                          if (photoUrls.length > 1) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                photoUrls.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentPhotoIndex == index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: _currentPhotoIndex == index
                                        ? colorScheme.primary
                                        : colorScheme.onSurface
                                            .withOpacity(0.2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Información Detallada
                _buildSectionTitle(context, 'Información'),
                const SizedBox(height: 16),
                _buildInfoRow(context, 'Nombre', pet.name),
                _buildInfoRow(context, 'Especie', pet.species.toUpperCase()),
                if (pet.breed != null)
                  _buildInfoRow(context, 'Raza', pet.breed!),
                _buildInfoRow(context, 'Edad', pet.ageDisplay),
                if (pet.sex != null) _buildInfoRow(context, 'Sexo', pet.sex!),
                if (pet.size != null)
                  _buildInfoRow(context, 'Tamaño', pet.size!),

                const SizedBox(height: 32),

                // Descripción
                if (pet.description != null) ...[
                  _buildSectionTitle(context, 'Historia'),
                  const SizedBox(height: 8),
                  Text(
                    pet.description!,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Salud
                _buildSectionTitle(context, 'Salud'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    _buildHealthChip(context, 'Vacunado/a', pet.vaccinated),
                    _buildHealthChip(context, 'Desparasitado/a', pet.dewormed),
                    _buildHealthChip(context, 'Esterilizado/a', pet.sterilized),
                    _buildHealthChip(context, 'Microchip', pet.microchip),
                    if (pet.specialCare)
                      Chip(
                        avatar: const Icon(Icons.warning_amber_rounded,
                            size: 18, color: Colors.white),
                        label: const Text('Cuidados especiales'),
                        backgroundColor: colorScheme.error,
                        labelStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                  ],
                ),
                if (pet.healthNotes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.outline.withOpacity(0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: colorScheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pet.healthNotes!,
                            style: textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                _buildSectionTitle(context, 'Estado'),
                const SizedBox(height: 12),
                _buildStatusChip(pet.status, context),

                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Publicado el ${_formatDate(pet.createdAt)}',
                        style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      if (pet.updatedAt.isAfter(pet.createdAt))
                        Text(
                          'Actualizado el ${_formatDate(pet.updatedAt)}',
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthChip(BuildContext context, String label, bool value) {
    if (!value) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: const Icon(Icons.check, size: 18, color: Colors.white),
      label: Text(label),
      backgroundColor: colorScheme.secondary,
      labelStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildStatusChip(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    Color textColor = Colors.white;

    switch (status) {
      case 'disponible':
        color = colorScheme.secondary;
        break;
      case 'adoptado':
        color = colorScheme.onSurface.withOpacity(0.1);
        textColor = colorScheme.onSurface.withOpacity(0.6);
        break;
      case 'en_proceso':
      case 'pendiente':
        color = colorScheme.primary;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
