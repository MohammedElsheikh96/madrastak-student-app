import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/course.dart';
import '../../models/task.dart';
import '../../services/courses_service.dart';
import '../../widgets/post_card.dart';
import '../external_quiz_screen.dart';
import '../video_player_screen.dart';

class TasksTab extends StatefulWidget {
  final Course course;

  const TasksTab({super.key, required this.course});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final CoursesService _coursesService = CoursesService();

  // TODO: Get actual userId from auth service
  static const String _userId = 'c5061673-5b5f-4e5e-ab78-d9f51eef3dd2';

  bool _isLoading = true;
  String? _error;
  TasksByDayResponse? _tasksResponse;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _coursesService.getTasksByDay(
        _userId,
        widget.course.id,
      );

      if (response != null && response.status) {
        setState(() {
          _tasksResponse = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'فشل في تحميل المهام';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل المهام';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          // Tasks header
          _buildTasksHeader(),
          // Tasks content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.alexandria(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasks,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6EB7),
              ),
              child: Text(
                'إعادة المحاولة',
                style: GoogleFonts.alexandria(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final tasks = _tasksResponse?.allTasks ?? [];

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'لا توجد مهام لليوم',
              style: GoogleFonts.alexandria(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      color: const Color(0xFF0F6EB7),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length + 1, // +1 for bottom padding
        itemBuilder: (context, index) {
          if (index == tasks.length) {
            return const SizedBox(height: 80); // Safe area padding
          }
          return _buildTaskCard(tasks[index]);
        },
      ),
    );
  }

  Widget _buildTasksHeader() {
    final incompleteCount = _tasksResponse?.incompleteCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title on right (RTL: appears on left)
          Text(
            'مهام اليوم',
            style: GoogleFonts.alexandria(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          // Incomplete count on left (RTL: appears on right)
          Text(
            'غير مكتملة ($incompleteCount)',
            style: GoogleFonts.alexandria(
              fontSize: 14,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final typeColor = task.typeColor;
    final isCompleted = task.isOpened;

    return GestureDetector(
      onTap: () => _handleTaskTap(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: typeColor, width: 1.5),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored border strip on left
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
              // Main content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Row 1: Lesson name + checkmark (right) + Type badge (left)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Lesson/Course name with checkmark (right side)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Green checkmark for completed tasks
                                  if (isCompleted) ...[
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      task.displaySubtitle,
                                      style: GoogleFonts.alexandria(
                                        fontSize: 12,
                                        color: const Color(0xFF757575),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Type badge with icon (left side)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(task.typeIcon, size: 14, color: typeColor),
                                const SizedBox(width: 4),
                                Text(
                                  task.typeName,
                                  style: GoogleFonts.alexandria(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Row 2: Image (left) + Task name (right)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Task image with play icon for type 3
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 100,
                                  height: 75,
                                  color: Colors.grey.shade200,
                                  child:
                                      task.imageUrl != null &&
                                          task.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          task.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Center(
                                                  child: Icon(
                                                    task.typeIcon,
                                                    color: typeColor,
                                                    size: 28,
                                                  ),
                                                );
                                              },
                                        )
                                      : Center(
                                          child: Icon(
                                            task.typeIcon,
                                            color: typeColor,
                                            size: 28,
                                          ),
                                        ),
                                ),
                              ),
                              // Play icon overlay for referenceType 3 (شرح/عنصر تعليمي)
                              if (task.referenceType == 3)
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Task name/title (RTL aligned)
                          Expanded(
                            child: Text(
                              task.displayName,
                              style: GoogleFonts.alexandria(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF333333),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                      // Row 3: Hashtags if available
                      if (task.tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          children: task.tags.take(4).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '#$tag',
                                style: GoogleFonts.alexandria(
                                  fontSize: 11,
                                  color: const Color(0xFF4CAF50),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTaskTap(Task task) {
    debugPrint(
      'Task tapped: ${task.taskId}, referenceType: ${task.referenceType}',
    );

    switch (task.referenceType) {
      case 3: // Learning Object (شرح)
        // Navigate to LO player/content
        _navigateToLearningObject(task);
        break;
      case 1: // Quiz (اختبار)
      case 2:
        // Navigate to quiz
        _navigateToQuiz(task);
        break;
      case 5: // Discussion (نقاش)
        // Navigate to discussion/post
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
      debugPrint('Navigate to LO: No video URL found');
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

    debugPrint('Navigate to LO: ${task.referenceId}, URL: $videoUrl');

    // Call showMark API to mark task as completed
    _showMark(task);

    // Navigate to video player screen
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoUrl: videoUrl,
          title: task.displayName,
          lessonId: lessonId,
          courseId: task.courseId,
          enrollmentId: null, // TODO: Get from enrollment data
          isFromTask: true,
        ),
      ),
    );

    // Refresh tasks list after returning from video
    _loadTasks();
  }

  void _navigateToQuiz(Task task) async {
    final quizUrl = task.taskDetailsQuiz?.url;
    final quizId = task.taskDetailsQuiz?.id;

    if (quizUrl == null || quizUrl.isEmpty) {
      debugPrint('Navigate to Quiz: No URL found');
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

    debugPrint('Navigate to Quiz: ${task.referenceId}, URL: $quizUrl');

    // Navigate to external quiz screen
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ExternalQuizScreen(
          url: quizUrl,
          courseId: widget.course.id,
          plusExternalQuizId: quizId ?? task.referenceId,
          userToken: CoursesService.staticToken,
          userId: _userId,
        ),
      ),
    );

    // If quiz was completed/submitted, call showMark and refresh tasks
    if (result == true) {
      _showMark(task);
    }

    // Refresh tasks list after returning from quiz
    _loadTasks();
  }

  void _navigateToDiscussion(Task task) async {
    final postId = task.taskDetailsDiscussion?.id;
    if (postId == null) {
      debugPrint('Navigate to Discussion: No postId found');
      return;
    }

    debugPrint('Navigate to Discussion: postId=$postId');

    // Call showMark API to mark task as completed
    _showMark(task);

    // Open SinglePostSheet with the discussion post
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SinglePostSheet(
        postId: postId,
        currentUserName: 'المستخدم', // TODO: Get from auth service
        currentUserImage: null,
        onClose: null,
      ),
    );

    // Refresh tasks after closing to update completion status
    _loadTasks();
  }

  Future<void> _showMark(Task task) async {
    try {
      await _coursesService.showMark(
        userId: _userId,
        taskId: task.taskId,
        dueDate: task.dueDate,
      );
      debugPrint('showMark called for taskId: ${task.taskId}');
    } catch (e) {
      debugPrint('showMark error: $e');
    }
  }
}
