import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/student_data.dart';
import '../../services/auth_service.dart';
import '../../services/courses_service.dart';
import '../../widgets/user_header.dart';
import '../course_details_page.dart';

class StudyMaterialsTab extends StatefulWidget {
  const StudyMaterialsTab({super.key});

  @override
  State<StudyMaterialsTab> createState() => _StudyMaterialsTabState();
}

class _StudyMaterialsTabState extends State<StudyMaterialsTab> {
  final CoursesService _coursesService = CoursesService();
  final AuthService _authService = AuthService();
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;
  StudentData? _studentData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCourses();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getStudentData();
    if (mounted) {
      setState(() {
        _studentData = data;
      });
    }
  }

  Future<void> _loadCourses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final courses = await _coursesService.getBundleCourses();

      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في تحميل المواد الدراسية';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return UserHeader(
      userName: _studentData?.userBasicInfo.name ?? 'مستخدم',
      userImage: _studentData?.userBasicInfo.profilePicture,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1976D2)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 60, color: Color(0xFFBDBDBD)),
            SizedBox(height: 16),
            Text(
              'لا توجد مواد دراسية',
              style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCourses,
      color: const Color(0xFF1976D2),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          return _buildCourseCard(_courses[index]);
        },
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final colorCode = course.color?.code ?? '#1976D2';
    final color = _parseColor(colorCode);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CourseDetailsPage(course: course),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: course.image != null && course.image!.isNotEmpty
                    ? Image.network(
                        course.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder(color);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: color.withValues(alpha: 0.1),
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: color,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      )
                    : _buildPlaceholder(color),
              ),
              // Gradient overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Course name at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    course.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Tasks count badge (top-left)
              if (course.numOfTasks > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F6EB7),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(0),
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      '${course.numOfTasks} مهام',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.6), color],
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book, size: 60, color: Colors.white54),
      ),
    );
  }

  Color _parseColor(String colorCode) {
    try {
      final hex = colorCode.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF1976D2);
    }
  }
}
