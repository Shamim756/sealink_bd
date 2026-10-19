import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/datasources/socket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _socket = SocketService();
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    _socket.connect();
    _socket.joinUser(auth.user!.id);

    _socket.onNotification((data) {
      if (!mounted) return;
      setState(() => _hasUnread = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 ${data['content']}'),
          backgroundColor: const Color(0xFF0077B6),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isSupplier = user?.role == 'SUPPLIER';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SeaLink BD'),
        actions: [
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/notifications');
                  if (mounted) setState(() => _hasUnread = false);
                },
              ),
              if (_hasUnread)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
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
            
            // Marketplace Button
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
            
            // My Orders Button
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
            const SizedBox(height: 12),

            // AI Chatbot Button (নতুন)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/ai-chat'),
                icon: const Icon(Icons.smart_toy),
                label: const Text('AI মাছ সহকারী'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
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