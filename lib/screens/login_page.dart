import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../widgets/info_dialog.dart';
import '../services/azure_ad_service.dart';
import '../config/azure_ad_config.dart';
import '../models/api_exception.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final bool? countryRestricted;

  const LoginPage({super.key, this.countryRestricted});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AzureADService _azureADService = AzureADService();
  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void initState() {
    super.initState();
    // Show country restriction message if redirected with that flag
    if (widget.countryRestricted == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(
          'نعتذر، بلدك غير مدعوم الآن. سيتم الإتاحة قريبًا',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Header with gradient - curved shape
              _buildHeader(),

              // Content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Ministry Logo
                    Image.asset(
                      'assets/images/ministry_logo.png',
                      width: 130,
                      height: 130,
                    ),

                    const SizedBox(height: 20),

                    // Login Title
                    const Text(
                      'تسجيل دخول',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),

                    const SizedBox(height: 64),

                    // Microsoft Login Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _buildMicrosoftButton(context),
                    ),

                    const SizedBox(height: 16),

                    // How to Login Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _buildHowToLoginButton(context),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF1976D2),
              ),
              const SizedBox(height: 16),
              Text(
                _loadingMessage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      height: 330,
      child: Stack(
        children: [
          // Background curved shape with gradient
          ClipPath(
            clipper: HeaderClipper(),
            child: Container(
              width: double.infinity,
              height: 330,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Color(0xFF0F6EB7), // Blue
                    Color(0xFF0F6EB7), // Blue
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          // Content (Logo and Text)
          SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 120,
                    height: 130,
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrosoftButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithMicrosoft,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Microsoft Logo
            SvgPicture.asset(
              'assets/images/microsoft-icon.svg',
              width: 18,
              height: 18,
            ),
            const SizedBox(width: 12),
            const Text(
              'تسجيل الدخول بحساب Microsoft',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading
            ? null
            : () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black54,
                  builder: (context) => const InfoDialog(),
                );
              },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circle with ! icon
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBDBDBD), width: 2),
              ),
              child: const Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'كيفية تسجيل الدخول',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sign in with Microsoft Azure AD
  Future<void> _signInWithMicrosoft() async {
    // TODO: Uncomment this when Azure AD portal is configured
    // try {
    //   setState(() {
    //     _isLoading = true;
    //     _loadingMessage = 'جاري المعالجة...';
    //   });

    //   // Build the authorization URL
    //   final authUrl = _azureADService.buildAuthorizationUrl();

    //   // Use flutter_web_auth_2 to handle the OAuth flow
    //   final result = await FlutterWebAuth2.authenticate(
    //     url: authUrl,
    //     callbackUrlScheme: AzureADConfig.callbackUrlScheme,
    //   );

    //   // Handle the callback result
    //   await _handleAzureCallback(result);
    // } catch (e) {
    //   _handleError(e);
    // }

    // Temporary: Navigate directly to home page
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  /// Handle the Azure AD callback
  Future<void> _handleAzureCallback(String callbackUrl) async {
    try {
      setState(() {
        _loadingMessage = 'جاري التحقق من الهوية...';
      });

      // Handle callback - sends tokens to backend and gets AzureADLoginResponse
      final loginResponse = await _azureADService.handleCallback(callbackUrl);

      // Store authentication data
      await _azureADService.storeAuthData(loginResponse);

      setState(() {
        _loadingMessage = 'تم تسجيل الدخول بنجاح';
      });

      // Small delay to show success message
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to home page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      _handleError(e);
    }
  }

  /// Handle errors from Azure AD authentication
  void _handleError(dynamic error) {
    setState(() {
      _isLoading = false;
      _loadingMessage = '';
    });

    if (error is ApiException) {
      if (error.success == false && error.statusCode == '403') {
        // Country is restricted
        _showErrorSnackBar(
          'نعتذر، بلدك غير مدعوم الآن. سيتم الإتاحة قريبًا',
        );
        return;
      }
      _showErrorSnackBar(error.message);
    } else {
      // Check if user cancelled the authentication
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('cancelled') ||
          errorString.contains('canceled') ||
          errorString.contains('user_cancel')) {
        // User cancelled - no error message needed
        return;
      }

      _showErrorSnackBar('حدث خطأ أثناء تسجيل الدخول. يرجى المحاولة مرة أخرى.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}

// Custom clipper to create the curved header shape matching Figma
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start from top-left
    path.moveTo(0, 0);

    // Line to top-right
    path.lineTo(size.width, 0);

    // Line down the right side with curve
    path.lineTo(size.width, size.height * 0.65);

    // Create the curved bottom edge (matching the Figma blob shape)
    path.quadraticBezierTo(
      size.width * 0.75, // control point x
      size.height * 1.05, // control point y
      size.width * 0.5, // end point x
      size.height * 0.85, // end point y
    );

    path.quadraticBezierTo(
      size.width * 0.25, // control point x
      size.height * 0.65, // control point y
      0, // end point x
      size.height * 0.85, // end point y
    );

    // Close path back to start
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
