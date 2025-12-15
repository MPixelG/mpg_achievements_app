
import 'dart:convert';

void parseTextureJson(String jsonString) {
  final Map<String, dynamic> textureData = jsonDecode(jsonString);

  textureData.forEach((key, value) {
    print('Texture Name: $key');
    print('Properties: $value');
  });
}