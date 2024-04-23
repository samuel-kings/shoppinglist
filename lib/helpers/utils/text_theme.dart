import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_schemes.dart';

final lightTextTheme = TextTheme(
  displayLarge: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.bold,
    fontSize: 48,
  ),
  displayMedium: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.bold,
    fontSize: 32,
  ),
  displaySmall: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.bold,
    fontSize: 24,
  ),
  headlineLarge: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  ),
  headlineMedium: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.bold,
    fontSize: 18,
  ),
  headlineSmall: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.w500,
    fontSize: 15,
  ),
  titleLarge: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.w600,
    fontSize: 20,
  ),
  titleMedium: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.w600,
    fontSize: 16.5,
  ),
  titleSmall: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.w500,
    fontSize: 14.5,
  ),
  bodyLarge: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontSize: 16,
  ),
  bodyMedium: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.w500,
    height: 1.5,
    fontSize: 14,
  ),
  bodySmall: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontSize: 12,
  ),
  labelLarge: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
  labelMedium: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  ),
  labelSmall: GoogleFonts.montserrat(
    color: lightColorScheme.onBackground,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  ),
);

final darkTextTheme =
    lightTextTheme.apply(bodyColor: darkColorScheme.onBackground, displayColor: darkColorScheme.onBackground);
