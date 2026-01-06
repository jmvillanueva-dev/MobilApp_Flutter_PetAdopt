import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/gemini_remote_data_source.dart';
import '../../domain/entities/message_entity.dart';
import 'chat_state.dart';

/// Cubit que maneja la lógica del chat.
///
/// ¿QUÉ ES UN CUBIT?
/// - Es una clase que gestiona estados (más simple que Bloc)
/// - Recibe "acciones" (llamadas a métodos)
/// - Emite nuevos "estados" cuando algo cambia
/// - La UI escucha estos estados y se actualiza automáticamente
///
/// FLUJO:
/// 1. UI llama a sendMessage("¿Cómo cuido a mi perro?")
/// 2. Cubit agrega el mensaje del usuario a la lista
/// 3. Cubit emite ChatLoading (UI muestra "escribiendo...")
/// 4. Cubit llama a GeminiRemoteDataSource
/// 5. Cuando llega la respuesta, agrega mensaje de IA
/// 6. Cubit emite ChatLoaded (UI muestra todos los mensajes)
class ChatCubit extends Cubit<ChatState> {
  /// Servicio para comunicarse con Gemini
  final GeminiRemoteDataSource _geminiDataSource;

  /// Lista de mensajes de la conversación (en memoria)
  final List<MessageEntity> _messages = [];

  /// Constructor: inicializa con el estado inicial y el servicio
  ChatCubit(this._geminiDataSource) : super(ChatInitial()) {
    // Agregar mensaje de bienvenida inicial
    _addWelcomeMessage();
  }

  /// Agrega el mensaje de bienvenida inicial de la IA
  void _addWelcomeMessage() {
    _messages.add(
      MessageEntity(
        text:
            '¡Hola! Soy tu Asistente PetAdopt. Estoy aquí para ayudarte con el cuidado de tus mascotas. ¿En qué puedo ayudarte hoy?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    emit(ChatLoaded(List.from(_messages)));
  }

  /// Envía un mensaje y obtiene la respuesta de la IA.
  ///
  /// Este método es async porque necesita esperar la respuesta de la API.
  Future<void> sendMessage(String text) async {
    // Ignoramos mensajes vacíos
    if (text.trim().isEmpty) return;

    // 1. Agregamos el mensaje del usuario a nuestra lista
    _messages.add(
      MessageEntity(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    // 2. Emitimos estado de carga con los mensajes actuales
    //    Esto permite a la UI mostrar los mensajes + indicador de carga
    emit(ChatLoading(List.from(_messages)));

    try {
      // 3. Llamamos al servicio pasando la lista completa para contexto
      final response = await _geminiDataSource.sendMessage(_messages);

      // 4. Agregamos la respuesta de la IA a la lista
      _messages.add(
        MessageEntity(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      // 5. Emitimos el nuevo estado con todos los mensajes
      //    List.from() crea una copia para asegurar que Equatable
      //    detecte el cambio (nueva referencia)
      emit(ChatLoaded(List.from(_messages)));
    } catch (e) {
      // Si hay error, emitimos estado de error con el mensaje
      emit(ChatError(e.toString(), List.from(_messages)));
    }
  }

  /// Limpia el chat y vuelve al estado inicial.
  void clearChat() {
    _messages.clear();
    emit(ChatInitial());
  }
}
