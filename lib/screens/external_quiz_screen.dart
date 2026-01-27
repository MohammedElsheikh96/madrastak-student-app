import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ExternalQuizScreen extends StatefulWidget {
  final String url;
  final int courseId;
  final String plusExternalQuizId;
  final String? userToken;
  final String? userId;

  const ExternalQuizScreen({
    super.key,
    required this.url,
    required this.courseId,
    required this.plusExternalQuizId,
    this.userToken,
    this.userId,
  });

  @override
  State<ExternalQuizScreen> createState() => _ExternalQuizScreenState();
}

class _ExternalQuizScreenState extends State<ExternalQuizScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Build the full URL with parameters
    final fullUrl = _buildQuizUrl();
    debugPrint('ExternalQuizScreen: Loading URL: $fullUrl');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('ExternalQuizScreen: Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            debugPrint('ExternalQuizScreen: Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'ExternalQuizScreen: Web resource error: ${error.description}',
            );
            setState(() {
              _error = error.description;
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint(
              'ExternalQuizScreen: Navigation request: ${request.url}',
            );

            // Check if the URL indicates quiz submission/completion
            if (_isQuizCompleted(request.url)) {
              debugPrint('ExternalQuizScreen: Quiz completed, closing screen');
              Navigator.of(
                context,
              ).pop(true); // Return true to indicate completion
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint(
            'ExternalQuizScreen: JS message received: ${message.message}',
          );

          // Handle messages from the quiz page
          if (message.message == 'quizCompleted' ||
              message.message == 'quizSubmitted' ||
              message.message == 'close') {
            Navigator.of(context).pop(true);
          }
        },
      )
      ..loadRequest(Uri.parse(fullUrl));
  }

  String _buildQuizUrl() {
    String url = widget.url;

    // Add parameters to URL
    final separator = url.contains('?') ? '&' : '?';
    final params = <String>[];

    if (widget.userToken != null) {
      params.add('token=${widget.userToken}');
    }
    if (widget.userId != null) {
      params.add('userId=${widget.userId}');
    }
    params.add('source=flutter');
    params.add('plusExternalQuizId=${widget.plusExternalQuizId}');

    if (params.isNotEmpty) {
      url = '$url$separator${params.join('&')}';
    }

    return url;
  }

  bool _isQuizCompleted(String url) {
    // Check for common quiz completion URL patterns
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('complete') ||
        lowerUrl.contains('submitted') ||
        lowerUrl.contains('finished') ||
        lowerUrl.contains('success') ||
        lowerUrl.contains('done');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => _showExitConfirmation(),
          ),
          title: Text(
            'الاختبار',
            style: GoogleFonts.alexandria(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          bottom: true,
          child: Stack(
            children: [
              if (_error != null)
                _buildErrorView()
              else
                WebViewWidget(controller: _controller),

              if (_isLoading)
                Container(
                  color: Colors.white,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء تحميل الاختبار',
              style: GoogleFonts.alexandria(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'خطأ غير معروف',
              style: GoogleFonts.alexandria(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _controller.reload();
              },
              icon: const Icon(Icons.refresh),
              label: Text('إعادة المحاولة', style: GoogleFonts.alexandria()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6EB7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExitConfirmation() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'إغلاق الاختبار',
            style: GoogleFonts.alexandria(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'هل أنت متأكد من إغلاق الاختبار؟',
            style: GoogleFonts.alexandria(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'إلغاء',
                style: GoogleFonts.alexandria(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'إغلاق',
                style: GoogleFonts.alexandria(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.of(
        context,
      ).pop(false); // Return false to indicate not completed
    }
  }
}
