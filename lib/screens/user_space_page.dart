import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/profile_space.dart';
import '../services/space_service.dart';
import '../widgets/posts_list_widget.dart';

class UserSpacePage extends StatefulWidget {
  final String spaceId;

  const UserSpacePage({super.key, required this.spaceId});

  @override
  State<UserSpacePage> createState() => _UserSpacePageState();
}

class _UserSpacePageState extends State<UserSpacePage> {
  final SpaceService _spaceService = SpaceService();

  ProfileSpace? _profileSpace;
  bool _isLoading = true;
  String? _error;
  bool _isFriend = false;
  bool _isFriendActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSpaceData();
  }

  Future<void> _loadSpaceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _spaceService.getSpaceById(widget.spaceId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.profileSpace != null) {
          _profileSpace = result.profileSpace;
          _isFriend = result.profileSpace!.isFriend ?? false;
        } else {
          _error = result.message;
        }
      });
    }
  }

  Future<void> _toggleFriend() async {
    if (_isFriendActionLoading || _profileSpace?.userId == null) return;

    setState(() {
      _isFriendActionLoading = true;
    });

    final userId = _profileSpace!.userId;
    final result = _isFriend
        ? await _spaceService.removeFriend(userId)
        : await _spaceService.addFriend(userId);

    if (mounted) {
      setState(() {
        _isFriendActionLoading = false;
        if (result.success) {
          _isFriend = !_isFriend;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message, style: GoogleFonts.alexandria()),
          backgroundColor: result.success
              ? const Color(0xFF0F6EB7)
              : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // title: Text(
          //   _profileSpace?.name ?? '',
          //   style: GoogleFonts.alexandria(
          //     fontSize: 16,
          //     fontWeight: FontWeight.w600,
          //     color: const Color(0xFF333333),
          //   ),
          // ),
          // centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
              )
            : _error != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildProfileHeader(),
        _buildFriendButton(),
        Expanded(
          child: PostsListWidget(
            spaceId: widget.spaceId,
            showCourseHeader: false,
            showCreatePost: false,
            userName: '',
            currentUserId: null,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final profileImage = _profileSpace?.profileImageUrl;
    final userName = _profileSpace?.name ?? '';
    final bio = _profileSpace?.description ?? '';

    return SizedBox(
      height: bio.isNotEmpty ? 260 : 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover image
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF0F6EB7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child:
                (_profileSpace?.coverImageUrl != null &&
                    _profileSpace!.coverImageUrl!.isNotEmpty)
                ? Image.network(
                    _profileSpace!.coverImageUrl!,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  )
                : null,
          ),
          // Profile image + name + bio centered
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Profile avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profileImage != null && profileImage.isNotEmpty
                        ? Image.network(
                            profileImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFE3F2FD),
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF1976D2),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFFE3F2FD),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                // User name
                Text(
                  userName,
                  style: GoogleFonts.alexandria(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      bio,
                      style: GoogleFonts.alexandria(
                        fontSize: 13,
                        color: const Color(0xFF757575),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: _isFriendActionLoading ? null : _toggleFriend,
          icon: _isFriendActionLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _isFriend ? Icons.person_remove : Icons.person_add,
                  size: 20,
                ),
          label: Text(
            _isFriend ? 'إلغاء الصداقة' : 'إضافة للزملاء',
            style: GoogleFonts.alexandria(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFriend
                ? Colors.red.shade400
                : const Color(0xFF0F6EB7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFF757575)),
          const SizedBox(height: 16),
          Text(
            _error ?? 'حدث خطأ',
            style: GoogleFonts.alexandria(
              fontSize: 14,
              color: const Color(0xFF757575),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSpaceData,
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
}
