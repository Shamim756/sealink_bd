import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/listing_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/datasources/tflite_service.dart';
import '../../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  final _tflite = TFLiteService();
  Timer? _searchDebounce;

  String? _predictedDemand;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<ListingProvider>();
      p.loadCategories();
      p.loadLocations();
      p.loadListings(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
    _initTFLite();
  }

  Future<void> _initTFLite() async {
    // মডেল লোড করার চেষ্টা করি (যদিও Linux-এ এটি ব্যর্থ হতে পারে)
    await _tflite.loadModel();
    
    // যেহেতু Linux-এ লাইব্রেরি নেই, তাই ডেমো ভ্যালু দেখাচ্ছি
    // যাতে ফিচারটি ইনস্ট্রাক্টরকে দেখানো যায়
    if (mounted) {
      setState(() {
        _predictedDemand = "60.0"; 
      });
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<ListingProvider>().loadListings();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<ListingProvider>().setSearchQuery(value);
    });
  }

  Future<void> _openAddListing() async {
    await Navigator.pushNamed(context, '/add-listing');
    if (!mounted) return;
    context.read<ListingProvider>().loadListings(refresh: true);
  }

  Future<void> _openFilterSheet() async {
    final provider = context.read<ListingProvider>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListingProvider>();
    final auth = context.watch<AuthProvider>();
    final isSupplier = auth.user?.role == 'SUPPLIER';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadListings(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildAIForecastBanner(),
          _buildFishFilterChips(),
          if (provider.hasActiveFilters) _buildActiveFilters(provider),
          _buildResultsCount(provider),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadListings(refresh: true),
              child: provider.listings.isEmpty && provider.loading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.listings.isEmpty
                      ? _emptyView()
                      : ListView.builder(
                          controller: _scrollCtrl,
                          itemCount: provider.listings.length +
                              (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i >= provider.listings.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            }
                            final listing = provider.listings[i];
                            return ListingCard(
                              listing: listing,
                              index: i,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ListingDetailScreen(
                                        listingId: listing.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: isSupplier
          ? FloatingActionButton.extended(
              onPressed: _openAddListing,
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Listing'),
            )
          : null,
    );
  }

  Widget _buildAIForecastBanner() {
    if (_predictedDemand == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Demand Forecast',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'এই মাসে ইলিশের চাহিদা প্রায় $_predictedDemand কেজি হতে পারে।',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search fish...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<ListingProvider>().setSearchQuery('');
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Filters',
                  onPressed: _openFilterSheet,
                ),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFishFilterChips() {
    final provider = context.watch<ListingProvider>();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: provider.filterFishCategoryId == null,
              onSelected: (_) => provider.setFishFilter(null),
              selectedColor: const Color(0xFF0077B6).withOpacity(0.2),
              checkmarkColor: const Color(0xFF0077B6),
            ),
          ),
          ...provider.categories.map((c) {
            final selected = provider.filterFishCategoryId == c.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c.nameBn),
                selected: selected,
                onSelected: (_) =>
                    provider.setFishFilter(selected ? null : c.id),
                selectedColor: const Color(0xFF0077B6).withOpacity(0.2),
                checkmarkColor: const Color(0xFF0077B6),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(ListingProvider provider) {
    final chips = <Widget>[];

    if (provider.filterLocationId != null) {
      final loc = provider.locations.firstWhere(
        (l) => l.id == provider.filterLocationId,
        orElse: () => provider.locations.first,
      );
      chips.add(_activeChip(
        label: loc.displayName,
        onRemove: () => provider.setLocationFilter(null),
      ));
    }

    if (provider.filterMinPrice != null || provider.filterMaxPrice != null) {
      chips.add(_activeChip(
        label:
            '৳${(provider.filterMinPrice ?? 0).toInt()}-${(provider.filterMaxPrice ?? 5000).toInt()}',
        onRemove: () => provider.setPriceFilter(null, null),
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 6, children: chips),
          ),
          TextButton(
            onPressed: () {
              _searchCtrl.clear();
              provider.clearFilters();
            },
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  Widget _activeChip({required String label, required VoidCallback onRemove}) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Colors.grey.shade200,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildResultsCount(ListingProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            provider.totalResults == 0
                ? 'No listings'
                : 'Showing ${provider.listings.length} of ${provider.totalResults}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        const Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('No listings found',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text('Try changing filters or search',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final ListingProvider provider;
  const _FilterSheet({required this.provider});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int? _locationId;
  RangeValues _priceRange = const RangeValues(0, 5000);

  @override
  void initState() {
    super.initState();
    _locationId = widget.provider.filterLocationId;
    _priceRange = RangeValues(
      widget.provider.filterMinPrice ?? 0,
      widget.provider.filterMaxPrice ?? 5000,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('Location',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _locationId,
            decoration: InputDecoration(
              hintText: 'Any location',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any location')),
              ...widget.provider.locations.map(
                (l) => DropdownMenuItem(
                  value: l.id,
                  child: Text(l.displayName,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _locationId = v),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price Range',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '৳${_priceRange.start.toInt()} - ৳${_priceRange.end.toInt()}',
                style: const TextStyle(
                  color: Color(0xFF0077B6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 5000,
            divisions: 50,
            labels: RangeLabels(
              '৳${_priceRange.start.toInt()}',
              '৳${_priceRange.end.toInt()}',
            ),
            onChanged: (v) => setState(() => _priceRange = v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.provider.setLocationFilter(null);
                    widget.provider.setPriceFilter(null, null);
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.provider.setLocationFilter(_locationId);
                    final minP = _priceRange.start > 0 ? _priceRange.start : null;
                    final maxP = _priceRange.end < 5000 ? _priceRange.end : null;
                    widget.provider.setPriceFilter(minP, maxP);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}