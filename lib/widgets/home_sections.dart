import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course.dart';
import '../models/home_sections.dart';
import '../models/task.dart';
import '../screens/course_details_page.dart';
import '../screens/external_quiz_screen.dart';
import '../screens/video_player_screen.dart';
import '../services/courses_service.dart';
import '../widgets/post_card.dart';

// ─── Study Materials Section (Horizontal Course Cards) ──────

class StudyMaterialsSection extends StatelessWidget {
  final List<Course> courses;

  const StudyMaterialsSection({super.key, required this.courses});

  static const List<Color> _cardBorderColors = [
    Color(0xFF2EC4B6), // teal/cyan
    Color(0xFFE91E63), // pink
    Color(0xFF7C4DFF), // purple
    Color(0xFFFFB300), // amber/gold
    Color(0xFFFF7043), // orange
    Color(0xFF66BB6A), // green
    Color(0xFF42A5F5), // blue
    Color(0xFFEF5350), // red
  ];

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
    // if (courses.isEmpty) return const SizedBox.shrink();

    // return Container(
    //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    //   padding: const EdgeInsets.all(16),
    //   decoration: BoxDecoration(
    //     color: Colors.white,
    //     borderRadius: BorderRadius.circular(16),
    //     boxShadow: [
    //       BoxShadow(
    //         color: Colors.black.withValues(alpha: 0.05),
    //         blurRadius: 8,
    //         offset: const Offset(0, 2),
    //       ),
    //     ],
    //   ),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Text(
    //         'المواد الدراسية',
    //         style: GoogleFonts.alexandria(
    //           fontSize: 16,
    //           fontWeight: FontWeight.bold,
    //           color: const Color(0xFF333333),
    //         ),
    //       ),
    //       const SizedBox(height: 14),
    //       SizedBox(
    //         height: 155,
    //         child: ListView.separated(
    //           scrollDirection: Axis.horizontal,
    //           itemCount: courses.length,
    //           separatorBuilder: (_, _) => const SizedBox(width: 12),
    //           itemBuilder: (context, index) {
    //             return _buildCourseCard(context, courses[index], index);
    //           },
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  Widget _buildCourseCard(BuildContext context, Course course, int index) {
    final borderColor = _getCardColor(course, index);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CourseDetailsPage(course: course),
          ),
        );
      },
      child: SizedBox(
        width: 110,
        child: Column(
          children: [
            // Image card with colored border
            Container(
              width: 110,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: course.image != null && course.image!.isNotEmpty
                    ? Image.network(
                        course.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _buildPlaceholder(borderColor),
                      )
                    : _buildPlaceholder(borderColor),
              ),
            ),
            const SizedBox(height: 6),
            // Course name
            Text(
              course.displayName,
              textAlign: TextAlign.center,
              style: GoogleFonts.alexandria(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardColor(Course course, int index) {
    // Use course color from API if available
    if (course.color != null) {
      try {
        final hex = course.color!.code.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    // Fallback to predefined colors cycling
    return _cardBorderColors[index % _cardBorderColors.length];
  }

  Widget _buildPlaceholder(Color color) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(child: Icon(Icons.menu_book, size: 36, color: color)),
    );
  }
}

// ─── Live Sessions Section ───────────────────────────────────

class LiveSessionsSection extends StatelessWidget {
  final List<LiveSession> sessions;

  const LiveSessionsSection({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.videocam, color: Color(0xFFE91E63), size: 22),
              const SizedBox(width: 8),
              Text(
                'حصص مباشرة اليوم',
                style: GoogleFonts.alexandria(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            _buildEmptyState()
          else
            ...sessions.map((session) => _buildSessionCard(context, session)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'لا توجد حصص مباشرة اليوم',
              style: GoogleFonts.alexandria(
                fontSize: 14,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, LiveSession session) {
    final isLive = session.isLive;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFFFF0F3) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: isLive
            ? Border.all(color: const Color(0xFFE91E63).withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.displayName,
                  style: GoogleFonts.alexandria(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'مباشر الان',
                    style: GoogleFonts.alexandria(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            session.displayCourseName,
            style: GoogleFonts.alexandria(
              fontSize: 13,
              color: const Color(0xFF757575),
            ),
          ),
          if (session.meetingLink != null &&
              session.meetingLink!.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openMeetingLink(session.meetingLink!),
                icon: const Icon(Icons.groups, size: 18),
                label: Text(
                  'الانضمام عبر Teams',
                  style: GoogleFonts.alexandria(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF464EB8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openMeetingLink(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

// ─── Recommended Videos Section ──────────────────────────────

class RecommendedVideosSection extends StatelessWidget {
  final List<RecommendedVideo> videos;

  const RecommendedVideosSection({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فيديوهات مقترحه لك',
            style: GoogleFonts.alexandria(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          ...videos.map((video) => _buildVideoItem(context, video)),
        ],
      ),
    );
  }

  Widget _buildVideoItem(BuildContext context, RecommendedVideo video) {
    return GestureDetector(
      onTap: () {
        if (video.videoUrl.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                videoUrl: video.videoUrl,
                title: video.displayName,
                lessonId: video.lessonId,
                courseId: video.courseId,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: video.displayImage.isNotEmpty
                    ? Image.network(
                        video.displayImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.grey,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.displayName,
                    style: GoogleFonts.alexandria(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.displayCourseName,
                    style: GoogleFonts.alexandria(
                      fontSize: 12,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Today Tasks Section ─────────────────────────────────────

class TodayTasksSection extends StatefulWidget {
  final List<Task> tasks;
  final int incompleteCount;
  final VoidCallback? onTaskCompleted;

  const TodayTasksSection({
    super.key,
    required this.tasks,
    required this.incompleteCount,
    this.onTaskCompleted,
  });

  @override
  State<TodayTasksSection> createState() => _TodayTasksSectionState();
}

class _TodayTasksSectionState extends State<TodayTasksSection> {
  static const String _userId = 'c5061673-5b5f-4e5e-ab78-d9f51eef3dd2';
  final CoursesService _coursesService = CoursesService();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'مهام اليوم',
                  style: GoogleFonts.alexandria(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              if (widget.incompleteCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.incompleteCount} متبقية',
                    style: GoogleFonts.alexandria(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'لا توجد مهام اليوم',
                  style: GoogleFonts.alexandria(
                    fontSize: 14,
                    color: const Color(0xFF757575),
                  ),
                ),
              ),
            )
          else
            ...widget.tasks.map((task) => _buildTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final isCompleted = task.isCompleted == true || task.isOpened;
    final dueDate = _formatDueDate(task.dueDate);
    final typeName = task.referenceTypeNameAr ?? task.typeName;

    return GestureDetector(
      onTap: () => _handleTaskTap(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCompleted
              ? const Color(0xFFF5F5F5)
              : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: !isCompleted
              ? Border.all(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Row(
          children: [
            // Completion indicator
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFF4CAF50) : Colors.white,
                border: !isCompleted
                    ? Border.all(color: const Color(0xFFBDBDBD), width: 2)
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: task.typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeName,
                          style: GoogleFonts.alexandria(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: task.typeColor,
                          ),
                        ),
                      ),
                      if (dueDate.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          dueDate,
                          style: GoogleFonts.alexandria(
                            fontSize: 11,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.displayName.isNotEmpty
                        ? task.displayName
                        : task.taskName,
                    style: GoogleFonts.alexandria(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCompleted
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF333333),
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_left, color: Color(0xFFBDBDBD), size: 22),
          ],
        ),
      ),
    );
  }

  void _handleTaskTap(Task task) {
    switch (task.referenceType) {
      case 3: // Learning Object (شرح)
        _navigateToLearningObject(task);
        break;
      case 1: // Quiz (اختبار)
      case 2:
        _navigateToQuiz(task);
        break;
      case 5: // Discussion (نقاش)
        _navigateToDiscussion(task);
        break;
      default:
        debugPrint('Unknown task type: ${task.referenceType}');
    }
  }

  void _navigateToLearningObject(Task task) async {
    final videoUrl = task.taskDetailsLO?.content;
    final lessonId = task.taskDetailsLO?.lessonId;

    if (videoUrl == null || videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد رابط للفيديو',
            style: GoogleFonts.alexandria(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showMark(task);

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoUrl: videoUrl,
          title: task.displayName,
          lessonId: lessonId,
          courseId: task.courseId,
          enrollmentId: null,
          isFromTask: true,
        ),
      ),
    );

    widget.onTaskCompleted?.call();
  }

  void _navigateToQuiz(Task task) async {
    final quizUrl = task.taskDetailsQuiz?.url;
    final quizId = task.taskDetailsQuiz?.id;

    if (quizUrl == null || quizUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد رابط للاختبار',
            style: GoogleFonts.alexandria(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ExternalQuizScreen(
          url: quizUrl,
          courseId: task.courseId,
          plusExternalQuizId: quizId ?? task.referenceId,
          userToken: CoursesService.staticToken,
          userId: _userId,
        ),
      ),
    );

    if (result == true) {
      _showMark(task);
    }

    widget.onTaskCompleted?.call();
  }

  void _navigateToDiscussion(Task task) async {
    final postId = task.taskDetailsDiscussion?.id;
    if (postId == null) return;

    _showMark(task);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SinglePostSheet(
        postId: postId,
        currentUserName: 'المستخدم',
        currentUserImage: null,
        currentUserId: _userId,
        onClose: null,
        onPostDeleted: widget.onTaskCompleted,
      ),
    );

    widget.onTaskCompleted?.call();
  }

  Future<void> _showMark(Task task) async {
    try {
      await _coursesService.showMark(
        userId: _userId,
        taskId: task.taskId,
        dueDate: task.dueDate,
      );
    } catch (e) {
      debugPrint('showMark error: $e');
    }
  }

  String _formatDueDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final days = [
      'الاحد',
      'الاثنين',
      'الثلاثاء',
      'الاربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    final dayName = days[date.weekday % 7];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'م' : 'ص';
    return '$dayName، ${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }
}
