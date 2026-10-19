import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/listing_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env ফাইল লোড করা হচ্ছে
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ListingProvider()),
      ],
      child: const SeaLinkApp(),
    ),
  );
}