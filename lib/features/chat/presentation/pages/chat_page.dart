import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/gemini_remote_data_source.dart';
import '../../domain/entities/message_entity.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Pantalla principal del chat con IA.
///
/// Responsabilidades:
/// - Mostrar lista de mensajes
/// - Permitir al usuario escribir y enviar mensajes
/// - Mostrar indicadores de carga y errores
/// - Proporcionar opción para limpiar el chat
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  /// Controlador para el campo de texto
  /// Nos permite leer el texto y limpiarlo después de enviar
  final TextEditingController _controller = TextEditingController();

  /// Controlador para el scroll de la lista
  /// Lo usamos para hacer scroll automático al último mensaje
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // Limpiamos los controladores cuando se destruye el widget
    // Esto es importante para evitar memory leaks
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Hace scroll hasta el final de la lista
  void _scrollToBottom() {
    // Esperamos un frame para que la lista se actualice
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Envía el mensaje al Cubit
  void _sendMessage() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      // Llamamos al método del Cubit
      context.read<ChatCubit>().sendMessage(text);
      // Limpiamos el campo de texto
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ===== APP BAR =====
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asistente PetAdopt'),
            Text(
              'Powered by Gemini AI',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Botón para limpiar el chat
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => context.read<ChatCubit>().clearChat(),
            tooltip: 'Limpiar chat',
          ),
        ],
      ),

      body: Column(
        children: [
          // ===== LISTA DE MENSAJES =====
          Expanded(
            // BlocBuilder reconstruye este widget cuando el estado cambia
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                // Extraemos los mensajes según el tipo de estado
                final messages = switch (state) {
                  ChatInitial() => <MessageEntity>[],
                  ChatLoading(messages: var m) => m,
                  ChatLoaded(messages: var m) => m,
                  ChatError(messages: var m) => m,
                };

                // Si no hay mensajes, mostramos mensaje de bienvenida
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pets,
                            size: 64,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '¡Hola! Soy tu Asistente de Mascotas',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '¿En qué puedo ayudarte hoy?',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Hacemos scroll al final cuando hay nuevos mensajes
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (state is ChatLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Si estamos cargando y es el último item, mostramos indicador
                    if (state is ChatLoading && index == messages.length) {
                      return const TypingIndicator();
                    }
                    // Si no, mostramos la burbuja del mensaje
                    return MessageBubble(message: messages[index]);
                  },
                );
              },
            ),
          ),

          // ===== INDICADOR DE ERROR =====
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatError) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error: ${state.errorMessage}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // ===== CAMPO DE ENTRADA =====
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Campo de texto expandido
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu pregunta...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      // Enviar con Enter
                      onSubmitted: (_) => _sendMessage(),
                      // Permitir múltiples líneas
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón de enviar
                  BlocBuilder<ChatCubit, ChatState>(
                    builder: (context, state) {
                      // Deshabilitamos el botón mientras carga
                      final isLoading = state is ChatLoading;
                      return FloatingActionButton(
                        onPressed: isLoading ? null : _sendMessage,
                        mini: true,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget wrapper que proporciona el ChatCubit a ChatPage.
/// Esto permite que la página funcione de forma independiente.
class ChatPageProvider extends StatelessWidget {
  const ChatPageProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(GeminiRemoteDataSource()),
      child: const ChatPage(),
    );
  }
}
