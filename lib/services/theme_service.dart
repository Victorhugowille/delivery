import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ThemeService {
  final Color _defaultColor = const Color(0xFFFF5722);
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
    final cleanColorString = colorString.trim().toUpperCase();

    if (cleanColorString.startsWith('#') && cleanColorString.length == 7) {
      final hexString = cleanColorString.substring(1);
      try {
        return Color(int.parse('FF$hexString', radix: 16));
      } catch (e) {
        debugPrint("AVISO: Não foi possível converter o hex '$colorString'. Usando a cor padrão.");
        return _defaultColor;
      }
    }

    debugPrint("AVISO: O formato da cor '$colorString' não foi reconhecido. Usando a cor padrão.");
    return _defaultColor;
  }
}

final themeService = ThemeService();