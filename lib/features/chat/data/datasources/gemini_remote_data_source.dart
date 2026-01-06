import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/message_entity.dart';

/// Servicio para comunicación con la API de Google Gemini.
///
/// Responsabilidades:
/// - Enviar mensajes a Gemini con contexto conversacional
/// - Procesar respuestas de la API
/// - Manejar errores de comunicación
class GeminiRemoteDataSource {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Prompt del sistema para personalizar el asistente
  static const String _systemPrompt = '''
Eres un asistente experto en cuidado de mascotas. Tu nombre es "Asistente PetAdopt". 
Proporciona consejos útiles, precisos y compasivos sobre salud, alimentación, 
comportamiento y cuidado general de perros y gatos. Responde en español de 
manera amigable y accesible. Si te preguntan sobre adopción o refugios, 
menciona que PetAdopt es una aplicación que conecta adoptantes con refugios.
''';

  String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
          'Falta la variable de entorno GEMINI_API_KEY en el archivo .env');
    }
    return key;
  }

  /// Envía un mensaje y su historial a Gemini para obtener una respuesta.
  ///
  /// [messages]: Lista completa de mensajes de la conversación.
  /// El último mensaje debe ser del usuario.
  ///
  /// Returns: La respuesta generada por Gemini.
  /// Throws: [Exception] si hay un error en la comunicación o respuesta.
  Future<String> sendMessage(List<MessageEntity> messages) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');

      // 1) Mensaje actual (último que escribió el usuario)
      final currentMessage = messages.last;

      // 2) Historial previo sin el actual
      final history = messages.sublist(0, messages.length - 1);

      // 3) Limitamos a los últimos 3 mensajes previos para no exceder límites
      final recentHistory =
          history.length > 3 ? history.sublist(history.length - 3) : history;

      // 4) Contexto final: prompt del sistema + historial reciente + mensaje actual
      final contextToSend = [...recentHistory, currentMessage];

      // 5) Mapeamos al formato que espera la API de Gemini
      final contents = [
        // Primer mensaje: contexto del sistema
        {
          'role': 'user',
          'parts': [
            {'text': _systemPrompt},
          ],
        },
        {
          'role': 'model',
          'parts': [
            {
              'text':
                  '¡Hola! Soy tu Asistente PetAdopt. Estoy aquí para ayudarte con el cuidado de tus mascotas. ¿En qué puedo ayudarte hoy?'
            },
          ],
        },
        // Luego el historial + mensaje actual
        ...contextToSend.map((msg) {
          return {
            'role': msg.isUser ? 'user' : 'model',
            'parts': [
              {'text': msg.text},
            ],
          };
        }).toList(),
      ];

      final body = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 8192,
          'topP': 0.8,
          'topK': 40,
        },
      });

      // Hacemos la petición POST a la API de Gemini
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data == null ||
            data['candidates'] == null ||
            data['candidates'].isEmpty) {
          throw Exception('Respuesta inválida de Gemini: ${response.body}');
        }

        final candidate = data['candidates'][0];

        if (candidate['content'] == null) {
          throw Exception(
            'No hay contenido en la respuesta de Gemini: ${response.body}',
          );
        }

        final content = candidate['content'];

        String? text;

        if (content['parts'] != null && content['parts'].isNotEmpty) {
          text = content['parts'][0]['text'];
        } else if (content['text'] != null) {
          text = content['text'];
        }

        if (text == null || text.isEmpty) {
          throw Exception(
            'No se encontró texto en la respuesta de Gemini: ${response.body}',
          );
        }

        return text;
      } else {
        throw Exception(
          'Error de Gemini (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error al comunicarse con Gemini: $e');
    }
  }
}
