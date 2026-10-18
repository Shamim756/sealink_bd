import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
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

  // ==========================================
  // PDF GENERATOR FUNCTION
  // ==========================================
  Future<pw.Document> _createPdf() async {
    final pdf = pw.Document();
    final order = _order!;
    final items = order['items'] as List? ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SeaLink BD', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        pw.SizedBox(height: 4),
                        pw.Text('Seafood Supply Chain', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Order #${order['id']}', style: const pw.TextStyle(fontSize: 14)),
                        pw.Text('Date: ${order['created_at']?.toString().split('T')[0] ?? '-'}', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(order['buyer_name'] ?? '-'),
                        pw.Text(order['buyer_phone'] ?? '-'),
                        pw.Text('${order['upazila'] ?? ''}, ${order['district'] ?? ''}, ${order['division'] ?? ''}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Supplier:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(order['supplier_name'] ?? '-'),
                        pw.Text(order['supplier_phone'] ?? '-'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                pw.TableHelper.fromTextArray(
                  context: context,
                  headers: ['Fish', 'Quantity', 'Price/kg', 'Subtotal'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                  data: items.map((item) {
                    return [
                      item['fish_name_bn'] ?? '-',
                      '${item['quantity_kg']} kg',
                      '৳ ${item['price_per_kg']}',
                      '৳ ${item['subtotal']}',
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 20),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Total:'),
                              pw.Text('৳ ${order['total_price']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.green800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),

                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text('Thank you for using SeaLink BD!', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  // Show Print Preview
  Future<void> _generatePdf() async {
    if (_order == null) return;
    final pdf = await _createPdf();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_Order_${_order!['id']}.pdf',
    );
  }

  // Save PDF to Device
  Future<void> _savePdf() async {
    if (_order == null) return;

    try {
      final pdf = await _createPdf();
      final bytes = await pdf.save();

      // Get Downloads Directory (Linux/Android)
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        // For Linux, macOS, Windows (Saves in /home/user/Downloads)
        dir = await getDownloadsDirectory();
      }

      if (dir == null) throw Exception('Could not find downloads directory');

      final file = File('${dir.path}/Invoice_Order_${_order!['id']}.pdf');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Saved to: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSupplier = auth.user?.role == 'SUPPLIER';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
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

                      // PDF Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _generatePdf,
                              icon: const Icon(Icons.print),
                              label: const Text('Print Preview'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _savePdf,
                              icon: const Icon(Icons.download),
                              label: const Text('Save PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0077B6),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
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