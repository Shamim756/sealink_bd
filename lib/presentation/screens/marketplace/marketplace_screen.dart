import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/listing_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ListingProvider>().loadListings(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
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
    super.dispose();
  }

  Future<void> _openAddListing() async {
    await Navigator.pushNamed(context, '/add-listing');
    if (!mounted) return;
    context.read<ListingProvider>().loadListings(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = context.watch<ListingProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isSupplier = user != null && user.role.toUpperCase() == 'SUPPLIER';

    // Debug (terminal-এ দেখতে পাবেন)
    debugPrint('=== MARKETPLACE ===');
    debugPrint('User: ${user?.username}');
    debugPrint('Role: "${user?.role}"');
    debugPrint('IsSupplier: $isSupplier');
    debugPrint('===================');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<ListingProvider>().loadListings(refresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<ListingProvider>().loadListings(refresh: true),
        child: listingProvider.listings.isEmpty && listingProvider.loading
            ? const Center(child: CircularProgressIndicator())
            : listingProvider.listings.isEmpty
                ? _emptyView()
                : ListView.builder(
                    controller: _scrollCtrl,
                    itemCount: listingProvider.listings.length +
                        (listingProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= listingProvider.listings.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final listing = listingProvider.listings[i];
                      return ListingCard(
                        listing: listing,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ListingDetailScreen(listingId: listing.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
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

  Widget _emptyView() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Column(
            children: [
              Icon(Icons.set_meal, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No listings yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Pull down to refresh',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}