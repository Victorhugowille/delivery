import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ThemeService {
  // Cor padrão do aplicativo (Deep Orange)
  final Color _defaultColor = const Color(0xFFFF5722);
  
  // Agora o notifier guarda um objeto 'Color' simples
  late final ValueNotifier<Color> colorNotifier;

  ThemeService() {
    colorNotifier = ValueNotifier(_defaultColor);
  }

  void updateTheme(String? colorString) {
    debugPrint("--- DEBUG THEME ---");
    debugPrint("1. ThemeService.updateTheme foi chamado com o valor: '$colorString'");

    if (colorString == null || colorString.isEmpty) {
      debugPrint("2. O valor da cor é nulo ou vazio. Redefinindo para o padrão.");
      resetToDefault();
      return;
    }
    
    Color newColor = _colorFromString(colorString);
    debugPrint("3. A string de cor foi convertida para o objeto Color: $newColor");
    colorNotifier.value = newColor;
    debugPrint("4. Tema atualizado com sucesso.");
  }

  void resetToDefault() {
    colorNotifier.value = _defaultColor;
  }

  Color _colorFromString(String colorString) {
    final Map<String, Color> colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'teal': Colors.teal,
      'black': Colors.black,
    };
    if (colorMap.containsKey(colorString.toLowerCase())) {
      return colorMap[colorString.toLowerCase()]!;
    }

    if (colorString.startsWith('#') && colorString.length == 7) {
      final hexString = colorString.substring(1);
      return Color(int.parse('FF$hexString', radix: 16));
    }
    
    debugPrint("AVISO: O formato da cor '$colorString' não foi reconhecido. Usando a cor padrão.");
    return _defaultColor;
  }
}

final themeService = ThemeService();