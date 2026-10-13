import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/fish_listing_model.dart';
import '../../../data/models/location_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/listing_repository.dart';

class PlaceOrderScreen extends StatefulWidget {
  final FishListingModel listing;
  const PlaceOrderScreen({super.key, required this.listing});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _orderRepo = OrderRepository();
  final _listingRepo = ListingRepository();

  DateTime? _deliveryDate;
  int? _locationId;
  List<LocationModel> _locations = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locs = await _listingRepo.getLocations();
    if (!mounted) return;
    setState(() => _locations = locs);
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) setState(() => _deliveryDate = date);
  }

  double get _computedTotal {
    final qty = double.tryParse(_quantityCtrl.text) ?? 0;
    return qty * widget.listing.pricePerKg;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.parse(_quantityCtrl.text);

    if (qty > widget.listing.quantityKg) {
      _snack('Only ${widget.listing.quantityKg} kg available', false);
      return;
    }

    setState(() => _loading = true);

    final r = await _orderRepo.createOrder(
      listingId: widget.listing.id,
      quantityKg: qty,
      deliveryDate: _deliveryDate != null
          ? DateFormat('yyyy-MM-dd').format(_deliveryDate!)
          : null,
      deliveryLocationId: _locationId,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (r['success'] == true) {
      _snack('Order placed! Total: ৳${r['total_price']}', true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      _snack(r['message'] ?? 'Failed', false);
    }
  }

  void _snack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    return Scaffold(
      appBar: AppBar(title: const Text('Place Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Listing summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (listing.primaryImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            listing.primaryImage!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.blue.shade50,
                              child: const Icon(Icons.set_meal),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 70,
                          height: 70,
                          color: Colors.blue.shade50,
                          child: const Icon(Icons.set_meal),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.fishNameBn,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '৳${listing.pricePerKg.toStringAsFixed(0)}/kg',
                              style: const TextStyle(color: Colors.green),
                            ),
                            Text(
                              'Available: ${listing.quantityKg.toStringAsFixed(0)} kg',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Quantity (kg) *',
                  prefixIcon: Icon(Icons.scale),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final qty = double.tryParse(v);
                  if (qty == null || qty <= 0) return 'Invalid quantity';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Delivery Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _deliveryDate != null
                        ? DateFormat('yyyy-MM-dd').format(_deliveryDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _deliveryDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: _locationId,
                decoration: const InputDecoration(
                  labelText: 'Delivery Location',
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: _locations
                    .map((l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(
                            l.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _locationId = v),
              ),
              const SizedBox(height: 24),

              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      '৳${_computedTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}