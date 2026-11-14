import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF0077B6);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    
    // গ্লোবাল ফন্ট এবং সাইজ (ফন্ট সাইজ ফ্যাক্টরের বদলে সরাসরি ফন্ট সাইজ দেওয়া হলো)
    textTheme: GoogleFonts.hindSiliguriTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        bodySmall: TextStyle(fontSize: 14, color: Colors.black54),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // ইনপুট বক্সগুলো বড় এবং ইন্টারঅ্যাকটিভ করা হলো
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      labelStyle: const TextStyle(fontSize: 16),
      hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
      prefixIconColor: Colors.grey.shade600,
    ),

    // বাটনগুলো বড় এবং স্পষ্ট করা হলো
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        elevation: 2,
      ),
    ),

    // অ্যাপবার (AppBar) আরও সুন্দর করা হলো
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(size: 26),
    ),

    // ড্রপডাউন মেনু স্টাইল
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(fontSize: 16),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    ),

    // কার্ডের শ্যাডো ও রেডিয়াস
    cardTheme: CardThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}