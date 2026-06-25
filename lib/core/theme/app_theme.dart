import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class AppTheme {
  static ThemeData light(String colorSeed) {
    return FlexThemeData.light(
      scheme: _schemeFromSeed(colorSeed),
      surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
      appBarStyle: FlexAppBarStyle.background,
      tabBarStyle: FlexTabBarStyle.forBackground,
      tooltipsMatchBackground: true,
      useMaterial3: true,
      swapColors: false,
      lightIsWhite: true,
    );
  }

  static ThemeData dark(String colorSeed) {
    return FlexThemeData.dark(
      scheme: _schemeFromSeed(colorSeed),
      surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
      appBarStyle: FlexAppBarStyle.background,
      tabBarStyle: FlexTabBarStyle.forBackground,
      tooltipsMatchBackground: true,
      useMaterial3: true,
      swapColors: false,
      darkIsTrueBlack: true,
    );
  }

  static FlexScheme _schemeFromSeed(String seedName) {
    switch (seedName) {
      case 'blue':   return FlexScheme.blueM3;
      case 'green':  return FlexScheme.greenM3;
      case 'purple': return FlexScheme.purpleM3;
      case 'orange': return FlexScheme.orangeM3;
      case 'red':    return FlexScheme.redM3;
      case 'teal':   return FlexScheme.tealM3;
      case 'pink':   return FlexScheme.pinkM3;
      case 'grey':   return FlexScheme.greys;
      case 'brown':  return FlexScheme.sepia;
      case 'indigo': return FlexScheme.indigoM3;
      default:       return FlexScheme.blueM3;
    }
  }

  static Color colorFromSeed(String seedName) {
    final data = FlexColor.schemes[_schemeFromSeed(seedName)]!;
    return data.light.primary;
  }
}