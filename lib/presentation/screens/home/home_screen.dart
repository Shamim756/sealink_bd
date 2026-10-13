import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isSupplier = user?.role == 'SUPPLIER';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SeaLink BD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, size: 70, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?.name ?? "User"}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.person, 'Username', user?.username ?? '-'),
            _infoRow(Icons.email, 'Email', user?.email ?? '-'),
            _infoRow(Icons.phone, 'Phone', user?.phone ?? '-'),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                user?.role ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: isSupplier
                  ? Colors.orange.shade700
                  : const Color(0xFF0077B6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            const SizedBox(height: 30),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/marketplace'),
                icon: const Icon(Icons.storefront),
                label: const Text('Marketplace'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/my-orders'),
                icon: Icon(isSupplier ? Icons.receipt_long : Icons.receipt),
                label: Text(isSupplier ? 'Incoming Orders' : 'My Orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}