import 'package:flutter/material.dart';
import '../../../data/datasources/api_client.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _dio = ApiClient().dio;
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _dio.get('/notifications');
      setState(() {
        _notifications = r.data['notifications'] ?? [];
        _loading = false;
      });
      // Mark as read
      await _dio.put('/notifications/read');
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'ORDER':
        return Icons.shopping_bag;
      case 'COMMENT':
        return Icons.comment;
      case 'LIKE':
        return Icons.thumb_up;
      case 'RATING':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'ORDER':
        return Colors.green;
      case 'COMMENT':
        return Colors.blue;
      case 'LIKE':
        return Colors.indigo;
      case 'RATING':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _timeAgo(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr.replaceAll(' ', 'T'));
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? const Center(child: Text('No notifications yet'))
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isUnread = n['is_read'] == 0 || n['is_read'] == false;

                      return Container(
                        color: isUnread
                            ? const Color(0xFF0077B6).withOpacity(0.05)
                            : Colors.transparent,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _getColor(n['type']).withOpacity(0.2),
                            child: Icon(
                              _getIcon(n['type']),
                              color: _getColor(n['type']),
                            ),
                          ),
                          title: Text(n['content'] ?? ''),
                          subtitle: Text(_timeAgo(n['created_at'])),
                          trailing: isUnread
                              ? const Icon(Icons.circle,
                                  size: 10, color: Colors.blue)
                              : null,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}