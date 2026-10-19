import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../data/models/fish_listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../data/datasources/socket_service.dart';
import '../../data/repositories/listing_repository.dart';

class ListingCard extends StatefulWidget {
  final FishListingModel listing;
  final VoidCallback? onTap;
  final int index; // অ্যানিমেশনের জন্য ইনডেক্স

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.index = 0,
  });

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  final _repo = ListingRepository();
  final _socket = SocketService();

  late int _likes;
  late int _dislikes;
  String? _userReaction;
  bool _reacting = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.listing.likeCount;
    _dislikes = widget.listing.dislikeCount;
    _userReaction = widget.listing.userReaction;

    _socket.connect();
    _socket.joinListing(widget.listing.id);

    _socket.onReactionUpdate((data) {
      if (!mounted) return;
      try {
        final map = data as Map<String, dynamic>;
        if (map['listingId'] == widget.listing.id) {
          setState(() {
            _likes = map['likes'] ?? _likes;
            _dislikes = map['dislikes'] ?? _dislikes;
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _react(String type) async {
    if (_reacting) return;

    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to react')),
      );
      return;
    }

    final oldReaction = _userReaction;
    final oldLikes = _likes;
    final oldDislikes = _dislikes;

    setState(() {
      _reacting = true;
      if (oldReaction == type) {
        if (type == 'LIKE') {
          _likes--;
        } else {
          _dislikes--;
        }
        _userReaction = null;
      } else {
        if (oldReaction == 'LIKE') _likes--;
        if (oldReaction == 'DISLIKE') _dislikes--;
        if (type == 'LIKE') {
          _likes++;
        } else {
          _dislikes++;
        }
        _userReaction = type;
      }
    });

    final r = await _repo.react(listingId: widget.listing.id, type: type);

    if (!mounted) return;
    setState(() => _reacting = false);

    if (r['success'] == true) {
      setState(() {
        _likes = r['likes'];
        _dislikes = r['dislikes'];
        _userReaction = r['userReaction'];
      });
    } else {
      setState(() {
        _likes = oldLikes;
        _dislikes = oldDislikes;
        _userReaction = oldReaction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: listing.primaryImage != null
                  ? Image.network(
                      listing.primaryImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.fishNameBn,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '৳${listing.pricePerKg.toStringAsFixed(0)}/kg',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.fishNameEn,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.scale, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${listing.quantityKg.toStringAsFixed(0)} kg'),
                      const SizedBox(width: 16),
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.supplierName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (listing.locationDisplay.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.locationDisplay,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _reactionButton(
                        icon: _userReaction == 'LIKE'
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        count: _likes,
                        color: _userReaction == 'LIKE'
                            ? const Color(0xFF0077B6)
                            : Colors.grey.shade700,
                        onTap: () => _react('LIKE'),
                      ),
                      const SizedBox(width: 16),
                      _reactionButton(
                        icon: _userReaction == 'DISLIKE'
                            ? Icons.thumb_down
                            : Icons.thumb_down_outlined,
                        count: _dislikes,
                        color: _userReaction == 'DISLIKE'
                            ? Colors.red
                            : Colors.grey.shade700,
                        onTap: () => _react('DISLIKE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (widget.index * 100).ms) // সিরিয়ালি লোড হবে
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _reactionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.blue.shade50,
      child: const Center(
        child: Icon(Icons.set_meal, size: 50, color: Color(0xFF0077B6)),
      ),
    );
  }
}