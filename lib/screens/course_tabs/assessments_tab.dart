import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/course.dart';

class AssessmentsTab extends StatefulWidget {
  final Course course;

  const AssessmentsTab({super.key, required this.course});

  @override
  State<AssessmentsTab> createState() => _AssessmentsTabState();
}

class _AssessmentsTabState extends State<AssessmentsTab> {
  static const String _baseUrl = 'https://mfm-student.madrasetna.net/api';
  static const String _studentId = 'c5061673-5b5f-4e5e-ab78-d9f51eef3dd2';
  static const String _token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjJiODVmZTk2LTU3ZjgtNDBiNi05NjAxLTMyYTA3Mjg4NmUxMSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvdXNlcmRhdGEiOiJjNTA2MTY3My01YjVmLTRlNWUtYWI3OC1kOWY1MWVlZjNkZDIiLCJuYW1lIjoi2LnYqNiv2KfZhNmH2KfYr9mJINmF2K3ZhdivINi52KjYr9in2YTZh9in2K_ZiSDYudmE2Ykg2KfZhNi02YrZiNmJIiwiZW1haWwiOiIxNDU0MUBzYWJyb2FkLm1vZS5lZHUuZWciLCJwaG9uZV9udW1iZXIiOiIiLCJwcm9maWxlX3BpY3R1cmVfdXJsIjoiIiwic3RhZ2VfbmFtZSI6Itin2YTYqti52YTZitmFINin2YTYp9i52K_Yp9iv2YogIiwiZ3JhZGVfbmFtZSI6Itin2YTYtdmBINin2YTYq9in2YbZiiDYp9mE2KfYudiv2KfYr9mKIiwiY291bnRyeV9uYW1lIjoi2KXZiti32KfZhNmK2KciLCJuYmYiOjE3NzIzNzE0NjksImV4cCI6MTc3MjcxNzA2OSwiaWF0IjoxNzcyMzcxNDY5fQ.1MdmPe2r0kAiYluc9l1aZ1SIXjbHbUoruji4q89nqzM';

  List<Map<String, dynamic>> _categories = [];
  double _totalPercentage = 0.0;
  bool _isLoading = true;
  String? _error;
  final Map<int, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _fetchGradeBook();
  }

  Future<void> _fetchGradeBook() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final httpClient = HttpClient()..badCertificateCallback = (_, _, _) => true;
    final client = IOClient(httpClient);

    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/Grading/getGradeBookResult'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode([
          {'studentId': _studentId, 'courseId': widget.course.id},
        ]),
      );

      debugPrint('=== GRADING RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['status'] == true && data['returnObject'] != null) {
          final returnObject = data['returnObject'] as List;
          if (returnObject.isNotEmpty) {
            final result = returnObject[0]['result'] as Map<String, dynamic>?;
            if (result != null) {
              setState(() {
                _categories = (result['categoryResults'] as List)
                    .cast<Map<String, dynamic>>();
                _totalPercentage =
                    (result['totalPercentage'] as num?)?.toDouble() ?? 0.0;
                _isLoading = false;
                for (int i = 0; i < _categories.length; i++) {
                  _expandedCategories[i] = true;
                }
              });
              return;
            }
          }
        }
      }

      setState(() {
        _categories = [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Grading error: $e');
      setState(() {
        _error = 'حدث خطأ في تحميل التقييمات';
        _isLoading = false;
      });
    } finally {
      client.close();
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
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF757575)),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchGradeBook,
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

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد تقييمات حاليا',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم عرض التقييمات عند توفرها',
              style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _fetchGradeBook,
              icon: const Icon(Icons.refresh, color: Color(0xFF0F6EB7)),
              label: const Text(
                'تحديث',
                style: TextStyle(color: Color(0xFF0F6EB7)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchGradeBook,
      color: const Color(0xFF0F6EB7),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total percentage card
          _buildTotalCard(),
          const SizedBox(height: 16),
          // Category sections
          for (int i = 0; i < _categories.length; i++) ...[
            _buildCategorySection(_categories[i], i),
            if (i < _categories.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6EB7), Color(0xFF1E88E5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المجموع الكلي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_totalPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _totalPercentage / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                // ${_totalPercentage.toInt()}%
                Text(
                  '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category, int index) {
    final isExpanded = _expandedCategories[index] ?? true;
    final categoryName = category['categoryName'] as String? ?? '';
    final weight = (category['weight'] as num?)?.toDouble() ?? 0.0;
    final percentageScore =
        (category['percentageScore'] as num?)?.toDouble() ?? 0.0;
    final assignments = (category['assignments'] as List?) ?? [];

    return Container(
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
        children: [
          // Category header
          InkWell(
            onTap: () {
              setState(() {
                _expandedCategories[index] = !isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F6EB7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.category,
                      color: Color(0xFF0F6EB7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(
                        percentageScore,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${percentageScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(percentageScore),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF0F6EB7),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Assignments list
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                const Divider(height: 1),
                ...assignments.map(
                  (a) => _buildAssignmentItem(
                    a as Map<String, dynamic>,
                    assignments.indexOf(a) == assignments.length - 1,
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentItem(Map<String, dynamic> assignment, bool isLast) {
    final name = assignment['assignmentName'] as String? ?? '';
    final score = (assignment['scorePercentage'] as num?)?.toDouble() ?? 0.0;
    final isSubmitted = assignment['isSubmitted'] as bool? ?? false;
    final quizUrl = assignment['quizUrl'] as String?;

    return Column(
      children: [
        InkWell(
          onTap: quizUrl != null
              ? () => launchUrl(
                  Uri.parse(quizUrl),
                  mode: LaunchMode.externalApplication,
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSubmitted
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                        : const Color(0xFFFF9800).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSubmitted ? Icons.check_circle : Icons.pending,
                    color: isSubmitted
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                // Assignment name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      if (isSubmitted)
                        const Text(
                          'تم التسليم',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4CAF50),
                          ),
                        )
                      else
                        const Text(
                          'لم يتم التسليم',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                    ],
                  ),
                ),
                // Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${score.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(score),
                      ),
                    ),
                    if (quizUrl != null)
                      const Text(
                        'عرض الاختبار',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0F6EB7),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 60),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }
}
