import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoDialog extends StatelessWidget {
  const InfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            _buildHeader(context),

            // Content with scroll
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLoginInstructions(),
                    const SizedBox(height: 20),
                    _buildPortalLink(),
                    const SizedBox(height: 16),
                    _buildImportantNotes(),
                    const SizedBox(height: 16),
                    _buildEmailSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF0F6EB7), // Blue
            Color(0xFF5746AE), // Purple middle
            Color(0xFF79246D), // Dark purple
          ],
          stops: [0.0, 0.4952, 1.0],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title and info icon on right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/info-circle.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'معلومات هامة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          // Close button (X) on left
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: SvgPicture.asset(
              'assets/images/close-circle.svg',
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header with icon
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(
              'assets/images/info-popup/login_icon.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1976D2),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'تعليمات تسجيل الدخول',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildBulletPoint(
          'يتم تسجيل الدخول باستخدام حساب OFFICE 365 المخصص لك من منصة أبناؤنا في الخارج.',
        ),
        _buildBulletPoint(
          'من فضلك أدخل البريد الإلكتروني التعليمي (365 OFFICE) وكلمة المرور.',
        ),
        _buildBulletPoint(
          'سيتم تحويلك تلقائياً إلى الصفحة الرئيسية بعد تسجيل الدخول بنجاح.',
        ),
        _buildBulletPoint(
          'في حالة وجود مشكلة في كلمة المرور، يرجى الرجوع إلى منصة أبناؤنا في الخارج أو التواصل مع الدعم عبر تيليجرام.',
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              '•',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalLink() {
    return InkWell(
      onTap: () => _launchUrl('https://sabroad.emis.gov.eg/'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/images/info-popup/external_link_icon.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1976D2),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'زيارة بوابة أبناؤنا في الخارج',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBulletPoint('تأكد من وجود اتصال جيد بالإنترنت قبل تسجيل الدخول.'),
        _buildBulletPoint(
          'يمكن استخدام الحساب من خلال جهاز واحد فقط في نفس الوقت.',
        ),
      ],
    );
  }

  Widget _buildEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(
              'assets/images/info-popup/sms_icon.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1976D2),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'كيف يمكنني الحصول على البريد الإلكتروني؟',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Content (always visible, no accordion)
        const Text(
          'يمكن للطالب الحصول على بريده الإلكتروني الرسمي من خلال بوابة أبناؤنا في الخارج، وذلك باستخدام حساب ولي الأمر المسجّل على البوابة.',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.6),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _launchUrl('https://sabroad.emis.gov.eg/'),
          child: const Text(
            'من خلال الرابط: HTTPS://SABROAD.EMIS.GOV.EG/',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1976D2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
