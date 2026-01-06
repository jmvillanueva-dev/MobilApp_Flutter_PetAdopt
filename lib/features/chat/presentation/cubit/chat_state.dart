import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

/// Estados posibles del chat.
///
/// Usamos sealed class para que Dart sepa que estos son todos los estados posibles
/// y pueda hacer exhaustive checking en los switch statements.
sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial cuando el chat acaba de abrirse.
class ChatInitial extends ChatState {}

/// Estado de carga mientras esperamos la respuesta de la IA.
/// Mantiene los mensajes actuales para mostrarlos durante la carga.
class ChatLoading extends ChatState {
  final List<MessageEntity> messages;

  const ChatLoading(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Estado cuando el chat está cargado con mensajes.
class ChatLoaded extends ChatState {
  final List<MessageEntity> messages;

  const ChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Estado de error con mensaje descriptivo.
/// Mantiene los mensajes para que el usuario no pierda el contexto.
class ChatError extends ChatState {
  final String errorMessage;
  final List<MessageEntity> messages;

  const ChatError(this.errorMessage, this.messages);

  @override
  List<Object?> get props => [errorMessage, messages];
}
