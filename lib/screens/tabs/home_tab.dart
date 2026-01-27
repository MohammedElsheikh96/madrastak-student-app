import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/curriculum.dart';
import '../../models/student_data.dart';
import '../../services/auth_service.dart';
import '../../services/courses_service.dart';
import '../../services/space_service.dart';
import '../../widgets/posts_list_widget.dart';
import '../../widgets/user_header.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Static course ID - will be dynamic in the future
  static const int _staticCourseId = 21273;

  // Services
  final CoursesService _coursesService = CoursesService();
  final SpaceService _spaceService = SpaceService();
  final AuthService _authService = AuthService();

  // User data
  StudentData? _studentData;

  // State for course and space
  Course? _course;
  String? _spaceId;
  bool _isLoadingCourse = true;
  bool _isLoadingSpace = false;
  String? _courseError;
  String? _spaceError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCourseDetails();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getStudentData();
    if (mounted) {
      setState(() {
        _studentData = data;
      });
    }
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoadingCourse = true;
      _courseError = null;
      _spaceError = null;
    });

    try {
      // Fetch course details from API
      final courseDetails = await _coursesService.getCourseById(
        _staticCourseId,
      );

      if (courseDetails != null) {
        // Convert CourseDetails to Course for PostsListWidget
        _course = _convertToCourse(courseDetails);

        if (mounted) {
          setState(() {
            _isLoadingCourse = false;
            _isLoadingSpace = true;
          });
        }

        // Now load the space for this course
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

  /// Convert CourseDetails to Course model for PostsListWidget
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
      enrollmentType: 0, // Not available in CourseDetails
      type: 0, // Not available in CourseDetails
      isLive: details.isLive,
      numOfTasks: 0, // Not available in CourseDetails
      completedTasksPercentage: details.percentage.toDouble(),
      bundleOnly: details.bundleOnly,
    );
  }

  Future<void> _retryLoad() async {
    await _loadCourseDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Show loading while course is being fetched
    if (_isLoadingCourse) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0F6EB7)),
            SizedBox(height: 16),
            Text(
              'جاري تحميل بيانات المادة...',
              style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
            ),
          ],
        ),
      );
    }

    // Show error if course failed to load
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
              onPressed: _retryLoad,
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

    // Show PostsListWidget with course data
    if (_course != null) {
      return PostsListWidget(
        course: _course!,
        spaceId: _spaceId,
        isLoadingSpace: _isLoadingSpace,
        spaceError: _spaceError,
        onRetryLoadSpace: _loadSpace,
        showCourseHeader: true,
        userName: _studentData?.userBasicInfo.name ?? 'مستخدم',
        userImage: _studentData?.userBasicInfo.profilePicture,
      );
    }

    // Fallback
    return const Center(child: Text('لا توجد بيانات'));
  }

  Widget _buildHeader(BuildContext context) {
    return UserHeader(
      userName: _studentData?.userBasicInfo.name ?? 'مستخدم',
      userImage: _studentData?.userBasicInfo.profilePicture,
    );
  }
}
