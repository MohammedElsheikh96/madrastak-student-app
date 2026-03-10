import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/course.dart';
import '../../models/curriculum.dart';
import '../../models/home_sections.dart';
import '../../models/student_data.dart';
import '../../models/task.dart';
import '../../services/auth_service.dart';
import '../../services/courses_service.dart';
import '../../services/space_service.dart';
import '../../widgets/home_sections.dart';
import '../../widgets/posts_list_widget.dart';
import '../../widgets/user_header.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const int _staticCourseId = 21273;
  static const String _fallbackUserId = 'c5061673-5b5f-4e5e-ab78-d9f51eef3dd2';

  final CoursesService _coursesService = CoursesService();
  final SpaceService _spaceService = SpaceService();
  final AuthService _authService = AuthService();

  // User data
  StudentData? _studentData;

  // Course & space state
  Course? _course;
  String? _spaceId;
  bool _isLoadingCourse = true;
  bool _isLoadingSpace = false;
  String? _courseError;
  String? _spaceError;

  // Home sections data
  List<LiveSession> _liveSessions = [];
  List<RecommendedVideo> _recommendedVideos = [];
  List<Task> _todayTasks = [];
  int _incompleteTaskCount = 0;
  List<int> _allCourseIds = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCourseDetails();
    _loadHomeSections();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getStudentData();
    if (mounted) {
      setState(() => _studentData = data);
    }
  }

  Future<void> _loadHomeSections() async {
    final results = await Future.wait([
      _coursesService.getLiveSessions(),
      _coursesService.getRecommendedContent(),
      _coursesService.getBundleCourses(),
    ]);

    final liveSessions = results[0] as List<LiveSession>;
    final recommendedVideos = results[1] as List<RecommendedVideo>;
    final courses = results[2] as List<Course>;

    _allCourseIds = courses.map((c) => c.id).toList();

    if (mounted) {
      setState(() {
        _liveSessions = liveSessions;
        _recommendedVideos = recommendedVideos;
      });
    }

    if (_allCourseIds.isNotEmpty) {
      final userId = _studentData?.id ?? _fallbackUserId;
      final tasksResponse = await _coursesService.getTasksByDayMultiCourse(
        userId,
        _allCourseIds,
      );
      if (mounted && tasksResponse != null && tasksResponse.success) {
        setState(() {
          _todayTasks = tasksResponse.allTasks;
          _incompleteTaskCount = tasksResponse.incompleteCount;
        });
      }
    }
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoadingCourse = true;
      _courseError = null;
      _spaceError = null;
    });

    try {
      final courseDetails = await _coursesService.getCourseById(
        _staticCourseId,
      );

      if (courseDetails != null) {
        _course = _convertToCourse(courseDetails);
        if (mounted) {
          setState(() {
            _isLoadingCourse = false;
            _isLoadingSpace = true;
          });
        }
        await _loadSpace();
      } else {
        if (mounted) {
          setState(() {
            _isLoadingCourse = false;
            _courseError = 'فشل في تحميل بيانات المادة';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCourse = false;
          _courseError = 'حدث خطأ في تحميل البيانات';
        });
      }
    }
  }

  Future<void> _loadSpace() async {
    try {
      final spaceResult = await _spaceService.getCourseSpaces(_staticCourseId);

      if (mounted) {
        setState(() {
          _isLoadingSpace = false;
          if (spaceResult.success && spaceResult.space != null) {
            _spaceId = spaceResult.space!.id;
          } else if (spaceResult.success && spaceResult.spaceId != null) {
            _spaceId = spaceResult.spaceId;
          } else {
            _spaceError = spaceResult.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSpace = false;
          _spaceError = 'حدث خطأ في تحميل المساحة';
        });
      }
    }
  }

  Course _convertToCourse(CourseDetails details) {
    return Course(
      id: details.id,
      name: details.name,
      arabicName: details.arabicName,
      duration: details.duration,
      arabicDuration: details.arabicDuration,
      image: details.image,
      coverImage: details.coverImage,
      status: details.status,
      numOfSales: details.numOfSales,
      rate: details.rate,
      releaseDate: details.releaseDate,
      expirationDate: details.expirationDate,
      isLifeTime: details.isLifeTime,
      isDeleted: details.isDeleted,
      courseSubscribed: details.courseSubscribed,
      enrollmentType: 0,
      type: 0,
      isLive: details.isLive,
      numOfTasks: 0,
      completedTasksPercentage: details.percentage.toDouble(),
      bundleOnly: details.bundleOnly,
    );
  }

  bool get _hasSections =>
      _liveSessions.isNotEmpty ||
      _todayTasks.isNotEmpty ||
      _recommendedVideos.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Top user header with notifications
          UserHeader(
            userName: _studentData?.userBasicInfo.name ?? 'مستخدم',
            userImage: _studentData?.userBasicInfo.profilePicture,
          ),
          // Main scrollable content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingCourse) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
      );
    }

    if (_courseError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF757575)),
            const SizedBox(height: 16),
            Text(
              _courseError!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCourseDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6EB7),
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_course == null) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    // Build the dashboard sections that go above the posts
    return PostsListWidget(
      course: _course!,
      spaceId: _spaceId,
      isLoadingSpace: _isLoadingSpace,
      spaceError: _spaceError,
      onRetryLoadSpace: _loadSpace,
      showCourseHeader: true,
      userName: _studentData?.userBasicInfo.name ?? 'مستخدم',
      userImage: _studentData?.userBasicInfo.profilePicture,
      currentUserId: _studentData?.id ?? _fallbackUserId,
      headerWidgets: _buildDashboardSections(),
    );
  }

  /// Build the dashboard sections that appear ABOVE the course header.
  /// These are cross-course (shared) sections: live sessions, tasks, videos.
  List<Widget> _buildDashboardSections() {
    if (!_hasSections) return [];

    return [
      // Live sessions
      if (_liveSessions.isNotEmpty || true) // Always show — has empty state
        LiveSessionsSection(sessions: _liveSessions),
      // Today's tasks
      if (_todayTasks.isNotEmpty)
        TodayTasksSection(
          tasks: _todayTasks,
          incompleteCount: _incompleteTaskCount,
          onTaskCompleted: _loadHomeSections,
        ),
      // Recommended videos
      if (_recommendedVideos.isNotEmpty)
        RecommendedVideosSection(videos: _recommendedVideos),
      // Divider between dashboard and course feed
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.forum_outlined,
                    size: 18,
                    color: Color(0xFF0F6EB7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'آخر المنشورات',
                    style: GoogleFonts.alexandria(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
          ],
        ),
      ),
    ];
  }
}
