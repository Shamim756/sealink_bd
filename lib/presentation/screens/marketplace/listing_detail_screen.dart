import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/fish_listing_model.dart';
import '../../../data/repositories/listing_repository.dart';
import '../../../data/datasources/socket_service.dart';
import '../../../providers/auth_provider.dart';
import '../order/place_order_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final int listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _repo = ListingRepository();
  final _socket = SocketService();
  final _commentCtrl = TextEditingController();

  FishListingModel? _listing;
  List<CommentModel> _comments = [];
  bool _loading = true;
  bool _posting = false;
  bool _reacting = false;

  int _likes = 0;
  int _dislikes = 0;
  String? _userReaction;

  double _supplierAvg = 0;
  int _supplierTotal = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _initSocket();
  }

  Future<void> _load() async {
    final listing = await _repo.getListing(widget.listingId);
    final commentsRaw = await _repo.getComments(widget.listingId);

    if (!mounted) return;

    setState(() {
      _listing = listing;
      if (listing != null) {
        _likes = listing.likeCount;
        _dislikes = listing.dislikeCount;
        _userReaction = listing.userReaction;
      }
      _comments = commentsRaw
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _loading = false;
    });

    if (listing != null) {
      final rating = await _repo.getUserRating(listing.supplierId);
      if (!mounted) return;
      setState(() {
        _supplierAvg = (rating['average'] as num).toDouble();
        _supplierTotal = rating['total'] ?? 0;
      });
    }
  }

  void _initSocket() {
    _socket.connect();

    Future.delayed(const Duration(milliseconds: 700), () {
      _socket.joinListing(widget.listingId);
    });

    _socket.onCommentAdded((data) {
      if (!mounted) return;
      try {
        final newComment = CommentModel.fromJson(data as Map<String, dynamic>);
        if (_comments.any((c) => c.id == newComment.id)) return;
        setState(() => _comments.insert(0, newComment));
      } catch (_) {}
    });

    _socket.onReactionUpdate((data) {
      if (!mounted) return;
      try {
        final map = data as Map<String, dynamic>;
        if (map['listingId'] == widget.listingId) {
          setState(() {
            _likes = map['likes'] ?? _likes;
            _dislikes = map['dislikes'] ?? _dislikes;
          });
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _socket.leaveListing(widget.listingId);
    _commentCtrl.dispose();
    super.dispose();
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
        if (type == 'LIKE') _likes--;
        else _dislikes--;
        _userReaction = null;
      } else {
        if (oldReaction == 'LIKE') _likes--;
        if (oldReaction == 'DISLIKE') _dislikes--;
        if (type == 'LIKE') _likes++;
        else _dislikes++;
        _userReaction = type;
      }
    });

    final r = await _repo.react(listingId: widget.listingId, type: type);
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

  Future<void> _postComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _posting = true);
    final r = await _repo.postComment(
      listingId: widget.listingId,
      content: content,
    );
    if (!mounted) return;
    setState(() => _posting = false);

    if (r['success'] == true) {
      _commentCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r['message'] ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _orderNow() async {
    if (_listing == null) return;
    final auth = context.read<AuthProvider>();

    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to order')),
      );
      return;
    }
    if (auth.user!.role != 'BUYER') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only buyers can place orders')),
      );
      return;
    }
    if (auth.user!.id == _listing!.supplierId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot order your own listing')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceOrderScreen(listing: _listing!),
      ),
    );

    if (result == true && mounted) {
      // Order placed successfully
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canOrder = auth.user != null &&
        auth.user!.role == 'BUYER' &&
        _listing != null &&
        auth.user!.id != _listing!.supplierId;

    return Scaffold(
      appBar: AppBar(title: const Text('Listing Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _listing == null
              ? const Center(child: Text('Listing not found'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageSection(),
                            _buildInfoSection(),
                            _buildReactionBar(),
                            const Divider(height: 1),
                            _buildCommentsSection(),
                          ],
                        ),
                      ),
                    ),
                    _buildCommentInput(),
                    if (canOrder) _buildOrderButton(),
                  ],
                ),
    );
  }

  Widget _buildImageSection() {
    return SizedBox(
      height: 250,
      child: _listing!.imageUrls.isEmpty
          ? Container(
              color: Colors.blue.shade50,
              child: const Center(
                child: Icon(Icons.set_meal, size: 80, color: Color(0xFF0077B6)),
              ),
            )
          : PageView.builder(
              itemCount: _listing!.imageUrls.length,
              itemBuilder: (context, i) => Image.network(
                _listing!.imageUrls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.blue.shade50,
                  child: const Center(
                    child:
                        Icon(Icons.set_meal, size: 80, color: Color(0xFF0077B6)),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _listing!.fishNameBn,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _listing!.fishNameEn,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '৳${_listing!.pricePerKg.toStringAsFixed(0)}/kg',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_listing!.quantityKg.toStringAsFixed(0)} kg',
                  style: const TextStyle(
                    color: Color(0xFF0077B6),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.person, size: 20, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _listing!.supplierName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          _supplierTotal > 0
                              ? '${_supplierAvg.toStringAsFixed(1)} ($_supplierTotal)'
                              : 'No ratings yet',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_listing!.catchDate != null)
            _infoRow(Icons.calendar_today, 'Catch Date', _listing!.catchDate!),
          if (_listing!.locationDisplay.isNotEmpty)
            _infoRow(Icons.location_on, 'Location', _listing!.locationDisplay),
          if (_listing!.description != null &&
              _listing!.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(_listing!.description!),
          ],
        ],
      ),
    );
  }

  Widget _buildReactionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          _reactionButton(
            icon: _userReaction == 'LIKE'
                ? Icons.thumb_up
                : Icons.thumb_up_outlined,
            label: 'Like',
            count: _likes,
            color: _userReaction == 'LIKE'
                ? const Color(0xFF0077B6)
                : Colors.grey.shade700,
            onTap: () => _react('LIKE'),
          ),
          const SizedBox(width: 24),
          _reactionButton(
            icon: _userReaction == 'DISLIKE'
                ? Icons.thumb_down
                : Icons.thumb_down_outlined,
            label: 'Dislike',
            count: _dislikes,
            color: _userReaction == 'DISLIKE'
                ? Colors.red
                : Colors.grey.shade700,
            onTap: () => _react('DISLIKE'),
          ),
        ],
      ),
    );
  }

  Widget _reactionButton({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.comment, size: 20),
              const SizedBox(width: 8),
              Text(
                'Comments (${_comments.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No comments yet. Be the first!',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ..._comments.map(_buildCommentTile),
        ],
      ),
    );
  }

  Widget _buildCommentTile(CommentModel c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF0077B6),
            child: Text(
              c.userName.isNotEmpty ? c.userName[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.timeAgo,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(c.content),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _postComment(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF0077B6),
            child: _posting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _postComment,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _orderNow,
          icon: const Icon(Icons.shopping_cart),
          label: const Text('Order Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0077B6),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}