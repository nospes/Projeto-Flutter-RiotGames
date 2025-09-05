import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/profile/presentation/search_page.dart';

void main() {
  runApp(const ProviderScope(child: RiotApp()));
}

class RiotApp extends StatelessWidget {
  const RiotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riot Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0EA5E9), // opcional
        useMaterial3: true,
      ),
      home: const SearchPage(),
    );
  }
}
