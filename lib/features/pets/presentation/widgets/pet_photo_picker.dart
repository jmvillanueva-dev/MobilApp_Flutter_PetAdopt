import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget para seleccionar y gestionar fotos de mascotas.
///
/// Permite:
/// - Seleccionar desde galería o cámara
/// - Máximo 5 fotos
/// - Marcar foto principal
/// - Eliminar fotos
class PetPhotoPicker extends StatefulWidget {
  final List<String> initialPhotos; // URLs de fotos existentes
  final Function(List<File> selectedFiles, List<String> existingUrls)
      onPhotosChanged;
  final int? primaryPhotoIndex;

  const PetPhotoPicker({
    super.key,
    this.initialPhotos = const [],
    required this.onPhotosChanged,
    this.primaryPhotoIndex,
  });

  @override
  State<PetPhotoPicker> createState() => _PetPhotoPickerState();
}

class _PetPhotoPickerState extends State<PetPhotoPicker> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _newPhotos = [];
  late List<String> _existingPhotos;
  int _primaryIndex = 0;

  @override
  void initState() {
    super.initState();
    _existingPhotos = List.from(widget.initialPhotos);
    _primaryIndex = widget.primaryPhotoIndex ?? 0;
  }

  @override
  void didUpdateWidget(PetPhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPhotos != oldWidget.initialPhotos) {
      setState(() {
        _existingPhotos = List.from(widget.initialPhotos);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newPhotos.add(File(image.path));
        });
        _notifyChanges();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      final totalExisting = _existingPhotos.length;
      if (index < totalExisting) {
        _existingPhotos.removeAt(index);
      } else {
        _newPhotos.removeAt(index - totalExisting);
      }

      // Ajustar índice principal si es necesario
      if (_primaryIndex == index) {
        _primaryIndex = 0;
      } else if (_primaryIndex > index) {
        _primaryIndex--;
      }
    });
    _notifyChanges();
  }

  void _setPrimary(int index) {
    setState(() {
      _primaryIndex = index;
    });
    _notifyChanges();
  }

  void _notifyChanges() {
    widget.onPhotosChanged(_newPhotos, _existingPhotos);
  }

  void _showSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  int get _totalPhotos => _existingPhotos.length + _newPhotos.length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '📷 Fotos de la Mascota',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _totalPhotos > 0
                    ? colorScheme.secondary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_totalPhotos/5',
                style: TextStyle(
                  color: _totalPhotos > 0 ? colorScheme.secondary : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_totalPhotos == 0)
          Text(
            'Mínimo 1 foto, máximo 5. La primera será la principal.',
            style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
          ),
        const SizedBox(height: 16),

        // Grid de fotos
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _totalPhotos + (_totalPhotos < 5 ? 1 : 0),
          itemBuilder: (context, index) {
            // Última celda: botón para agregar
            if (index == _totalPhotos) {
              return _buildAddButton(context);
            }

            // Celda de foto
            final isExisting = index < _existingPhotos.length;
            final isPrimary = index == _primaryIndex;

            return _buildPhotoCard(
              context: context,
              index: index,
              isExisting: isExisting,
              isPrimary: isPrimary,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _showSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          border:
              Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.primary.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded,
                size: 32, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              'Agregar',
              style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard({
    required BuildContext context,
    required int index,
    required bool isExisting,
    required bool isPrimary,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // Imagen
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isPrimary ? colorScheme.primary : Colors.transparent,
              width: isPrimary ? 3 : 0,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: isExisting
                ? Image.network(
                    _existingPhotos[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Image.file(
                    _newPhotos[index - _existingPhotos.length],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
          ),
        ),

        // Badge "PRINCIPAL"
        if (isPrimary)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Text(
                'PRINCIPAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Botón eliminar
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.close, size: 16, color: colorScheme.error),
            ),
          ),
        ),

        // Botón marcar como principal
        if (!isPrimary)
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _setPrimary(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(Icons.star_border,
                    size: 20, color: colorScheme.primary),
              ),
            ),
          ),
      ],
    );
  }
}
