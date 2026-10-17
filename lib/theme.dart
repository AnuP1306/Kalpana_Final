import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Colour tokens copied 1:1 from the Bolt `colors` object.
class K {
  static const ink = Color(0xFF302D3A);
  static const muted = Color(0xFF817B8D);
  static const mutedText = Color(0xFF6A6477); // slightly darker muted, for text contrast
  static const pale = Color(0xFFFAF9FC);
  static const lilac = Color(0xFFCDB9F6);
  static const lilacSoft = Color(0xFFF3EFFB);
  static const blue = Color(0xFFC9DDFB);
  static const green = Color(0xFF82C39B);
  static const coral = Color(0xFFFF7676);
  static const teal = Color(0xFF559BA5);
  static const gold = Color(0xFFBA9448);
  static const purple = Color(0xFF8C76BA);
  static const purpleText = Color(0xFF6F58A0);
  static const btnText = Color(0xFF5E5772);
  static Color line = const Color(0xFFB8B0C8);
  static void setContrast(bool high) =>
      line = high ? const Color(0xFFB8B0C8) : const Color(0xFFEEEAF3);
}

/// Every icon in one place (Lucide, same set Bolt used). If a name fails to
/// compile with your lucide_icons version, fix it here only.
class Ic {
  static const arrowLeft = LucideIcons.arrowLeft;
  static const arrowRight = LucideIcons.arrowRight;
  static const bell = LucideIcons.bell;
  static const camera = LucideIcons.camera;
  static const check = LucideIcons.check;
  static const chevronRight = LucideIcons.chevronRight;
  static const help = LucideIcons.helpCircle;
  static const crosshair = LucideIcons.crosshair;
  static const ear = LucideIcons.ear;
  static const eye = LucideIcons.eye;
  static const fileText = LucideIcons.fileText;
  static const home = LucideIcons.home;
  static const mapPin = LucideIcons.mapPin;
  static const message = LucideIcons.messageCircle;
  static const mic = LucideIcons.mic;
  static const navigation = LucideIcons.navigation;
  static const palette = LucideIcons.palette;
  static const phone = LucideIcons.phone;
  static const play = LucideIcons.play;
  static const radio = LucideIcons.radio;
  static const send = LucideIcons.send;
  static const settings = LucideIcons.settings;
  static const sparkles = LucideIcons.sparkles;
  static const square = LucideIcons.square;
  static const alert = LucideIcons.alertTriangle;
  static const user = LucideIcons.user;
  static const volume = LucideIcons.volume2;
  static const circle = LucideIcons.circle;
}
