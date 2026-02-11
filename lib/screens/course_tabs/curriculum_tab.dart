import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/course.dart';
import '../../models/curriculum.dart';
import '../../services/courses_service.dart';
import '../external_quiz_screen.dart';
import '../pdf_viewer_screen.dart';
import '../video_player_screen.dart';

class CurriculumTab extends StatefulWidget {
  final Course course;

  const CurriculumTab({super.key, required this.course});

  @override
  State<CurriculumTab> createState() => _CurriculumTabState();
}

class _CurriculumTabState extends State<CurriculumTab> {
  final CoursesService _coursesService = CoursesService();

  bool _isLoading = true;
  String? _error;
  CourseDetails? _courseDetails;
  ChaptersLessonsResponse? _chaptersData;

  // Track expanded chapters
  final Set<int> _expandedChapters = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load course details and chapters in parallel
      final results = await Future.wait([
        _coursesService.getCourseById(widget.course.id),
        _coursesService.getChaptersLessons(widget.course.id),
      ]);

      final courseDetails = results[0] as CourseDetails?;
      final chaptersData = results[1] as ChaptersLessonsResponse?;

      debugPrint(
        'CurriculumTab: courseDetails = ${courseDetails != null ? "loaded (percentage: ${courseDetails.percentage})" : "null"}',
      );
      debugPrint(
        'CurriculumTab: chaptersData = ${chaptersData != null ? "loaded (${chaptersData.chapters.length} chapters, ${chaptersData.quizzes.length} quizzes)" : "null"}',
      );

