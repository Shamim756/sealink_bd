import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SeaLink BD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                'Welcome, ${user?.name ?? "User"}!',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Username: ${user?.username ?? "-"}'),
              const SizedBox(height: 4),
              Text('Email: ${user?.email ?? "-"}'),
              const SizedBox(height: 4),
              Text('Phone: ${user?.phone ?? "-"}'),
              const SizedBox(height: 4),
              Chip(
                label: Text(user?.role ?? "-"),
                backgroundColor: Colors.blue.shade100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Registration complete! ✅',
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}