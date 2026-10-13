import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/listing_provider.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _fishCategoryId;
  int? _locationId;
  DateTime? _catchDate;
  final List<String> _uploadedImageUrls = [];
  final List<XFile> _pickedImages = [];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingProvider>().loadCategories();
      context.read<ListingProvider>().loadLocations();
    });
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 70);
    if (images.isEmpty) return;

    if (!mounted) return;
    setState(() => _uploading = true);

    final provider = context.read<ListingProvider>();
    for (final img in images) {
      final url = await provider.uploadImage(img);
      if (url != null) {
        _uploadedImageUrls.add(url);
        _pickedImages.add(img);
      }
    }

    if (!mounted) return;
    setState(() => _uploading = false);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) setState(() => _catchDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fishCategoryId == null) {
      _snack('Please select a fish category', false);
      return;
    }

    final provider = context.read<ListingProvider>();
    final ok = await provider.createListing(
      fishCategoryId: _fishCategoryId!,
      quantityKg: double.parse(_quantityCtrl.text),
      pricePerKg: double.parse(_priceCtrl.text),
      catchDate: _catchDate != null
          ? DateFormat('yyyy-MM-dd').format(_catchDate!)
          : null,
      locationId: _locationId,
      imageUrls: _uploadedImageUrls,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      _snack('Listing created successfully!', true);
      Navigator.pop(context);
    } else {
      _snack(provider.error ?? 'Failed to create listing', false);
    }
  }

  void _snack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Fish Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _fishCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Fish Category *',
                  prefixIcon: Icon(Icons.set_meal),
                ),
                items: provider.categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.nameBn} (${c.nameEn})'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _fishCategoryId = v),
                validator: (v) => v == null ? 'Select fish category' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity (kg) *',
                  prefixIcon: Icon(Icons.scale),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price per kg (৳) *',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Catch Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _catchDate != null
                        ? DateFormat('yyyy-MM-dd').format(_catchDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _catchDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _locationId,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: provider.locations
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              const Text('Images',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._pickedImages.asMap().entries.map((e) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(e.value.path),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _pickedImages.removeAt(e.key);
                                  _uploadedImageUrls.removeAt(e.key);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )),
                  if (!_uploading)
                    InkWell(
                      onTap: _pickImages,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade100,
                        ),
                        child: const Icon(Icons.add_a_photo,
                            size: 30, color: Colors.grey),
                      ),
                    ),
                  if (_uploading)
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade100,
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: (provider.loading || _uploading) ? null : _submit,
                child: provider.loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Listing'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}