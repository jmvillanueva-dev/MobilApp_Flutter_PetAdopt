import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/pet_entity.dart';
import '../bloc/pets_bloc.dart';
import '../bloc/pets_event.dart';
import '../bloc/pets_state.dart';
import '../widgets/pet_photo_picker.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/pets_remote_data_source.dart';

/// Formulario para crear o editar una mascota (Fase 3: con fotos).
class PetFormPage extends StatefulWidget {
  final String shelterId;
  final PetEntity? petToEdit; // Null = crear, no null = editar

  const PetFormPage({
    super.key,
    required this.shelterId,
    this.petToEdit,
  });

  @override
  State<PetFormPage> createState() => _PetFormPageState();
}

class _PetFormPageState extends State<PetFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _healthNotesController = TextEditingController();

  // Valores del formulario
  String _selectedSpecies = 'perro';
  String? _selectedSex;
  String? _selectedSize;
  int? _ageYears;
  int? _ageMonths;

  // Estado de salud
  bool _vaccinated = false;
  bool _dewormed = false;
  bool _sterilized = false;
  bool _microchip = false;
  bool _specialCare = false;

  // Fotos
  List<File> _newPhotos = [];
  List<String> _existingPhotos = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Si estamos editando, cargar los datos existentes
    if (widget.petToEdit != null) {
      final pet = widget.petToEdit!;
      _nameController.text = pet.name;
      _breedController.text = pet.breed ?? '';
      _descriptionController.text = pet.description ?? '';
      _healthNotesController.text = pet.healthNotes ?? '';

      _selectedSpecies = pet.species;
      _selectedSex = pet.sex;
      _selectedSize = pet.size;
      _ageYears = pet.ageYears;
      _ageMonths = pet.ageMonths;

      _vaccinated = pet.vaccinated;
      _dewormed = pet.dewormed;
      _sterilized = pet.sterilized;
      _microchip = pet.microchip;
      _specialCare = pet.specialCare;

      // Cargar todas las fotos de pet_photos
      _loadExistingPhotos();
    }
  }

  Future<void> _loadExistingPhotos() async {
    if (widget.petToEdit == null) return;

    try {
      final dataSource = getIt<PetsRemoteDataSource>();
      final photos = await dataSource.getPetPhotos(widget.petToEdit!.id);

      if (mounted) {
        setState(() {
          _existingPhotos = photos.map((p) => p.photoUrl).toList();
        });
      }
    } catch (e) {
      print('Error al cargar fotos: $e');
      // Si falla, al menos muestra la foto principal
      if (widget.petToEdit!.primaryPhotoUrl != null && mounted) {
        setState(() {
          _existingPhotos = [widget.petToEdit!.primaryPhotoUrl!];
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _descriptionController.dispose();
    _healthNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Validar que haya al menos una foto
      if (_existingPhotos.isEmpty && _newPhotos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes agregar al menos una foto')),
        );
        return;
      }

      setState(() => _isUploading = true);

      try {
        final isEditing = widget.petToEdit != null;
        String? primaryPhotoUrl;

        // Generar ID temporal para storage (se usa para crear carpetas)
        final tempPetId = isEditing
            ? widget.petToEdit!.id
            : DateTime.now().millisecondsSinceEpoch.toString();

        // Upload new photos if any
        if (_newPhotos.isNotEmpty) {
          final dataSource = getIt<PetsRemoteDataSource>();
          final userId = widget.shelterId;

          for (var photo in _newPhotos) {
            final url = await dataSource.uploadPetPhoto(
              userId: userId,
              petId: tempPetId,
              filePath: photo.path,
            );
            _existingPhotos.add(url);
          }
        }

        // La primera foto es la principal
        primaryPhotoUrl =
            _existingPhotos.isNotEmpty ? _existingPhotos.first : null;

        final pet = PetEntity(
          id: isEditing ? widget.petToEdit!.id : '',
          shelterId: widget.shelterId,
          name: _nameController.text.trim(),
          species: _selectedSpecies,
          breed: _breedController.text.trim().isEmpty
              ? null
              : _breedController.text.trim(),
          ageYears: _ageYears,
          ageMonths: _ageMonths,
          sex: _selectedSex,
          size: _selectedSize,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          vaccinated: _vaccinated,
          dewormed: _dewormed,
          sterilized: _sterilized,
          microchip: _microchip,
          specialCare: _specialCare,
          healthNotes: _healthNotesController.text.trim().isEmpty
              ? null
              : _healthNotesController.text.trim(),
          status: isEditing ? widget.petToEdit!.status : 'disponible',
          primaryPhotoUrl: primaryPhotoUrl,
          createdAt: isEditing ? widget.petToEdit!.createdAt : DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (mounted) {
          if (isEditing) {
            context.read<PetsBloc>().add(PetUpdateRequested(pet));
          } else {
            context.read<PetsBloc>().add(PetCreateRequested(pet));
          }
          // NO hacer Navigator.pop aquí - se hace en BlocListener
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al subir fotos: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<PetsBloc, PetsState>(
      listener: (context, state) async {
        // Cuando se crea exitosamente, guardar fotos en pet_photos
        if (state is PetsOperationSuccess && state.createdPet != null) {
          final createdPet = state.createdPet!;
          if (_existingPhotos.isNotEmpty) {
            final dataSource = getIt<PetsRemoteDataSource>();
            for (int i = 0; i < _existingPhotos.length; i++) {
              try {
                await dataSource.createPetPhoto(
                  petId: createdPet.id,
                  photoUrl: _existingPhotos[i],
                  displayOrder: i,
                );
              } catch (e) {
                print('❌ Error saving photo $i: $e');
              }
            }
          }
          // Navegar de vuelta después de guardar fotos
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else if (state is PetsOperationSuccess) {
          // Para edición (sin createdPet)
          if (widget.petToEdit != null) {
            try {
              final dataSource = getIt<PetsRemoteDataSource>();
              await dataSource.replacePetPhotos(
                petId: widget.petToEdit!.id,
                photoUrls: _existingPhotos,
              );
            } catch (e) {
              print('❌ Error syncing photos: $e');
            }
          }

          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.petToEdit == null ? 'Nueva Mascota' : 'Editar Mascota',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información Básica
                Text(
                  '📝 Información Básica',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Mascota *',
                    prefixIcon: Icon(Icons.pets),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'El nombre es requerido' : null,
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedSpecies,
                  decoration: const InputDecoration(
                    labelText: 'Especie *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'perro', child: Text('Perro')),
                    DropdownMenuItem(value: 'gato', child: Text('Gato')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedSpecies = value!),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(
                    labelText: 'Raza',
                    prefixIcon: Icon(Icons.fingerprint),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Años',
                        ),
                        items: List.generate(
                          20,
                          (i) => DropdownMenuItem(
                              value: i, child: Text('$i años')),
                        ),
                        onChanged: (value) => setState(() => _ageYears = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Meses',
                        ),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                              value: i, child: Text('$i meses')),
                        ),
                        onChanged: (value) =>
                            setState(() => _ageMonths = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Sexo',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'macho', child: Text('Macho')),
                          DropdownMenuItem(
                              value: 'hembra', child: Text('Hembra')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedSex = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tamaño',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'pequeño', child: Text('Pequeño')),
                          DropdownMenuItem(
                              value: 'mediano', child: Text('Mediano')),
                          DropdownMenuItem(
                              value: 'grande', child: Text('Grande')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedSize = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Descripción
                Text(
                  '📄 Descripción',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Cuéntanos sobre esta mascota',
                    hintText: 'Personalidad, historia, comportamiento...',
                    alignLabelWithHint: true,
                    counterText: '',
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 32),

                // Fotos
                Text(
                  '📸 Galería',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                PetPhotoPicker(
                  initialPhotos: _existingPhotos,
                  onPhotosChanged: (newPhotos, existingPhotos) {
                    setState(() {
                      _newPhotos = newPhotos;
                      _existingPhotos = existingPhotos;
                    });
                  },
                ),

                const SizedBox(height: 32),

                // Estado de Salud
                Text(
                  '🏥 Estado de Salud',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: colorScheme.outline.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      _buildCheckbox(
                          'Vacunado/a',
                          'Tiene todas las vacunas al día',
                          _vaccinated,
                          (v) => setState(() => _vaccinated = v!)),
                      _buildDivider(),
                      _buildCheckbox(
                          'Desparasitado/a',
                          'Tratamiento antiparasitario completado',
                          _dewormed,
                          (v) => setState(() => _dewormed = v!)),
                      _buildDivider(),
                      _buildCheckbox(
                          'Esterilizado/a',
                          'Ha sido castrado/a o esterilizado/a',
                          _sterilized,
                          (v) => setState(() => _sterilized = v!)),
                      _buildDivider(),
                      _buildCheckbox(
                          'Microchip',
                          'Tiene microchip de identificación',
                          _microchip,
                          (v) => setState(() => _microchip = v!)),
                      _buildDivider(),
                      _buildCheckbox(
                          'Cuidados especiales',
                          'Necesita medicación o atención particular',
                          _specialCare,
                          (v) => setState(() => _specialCare = v!)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_specialCare)
                  TextFormField(
                    controller: _healthNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas adicionales de salud',
                      hintText:
                          'Alergias, medicamentos, condiciones crónicas...',
                      prefixIcon: Icon(Icons.medical_services_outlined),
                    ),
                    maxLines: 3,
                  ),

                const SizedBox(height: 48),

                // Botón de guardar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isUploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isUploading ? 'Subiendo fotos...' : 'Publicar Mascota',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(
      String title, String subtitle, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: Colors.grey.withOpacity(0.1));
  }
}
