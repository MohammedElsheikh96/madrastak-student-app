import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/course.dart';
import '../services/space_service.dart';
import 'course_tabs/tasks_tab.dart';
import 'course_tabs/curriculum_tab.dart';
import 'course_tabs/communication_tab.dart';
import 'course_tabs/assessments_tab.dart';

class CourseDetailsPage extends StatefulWidget {
  final Course course;

  const CourseDetailsPage({super.key, required this.course});

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SpaceService _spaceService = SpaceService();

  final List<String> _tabs = ['المنهج', 'المهام', 'تواصل', 'تقييمات'];

  // Space data
  String? _spaceId;
  bool _isLoadingSpace = true;
  String? _spaceError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _initializeSpace();
  }

  Future<void> _initializeSpace() async {
    setState(() {
      _isLoadingSpace = true;
      _spaceError = null;
    });

    try {
      // First, try to get existing course spaces
      final result = await _spaceService.getCourseSpaces(widget.course.id);

      if (result.success &&
          result.space != null &&
          result.space!.id.isNotEmpty) {
        // Space found, use it
        setState(() {
          _spaceId = result.space!.id;
          _isLoadingSpace = false;
        });
      } else {
        // Space not found, create one
        await _createCourseSpace();
      }
    } catch (e) {
      setState(() {
        _spaceError = 'حدث خطأ في تحميل بيانات المساحة';
        _isLoadingSpace = false;
      });
    }
  }

  Future<void> _createCourseSpace() async {
    try {
      final result = await _spaceService.createDigitalSchoolCourseSpace(
        widget.course.id,
      );

      if (result.success && result.spaceId != null) {
        setState(() {
          _spaceId = result.spaceId;
          _isLoadingSpace = false;
        });
      } else {
        setState(() {
          _spaceError = result.message;
          _isLoadingSpace = false;
        });
      }
    } catch (e) {
      setState(() {
        _spaceError = 'حدث خطأ في إنشاء المساحة';
        _isLoadingSpace = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header with back button and course name
          _buildHeader(),
          // Tab bar
          _buildTabBar(),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CurriculumTab(course: widget.course),
                TasksTab(course: widget.course),
                CommunicationTab(
                  course: widget.course,
                  spaceId: _spaceId,
                  isLoadingSpace: _isLoadingSpace,
                  spaceError: _spaceError,
                  onRetryLoadSpace: _initializeSpace,
                ),
                AssessmentsTab(course: widget.course),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF0F6EB7), Color(0xFF5746AE)],
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Course name
          Expanded(
            child: Text(
              widget.course.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        labelColor: const Color(0xFF0F6EB7),
        unselectedLabelColor: const Color(0xFF757575),
        labelStyle: GoogleFonts.alexandria(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.alexandria(
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: const Color(0xFF0F6EB7),
        indicatorWeight: 3,
        padding: const EdgeInsets.symmetric(vertical: 8),
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}
