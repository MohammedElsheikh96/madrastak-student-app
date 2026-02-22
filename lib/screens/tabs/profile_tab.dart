import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/student_data.dart';
import '../../models/profile_space.dart';
import '../../services/auth_service.dart';
import '../../services/space_service.dart';
import '../../widgets/user_header.dart';
import '../../widgets/posts_list_widget.dart';
import '../../widgets/friends_list_widget.dart';
import '../login_page.dart';
import '../edit_profile_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final SpaceService _spaceService = SpaceService();

  late TabController _tabController;

  StudentData? _studentData;
  ProfileSpace? _profileSpace;
  bool _isLoading = true;
  String? _error;

  static const String _fallbackUserId = 'c5061673-5b5f-4e5e-ab78-d9f51eef3dd2';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Load student data and profile space in parallel
    final results = await Future.wait([
      _authService.getStudentData(),
      _spaceService.getUserProfileSpace(),
    ]);

    if (mounted) {
      final studentData = results[0] as StudentData?;
      final profileResult = results[1] as ProfileSpaceResult;

      setState(() {
        _studentData = studentData;
        _isLoading = false;
        if (profileResult.success && profileResult.profileSpace != null) {
          _profileSpace = profileResult.profileSpace;
        } else {
          _error = profileResult.message;
        }
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          currentName:
              _profileSpace?.name ?? _studentData?.userBasicInfo.name ?? '',
          description: _profileSpace?.description,
          currentProfileImage:
              _profileSpace?.profileImageUrl ??
              _studentData?.userBasicInfo.profilePicture,
          currentCoverImage: _profileSpace?.coverImageUrl,
        ),
      ),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Color(0xFF1976D2)),
            const SizedBox(width: 8),
            Text(
              'تسجيل الخروج',
              style: GoogleFonts.alexandria(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
          style: GoogleFonts.alexandria(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.alexandria(color: const Color(0xFF757575)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'تسجيل الخروج',
              style: GoogleFonts.alexandria(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1976D2)),
      ),
    );

    await _authService.logout();

    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          UserHeader(
            userName:
                _profileSpace?.name ??
                _studentData?.userBasicInfo.name ??
                'مستخدم',
            userImage:
                _profileSpace?.profileImageUrl ??
                _studentData?.userBasicInfo.profilePicture,
            hideUserInfo: true,
            showLogout: true,
            onLogout: _showLogoutConfirmation,
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
              ),
            )
          else if (_error != null && _profileSpace == null)
            Expanded(child: _buildErrorState())
          else ...[
            _buildProfileHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Activity tab - reuse PostsListWidget
                  PostsListWidget(
                    spaceId: _profileSpace?.id,
                    isLoadingSpace: _isLoading,
                    spaceError: _error,
                    onRetryLoadSpace: _loadData,
                    showCourseHeader: false,
                    showCreatePost: true,
                    userName: _studentData?.userBasicInfo.name ?? 'مستخدم',
                    userImage: _studentData?.userBasicInfo.profilePicture,
                    currentUserId: _studentData?.id ?? _fallbackUserId,
                  ),
                  // Friends tab
                  FriendsListWidget(spaceId: _profileSpace?.id),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profileImage =
        _profileSpace?.profileImageUrl ??
        _studentData?.userBasicInfo.profilePicture;
    final userName =
        _profileSpace?.name ?? _studentData?.userBasicInfo.name ?? 'مستخدم';
    final bio = _profileSpace?.description ?? '';

    return SizedBox(
      height: 240,
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
          // Edit profile icon on cover
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: _navigateToEditProfile,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
              ),
            ),
          ),
          // Profile image + name centered
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Bio
                Text(
                  bio,
                  style: GoogleFonts.alexandria(
                    fontSize: 13,
                    color: const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF757575),
        indicator: BoxDecoration(
          color: const Color(0xFF0F6EB7),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F6EB7).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.alexandria(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.alexandria(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'النشاط'),
          Tab(text: 'الزملاء'),
        ],
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
            onPressed: _loadData,
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
