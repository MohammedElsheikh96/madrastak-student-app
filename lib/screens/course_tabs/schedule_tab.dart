import 'package:flutter/material.dart';
import '../../models/course.dart';

class ScheduleTab extends StatefulWidget {
  final Course course;

  const ScheduleTab({super.key, required this.course});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  DateTime _selectedDate = DateTime.now();
  int _selectedDayIndex = 2; // Default to today

  final List<Map<String, dynamic>> _weekDays = [];

  // Mock schedule items
  final List<Map<String, dynamic>> _scheduleItems = [
    {
      'teacher': 'أ / أحمد عادل',
      'title': 'نص "من أجل مصر" (حافظ إبراهيم)',
      'date': '30 نوفمبر',
      'time': '04:30 م',
      'image': 'https://via.placeholder.com/50',
    },
    {
      'teacher': 'أ / أحمد عادل',
      'title': 'قيمة الوقت في حياة الإنسان',
      'date': '30 نوفمبر',
      'time': '04:30 م',
      'image': 'https://via.placeholder.com/50',
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
  }

  void _generateWeekDays() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 6));

    final dayNames = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      _weekDays.add({
        'name': dayNames[i],
        'day': date.day,
        'date': date,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          // Calendar header
          _buildCalendarHeader(),
          // Week days
          _buildWeekDays(),
          // Schedule list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _scheduleItems.length,
              itemBuilder: (context, index) {
                return _buildScheduleCard(_scheduleItems[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              // Previous month
            },
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Color(0xFF0F6EB7),
              ),
            ),
          ),
          Text(
            'سبتمبر 2022',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          IconButton(
            onPressed: () {
              // Next month
            },
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Color(0xFF0F6EB7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_weekDays.length, (index) {
          final day = _weekDays[index];
          final isSelected = index == _selectedDayIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
                _selectedDate = day['date'];
              });
            },
            child: Column(
              children: [
                Text(
                  day['name'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? const Color(0xFF0F6EB7)
                        : const Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0F6EB7)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${day['day']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Teacher image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 50,
              color: Colors.grey.shade200,
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['teacher'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Color(0xFF757575),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['date'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Color(0xFF757575),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['time'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
