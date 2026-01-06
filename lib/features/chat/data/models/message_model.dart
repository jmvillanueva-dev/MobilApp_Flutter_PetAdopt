import '../../domain/entities/message_entity.dart';

/// Modelo de datos que extiende MessageEntity.
/// En este caso simple, no necesitamos métodos adicionales de serialización
/// ya que los mensajes solo viven en memoria durante la sesión del chat.
class MessageModel extends MessageEntity {
  const MessageModel({
    required super.text,
    required super.isUser,
    required super.timestamp,
  });

  /// Convierte el modelo a entidad (en este caso, ya es compatible)
  MessageEntity toEntity() {
    return MessageEntity(
      text: text,
      isUser: isUser,
      timestamp: timestamp,
    );
  }

  /// Factory para crear desde MessageEntity
  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      text: entity.text,
      isUser: entity.isUser,
      timestamp: entity.timestamp,
    );
  }
}
