import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../providers/auth_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _repo = OrderRepository();
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final order = await _repo.getOrder(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = order;
      _loading = false;
    });
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    final r = await _repo.updateStatus(orderId: widget.orderId, status: status);
    if (!mounted) return;
    setState(() => _updating = false);

    if (r['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status: ${status}'),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r['message'] ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSupplier = auth.user?.role == 'SUPPLIER';

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('Order #${_order!['id']}', [
                        _row('Status', _order!['status'] ?? '-'),
                        _row('Total Price',
                            '৳${double.tryParse(_order!['total_price'].toString())?.toStringAsFixed(0) ?? "0"}'),
                        if (_order!['delivery_date'] != null)
                          _row('Delivery Date', _order!['delivery_date']),
                        if (_order!['created_at'] != null)
                          _row('Ordered At', _order!['created_at']),
                      ]),
                      const SizedBox(height: 16),
                      _section('Product', [
                        _row('Fish', _order!['fish_name_bn'] ?? '-'),
                        _row('English', _order!['fish_name_en'] ?? '-'),
                      ]),
                      const SizedBox(height: 16),
                      _section(isSupplier ? 'Buyer' : 'Supplier', [
                        _row(
                          'Name',
                          isSupplier
                              ? (_order!['buyer_name'] ?? '-')
                              : (_order!['supplier_name'] ?? '-'),
                        ),
                        _row(
                          'Phone',
                          isSupplier
                              ? (_order!['buyer_phone'] ?? '-')
                              : (_order!['supplier_phone'] ?? '-'),
                        ),
                      ]),
                      if (_order!['division'] != null) ...[
                        const SizedBox(height: 16),
                        _section('Delivery Location', [
                          _row('Address',
                              '${_order!['upazila'] ?? ''}, ${_order!['district'] ?? ''}, ${_order!['division'] ?? ''}'),
                        ]),
                      ],
                      const SizedBox(height: 24),

                      // Supplier action buttons
                      if (isSupplier) _buildSupplierActions(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSupplierActions() {
    final currentStatus = _order!['status'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Update Status',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (currentStatus == 'PENDING')
          ElevatedButton.icon(
            onPressed: _updating ? null : () => _updateStatus('CONFIRMED'),
            icon: const Icon(Icons.check),
            label: const Text('Confirm Order'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        if (currentStatus == 'CONFIRMED')
          ElevatedButton.icon(
            onPressed: _updating ? null : () => _updateStatus('IN_TRANSIT'),
            icon: const Icon(Icons.local_shipping),
            label: const Text('Mark as In Transit'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        if (currentStatus == 'IN_TRANSIT')
          ElevatedButton.icon(
            onPressed: _updating ? null : () => _updateStatus('DELIVERED'),
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark as Delivered'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        if (currentStatus == 'PENDING' || currentStatus == 'CONFIRMED')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: _updating ? null : () => _updateStatus('CANCELLED'),
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text('Cancel Order',
                  style: TextStyle(color: Colors.red)),
            ),
          ),
        if (_updating)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}