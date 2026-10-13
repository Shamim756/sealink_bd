import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/datasources/socket_service.dart';
import '../../../providers/auth_provider.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _repo = OrderRepository();
  final _socket = SocketService();
  List<OrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _initSocket();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await _repo.getMyOrders();
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  void _initSocket() {
    _socket.connect();
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      _socket.joinUser(auth.user!.id);
    }

    _socket.onOrderUpdate((data) {
      if (!mounted) return;
      _load();
    });

    _socket.onNewOrder((data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 New order received!'),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSupplier = auth.user?.role == 'SUPPLIER';

    return Scaffold(
      appBar: AppBar(
        title: Text(isSupplier ? 'Incoming Orders' : 'My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? _emptyView()
                : ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (context, i) => _orderCard(_orders[i], isSupplier),
                  ),
      ),
    );
  }

  Widget _emptyView() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long,
                  size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No orders yet',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orderCard(OrderModel order, bool isSupplier) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: order.id),
            ),
          );
          _load();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (order.primaryImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.primaryImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.blue.shade50,
                          child: const Icon(Icons.set_meal),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.set_meal),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.fishNameBn,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSupplier
                              ? 'Buyer: ${order.buyerName ?? "-"}'
                              : 'Supplier: ${order.supplierName ?? "-"}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '৳${order.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(order.status),
                ],
              ),
              if (order.deliveryDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Delivery: ${order.deliveryDate}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'PENDING':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        break;
      case 'CONFIRMED':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        break;
      case 'IN_TRANSIT':
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade900;
        break;
      case 'DELIVERED':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case 'CANCELLED':
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }

    final label = status[0] + status.substring(1).toLowerCase().replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}