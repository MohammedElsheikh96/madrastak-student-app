import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/friend.dart';
import '../services/space_service.dart';
import '../screens/user_space_page.dart';

class FriendsListWidget extends StatefulWidget {
  final String? spaceId;

  const FriendsListWidget({super.key, this.spaceId});

  @override
  State<FriendsListWidget> createState() => _FriendsListWidgetState();
}

class _FriendsListWidgetState extends State<FriendsListWidget> {
  final SpaceService _spaceService = SpaceService();
  final ScrollController _scrollController = ScrollController();
  final List<Friend> _friends = [];
  int _pageNumber = 1;
  final int _pageSize = 10;
  int _totalCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.spaceId != null) {
      _loadFriends();
    }
  }

  @override
  void didUpdateWidget(FriendsListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spaceId != null && widget.spaceId != oldWidget.spaceId) {
      _resetAndLoad();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreFriends();
    }
  }

  void _resetAndLoad() {
    setState(() {
      _friends.clear();
      _pageNumber = 1;
      _totalCount = 0;
      _error = null;
    });
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    if (widget.spaceId == null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _spaceService.getFriendsList(
        spaceId: widget.spaceId!,
        pageNumber: _pageNumber,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success && result.friends != null) {
            _friends.addAll(result.friends!);
            _totalCount = result.totalCount;
            _pageNumber++;
          } else if (!result.success) {
            _error = result.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'حدث خطأ في تحميل الأصدقاء';
        });
      }
    }
  }

  Future<void> _loadMoreFriends() async {
    if (_isLoadingMore || _isLoading || widget.spaceId == null) return;
    if (_friends.length >= _totalCount && _totalCount > 0) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _spaceService.getFriendsList(
        spaceId: widget.spaceId!,
        pageNumber: _pageNumber,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (result.success && result.friends != null) {
            _friends.addAll(result.friends!);
            _totalCount = result.totalCount;
            _pageNumber++;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshFriends() async {
    _resetAndLoad();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.spaceId == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
      );
    }

    // Loading state
    if (_isLoading && _friends.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
      );
    }

    // Error state
    if (_error != null && _friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF757575)),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.alexandria(
                fontSize: 14,
                color: const Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFriends,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6EB7),
                foregroundColor: Colors.white,
              ),
              child: Text('إعادة المحاولة', style: GoogleFonts.alexandria()),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_friends.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 48, color: Color(0xFF757575)),
            const SizedBox(height: 16),
            Text(
              'لا يوجد أصدقاء بعد',
              style: GoogleFonts.alexandria(
                fontSize: 14,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFriends,
      color: const Color(0xFF0F6EB7),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _friends.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _friends.length) {
            return _buildFriendCard(_friends[index]);
          }
          // Loading more indicator
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendCard(Friend friend) {
    return GestureDetector(
      onTap: () {
        if (friend.spaceId != null && friend.spaceId!.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserSpacePage(spaceId: friend.spaceId!),
            ),
          );
        }
      },
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: friend.profileImageUrl != null &&
                      friend.profileImageUrl!.isNotEmpty
                  ? Image.network(
                      friend.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
          const SizedBox(width: 12),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name ?? '',
                  style: GoogleFonts.alexandria(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                if (friend.role != null && friend.role!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    friend.role!,
                    style: GoogleFonts.alexandria(
                      fontSize: 12,
                      color: const Color(0xFF757575),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Chat icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFF0F6EB7),
              size: 20,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF2C3E50),
      child: const Icon(Icons.person, size: 28, color: Colors.white70),
    );
  }
}
