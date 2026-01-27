import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/study_materials_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1; // Default to home (center)

  final List<Widget> _tabs = const [
    StudyMaterialsTab(),
    HomeTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _tabs[_currentIndex],
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomBottomNav() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final navBarHeight = 65.0 + bottomPadding;

    return SizedBox(
      height: navBarHeight + 35,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // White curved navbar with rounded edges
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(screenWidth, navBarHeight),
              painter: _RoundedNavBarPainter(bottomPadding: bottomPadding),
            ),
          ),
          // Navigation items
          Positioned(
            bottom: bottomPadding + 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left item - المواد (Study Materials) - RTL layout
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book,
                    label: 'المواد',
                    index: 0,
                  ),
                ),
                // Center space for logo
                const SizedBox(width: 90),
                // Right item - الحساب (Profile) - RTL layout
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'الحساب',
                    index: 2,
                  ),
                ),
              ],
            ),
          ),
          // Center logo button (elevated)
          Positioned(
            bottom: navBarHeight - 55,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: SvgPicture.asset(
                      'assets/images/logo-blank.svg',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      placeholderBuilder: (context) => _buildFallbackLogo(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.home, color: Color(0xFF0F6EB7), size: 26),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? const Color(0xFF0F6EB7)
        : const Color(0xFFBDBDBD);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the rounded navigation bar with curved edges
class _RoundedNavBarPainter extends CustomPainter {
  final double bottomPadding;

  _RoundedNavBarPainter({required this.bottomPadding});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    const double cornerRadius = 25.0;
    const double notchRadius = 40.0;
    final double notchCenterX = size.width / 2;
    const double notchDepth = 8.0;

    // Start from bottom-left
    path.moveTo(0, size.height);

    // Left edge - go up to the rounded corner
    path.lineTo(0, cornerRadius);

    // Top-left rounded corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Top edge to the notch
    path.lineTo(notchCenterX - notchRadius, 0);

    // Notch curve (smooth curve going down to accommodate the logo)
    path.quadraticBezierTo(
      notchCenterX - notchRadius + 12,
      0,
      notchCenterX - 28,
      notchDepth,
    );
    path.quadraticBezierTo(
      notchCenterX,
      notchDepth + 28,
      notchCenterX + 28,
      notchDepth,
    );
    path.quadraticBezierTo(
      notchCenterX + notchRadius - 12,
      0,
      notchCenterX + notchRadius,
      0,
    );

    // Continue top edge to top-right corner
    path.lineTo(size.width - cornerRadius, 0);

    // Top-right rounded corner
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Right edge - go down
    path.lineTo(size.width, size.height);

    // Bottom edge
    path.lineTo(0, size.height);

    path.close();

    // Draw shadow first
    final shadowPath = path.shift(const Offset(0, -2));
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw the white fill
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
