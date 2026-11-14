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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('SeaLink BD'),
        actions: [
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0077B6).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0077B6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome, ${user?.name ?? "User"}!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Menu Grid
            _buildMenuCard(
              title: 'Marketplace',
              subtitle: 'Browse & order fresh fish',
              icon: Icons.storefront,
              color: const Color(0xFF0077B6),
              onTap: () => Navigator.pushNamed(context, '/marketplace'),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              title: isSupplier ? 'Incoming Orders' : 'My Orders',
              subtitle: 'Manage your purchases/sales',
              icon: Icons.receipt_long,
              color: Colors.orange.shade700,
              onTap: () => Navigator.pushNamed(context, '/my-orders'),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              title: 'AI মাছ সহকারী',
              subtitle: 'Ask about fish prices or diseases',
              icon: Icons.smart_toy,
              color: Colors.purple.shade700,
              onTap: () => Navigator.pushNamed(context, '/ai-chat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}