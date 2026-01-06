import 'package:equatable/equatable.dart';

/// Entidad que representa un mensaje en el chat.
///
/// Propiedades:
/// - [text]: contenido del mensaje
/// - [isUser]: true si el mensaje es del usuario, false si es de la IA
/// - [timestamp]: momento en que se generó el mensaje
class MessageEntity extends Equatable {
  /// El texto del mensaje
  final String text;

  /// Indica si el mensaje es del usuario (true) o de la IA (false)
  final bool isUser;

  /// Fecha y hora de creación del mensaje
  final DateTime timestamp;

  const MessageEntity({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [text, isUser, timestamp];
}
