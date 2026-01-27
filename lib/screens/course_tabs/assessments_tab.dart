import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/grade_book_result.dart';
import '../../services/grading_service.dart';

class AssessmentsTab extends StatefulWidget {
  final Course course;

  const AssessmentsTab({super.key, required this.course});

  @override
  State<AssessmentsTab> createState() => _AssessmentsTabState();
}

class _AssessmentsTabState extends State<AssessmentsTab>
    with TickerProviderStateMixin {
  final GradingService _gradingService = GradingService();
  final Map<int, bool> _expandedCategories = {};

  GradeBookResult? _gradeBookResult;
  bool _isLoading = true;
  String? _error;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadGradeBook();
  }

  void _initAnimations() {
    // Pulse animation for circle background
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scale animation for "قريبا" text
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Dots animation controller
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _loadGradeBook() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _gradingService.getGradeBookResult(
        widget.course.id.toString(),
      );
      setState(() {
        _gradeBookResult = result;
        _isLoading = false;
        // Initialize all categories as expanded
        if (result != null) {
          for (int i = 0; i < result.categoryResults.length; i++) {
            _expandedCategories[i] = true;
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل التقييمات';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFF5F5F5), child: _buildContent());
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
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGradeBook,
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

    if (_gradeBookResult == null || _gradeBookResult!.categoryResults.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadGradeBook,
      color: const Color(0xFF0F6EB7),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _gradeBookResult!.categoryResults.length,
        itemBuilder: (context, index) {
          return _buildCategorySection(
            _gradeBookResult!.categoryResults[index],
            index,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "قريبا" text with decorative styling and animation
            Stack(
              alignment: Alignment.center,
              children: [
                // Light circle background with pulse animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                // "قريبا" text with scale animation
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: const Text(
                        'قريبا',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE74C3C),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'التقييمات قادمة قريبا',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F6EB7),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'نعمل على تجهيز نظام التقييمات\nالخاص بك، ترقب التحديثات!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Animated dots indicator
            _buildAnimatedDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnimatedDot(0),
            const SizedBox(width: 8),
            _buildAnimatedDot(1),
            const SizedBox(width: 8),
            _buildAnimatedDot(2),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedDot(int index) {
    // Calculate which dot should be active based on animation progress
    final progress = _dotsController.value;
    final activeDotIndex = (progress * 3).floor() % 3;
    final isActive = index == activeDotIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 12 : 8,
      height: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0F6EB7) : const Color(0xFFD0D0D0),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCategorySection(CategoryResult category, int categoryIndex) {
    final isExpanded = _expandedCategories[categoryIndex] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header with collapse arrow
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedCategories[categoryIndex] = !isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Arrow icon on the left
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF0F6EB7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                // Category title
                Expanded(
                  child: Text(
                    category.categoryName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F6EB7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Assignment items (collapsible)
        AnimatedCrossFade(
          firstChild: Column(
            children: category.assignments
                .map((assignment) => _buildAssignmentCard(assignment))
                .toList(),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0F6EB7), width: 1),
      ),
      child: Row(
        children: [
          // Content on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.assignmentName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'اختبر نفسك',
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Icon with blue background
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F6EB7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              // Score
              Text(
                'درجة الاختبار: ${assignment.scorePercentage.toInt()} %',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