      if (mounted) {
        setState(() {
          _courseDetails = courseDetails;
          _chaptersData = chaptersData;
          _isLoading = false;
          // Expand first chapter by default
          if (chaptersData != null && chaptersData.chapters.isNotEmpty) {
            _expandedChapters.add(chaptersData.chapters.first.id);
            debugPrint(
              'CurriculumTab: Expanded first chapter ID: ${chaptersData.chapters.first.id}',
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في تحميل البيانات: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6EB7),
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

    // Check if we have no data
    if (_chaptersData == null || _chaptersData!.chapters.isEmpty) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا يوجد محتوى متاح حاليا',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Course ID: ${widget.course.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6EB7),
                      ),
                      child: const Text(
                        'إعادة المحاولة',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          // Progress header
          _buildProgressHeader(),
          // Chapters list
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                // Chapter accordions
                ..._chaptersData!.chapters.asMap().entries.map(
                  (entry) => _buildChapterAccordion(entry.value, entry.key),
                ),
                // Course-level quizzes section
                if (_chaptersData!.quizzes.isNotEmpty ||
                    _chaptersData!.internalQuizzes.isNotEmpty)
                  _buildCourseQuizzesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final percentage = _courseDetails?.percentage ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '$percentage% من المنهج اكتمل',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(3),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned(
                      right: 0,
                      child: Container(
                        width: constraints.maxWidth * (percentage / 100),
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F6EB7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterAccordion(Chapter chapter, int index) {
    final isExpanded = _expandedChapters.contains(chapter.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Chapter header (accordion button)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedChapters.remove(chapter.id);
                } else {
                  _expandedChapters.add(chapter.id);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: isExpanded
                    ? const Border(
                        right: BorderSide(color: Color(0xFF0F6EB7), width: 4),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Bookmark icon
                  Icon(
                    Icons.bookmark,
                    color: isExpanded
                        ? const Color(0xFF0F6EB7)
                        : const Color(0xFF757575),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  // Chapter name (RTL)
                  Expanded(
                    child: Text(
                      chapter.displayName,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isExpanded
                            ? const Color(0xFF0F6EB7)
                            : const Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Expand/collapse arrow
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF757575),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (isExpanded) ...[
            // Learning outcomes from lessons
            ...chapter.lessons.expand(
              (lesson) => lesson.lessonLOs.map((lo) => _buildContentCard(lo)),
            ),
            // Chapter quizzes
            ...chapter.quizzes.map((quiz) => _buildQuizCard(quiz, false)),
            // Chapter internal quizzes
            ...chapter.internalQuizzes.map(
              (quiz) => _buildQuizCard(quiz, true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentCard(LearningOutcome lo) {
    // Determine type label and color based on content
    String typeLabel = 'شرح';
    Color typeColor = const Color(0xFF9C27B0); // Purple for explanation
    IconData typeIcon = Icons.play_circle_fill;
    bool isLiveVideo = false;

    // Customize based on lo.type
    if (lo.type == 1) {
      // PDF type
      typeLabel = 'ملف PDF';
      typeColor = const Color(0xFFE53935); // Red for PDF
      typeIcon = Icons.picture_as_pdf;
    } else if (lo.type == 4) {
      // Video type
      typeLabel = 'شرح';
      typeColor = const Color(0xFF9C27B0);
      typeIcon = Icons.play_circle_fill;
    } else if (lo.type == 13) {
      // Live Video (Teams meeting)
      typeLabel = 'بث مباشر';
      typeColor = const Color(0xFF0078D4); // Microsoft Teams blue
      typeIcon = Icons.videocam;
      isLiveVideo = true;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: InkWell(
        onTap: () {
          _onContentTap(lo);
        },
        child: Row(
          children: [
            // Content image with progress overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: lo.imageAr!.isNotEmpty
                      ? Image.network(
                          lo.imageAr!,
                          width: 120,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(typeColor, typeIcon),
                        )
                      : _buildPlaceholderImage(typeColor, typeIcon),
                ),
                // Progress indicator overlay
                if (lo.lessonPercentage > 0 && !isLiveVideo)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerRight,
                        widthFactor: lo.lessonPercentage / 100,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Icon overlay for content (video, PDF, or live)
                if (lo.type == 4)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(typeIcon, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                // Live indicator badge
                if (isLiveVideo)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content title (RTL)
                  Text(
                    lo.displayName,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ],
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

  Widget _buildPlaceholderImage(Color color, IconData icon) {
    return Container(
      width: 120,
      height: 90,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }

  Widget _buildQuizCard(Quiz quiz, bool isInternal) {
    final Color quizColor = isInternal
        ? const Color(0xFF2196F3) // Blue for internal
        : const Color(0xFF4CAF50); // Green for external

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to quiz
          _onQuizTap(quiz, isInternal);
        },
        child: Row(
          children: [
            // Quiz image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  quiz.landscapeImage != null && quiz.landscapeImage!.isNotEmpty
                  ? Image.network(
                      quiz.landscapeImage!,
                      width: 120,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildQuizPlaceholder(quizColor),
                    )
                  : _buildQuizPlaceholder(quizColor),
            ),
            const SizedBox(width: 12),
            // Quiz details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiz name (RTL)
                  Text(
                    quiz.quizName,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Type badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Result badge if available
                      if (quiz.result != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: quiz.result! >= quiz.passingPercentage
                                ? const Color(
                                    0xFF4CAF50,
                                  ).withValues(alpha: 0.15)
                                : const Color(
                                    0xFFF44336,
                                  ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${quiz.result!.toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: quiz.result! >= quiz.passingPercentage
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFF44336),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: quizColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isInternal ? 'تدريب' : 'واجب',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: quizColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizPlaceholder(Color color) {
    return Container(
      width: 120,
      height: 90,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.quiz, color: color, size: 32),
    );
  }

  Widget _buildCourseQuizzesSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'الاختبارات',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          // Internal quizzes
          if (_chaptersData!.internalQuizzes.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: _chaptersData!.internalQuizzes
                    .map((quiz) => _buildQuizCard(quiz, true))
                    .toList(),
              ),
            ),
          if (_chaptersData!.internalQuizzes.isNotEmpty &&
              _chaptersData!.quizzes.isNotEmpty)
            const SizedBox(height: 12),
          // External quizzes
          if (_chaptersData!.quizzes.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: _chaptersData!.quizzes
                    .map((quiz) => _buildQuizCard(quiz, false))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _onContentTap(LearningOutcome lo) async {
    final content = lo.content;
    if (content == null || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد محتوى متاح'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if it's a Live Video (type == 13) - Teams meeting
    if (lo.type == 13) {
      // Open the Teams meeting link in external browser
      final Uri url = Uri.parse(content);
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لا يمكن فتح رابط البث المباشر'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
      return;
    }

    // Check if it's a PDF (type == 1)
    if (lo.type == 1) {
      // Determine PDF URL - if it's already a full URL, use it directly
      // Otherwise, get signed URL from AWS S3
      String pdfUrl;
      if (content.startsWith('http://') || content.startsWith('https://')) {
        // Already a full URL, use directly
        pdfUrl = content;
      } else {
        // It's an S3 key, get signed URL
        pdfUrl = _coursesService.getSignedPdfUrl(content);
      }

      // Navigate to PDF viewer screen
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfUrl: pdfUrl,
            title: lo.displayName,
            lessonId: lo.lessonId,
          ),
        ),
      );
    } else {
      // Navigate to video player screen (type == 4 or other video types)
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoUrl: content,
            title: lo.displayName,
            lessonId: lo.lessonId,
            courseId: lo.courseId,
            enrollmentId: null, // TODO: Get from enrollment data
            isFromTask: false,
          ),
        ),
      );
    }

    // Refresh curriculum data after returning
    _loadData();
  }

  void _onQuizTap(Quiz quiz, bool isInternal) async {
    final quizUrl = quiz.url;

    if (quizUrl == null || quizUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد رابط للاختبار'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to external quiz screen
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ExternalQuizScreen(
          url: quizUrl,
          courseId: widget.course.id,
          plusExternalQuizId: quiz.quizId,
          userToken: CoursesService.staticToken,
          userId:
              'c5061673-5b5f-4e5e-ab78-d9f51eef3dd2', // TODO: Get from auth service
        ),
      ),
    );

    // Refresh data after returning from quiz
    _loadData();
  }
}
