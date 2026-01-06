import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/adoption_bloc.dart';
import '../bloc/adoption_event.dart';
import '../bloc/adoption_state.dart';
import '../pages/adoption_requests_page.dart';

class CreateAdoptionRequestDialog extends StatefulWidget {
  final String petId;
  final String petName;
  final String shelterId;

  const CreateAdoptionRequestDialog({
    super.key,
    required this.petId,
    required this.petName,
    required this.shelterId,
  });

  @override
  State<CreateAdoptionRequestDialog> createState() =>
      _CreateAdoptionRequestDialogState();
}

class _CreateAdoptionRequestDialogState
    extends State<CreateAdoptionRequestDialog> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdoptionBloc, AdoptionState>(
      listener: (context, state) {
        if (state is AdoptionOperationSuccess) {
          Navigator.of(context).pop(); // Cerrar diálogo

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitud enviada exitosamente 🎉'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navegación automática opcional tras breve delay o directa
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdoptionRequestsPage()),
          );
        } else if (state is AdoptionError) {
          // Si es error de duplicado (lo identificamos por el mensaje), cerramos el diálogo
          if (state.message.contains('solicitud pendiente')) {
            Navigator.of(context).pop();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: AlertDialog(
        title: Text('Adoptar a ${widget.petName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cuéntale al refugio por qué quieres adoptar a esta mascota. ¡Tu mensaje es importante!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu mensaje aquí...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          BlocBuilder<AdoptionBloc, AdoptionState>(
            builder: (context, state) {
              if (state is AdoptionLoading) {
                return const CircularProgressIndicator();
              }
              return ElevatedButton(
                onPressed: () {
                  context.read<AdoptionBloc>().add(
                        CreateAdoptonRequest(
                          petId: widget.petId,
                          shelterId: widget.shelterId,
                          message: _messageController.text,
                        ),
                      );
                },
                child: const Text('Enviar Solicitud'),
              );
            },
          ),
        ],
      ),
    );
  }
}
