import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/courses_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int? lessonId;
  final int? courseId;
  final String? enrollmentId;
  final bool isFromTask;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    this.lessonId,
    this.courseId,
    this.enrollmentId,
    this.isFromTask = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  WebViewController? _webViewController;
  final CoursesService _coursesService = CoursesService();
  bool _isLoading = true;
  String? _error;
  double _currentTime = 0; // Current playback position in seconds
  double _duration = 0; // Total video duration in seconds
  bool _useWebView = false;

  @override
  void initState() {
    super.initState();
    // Set landscape orientation for video
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for immersive video experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_onVideoProgress);
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    // Reset orientation to portrait when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      debugPrint('VideoPlayerScreen: Initializing video: ${widget.videoUrl}');

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: {
          'Authorization': 'Bearer ${CoursesService.staticToken}',
          'Accept': '*/*',
        },
      );

      await _videoPlayerController!.initialize();

      _videoPlayerController!.addListener(_onVideoProgress);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ أثناء تحميل الفيديو',
                  style: GoogleFonts.alexandria(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: GoogleFonts.alexandria(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('VideoPlayerScreen: Native player failed, trying WebView: $e');
      // Fallback to WebView
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    setState(() {
      _useWebView = true;
    });

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('VideoPlayerScreen WebView error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterVideoProgress',
        onMessageReceived: (JavaScriptMessage message) {
          // Message format: "currentTime,duration"
          final parts = message.message.split(',');
          if (parts.length >= 2) {
            _currentTime = double.tryParse(parts[0]) ?? 0;
            _duration = double.tryParse(parts[1]) ?? 0;
          }
        },
      )
      ..loadHtmlString(_buildVideoHtml());
  }

  String _buildVideoHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
    video { width: 100%; height: 100%; object-fit: contain; }
  </style>
</head>
<body>
  <video id="player" controls autoplay playsinline webkit-playsinline preload="auto">
    <source src="${widget.videoUrl}" type="video/mp4">
  </video>
  <script>
    var v = document.getElementById('player');
    v.addEventListener('timeupdate', function() {
      if (typeof FlutterVideoProgress !== 'undefined') {
        FlutterVideoProgress.postMessage(v.currentTime + ',' + v.duration);
      }
    });
  </script>
</body>
</html>
''';
  }

  void _onVideoProgress() {
    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      // Get current time in seconds (with milliseconds precision)
      final positionMs = _videoPlayerController!.value.position.inMilliseconds;
      _currentTime = positionMs / 1000.0;

      // Get total duration in seconds
      final durationMs = _videoPlayerController!.value.duration.inMilliseconds;
      _duration = durationMs / 1000.0;
    }
  }

  Future<void> _onClose() async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🎬 VideoPlayerScreen: Closing video player');
    debugPrint('   lessonId: ${widget.lessonId}');
    debugPrint('   courseId: ${widget.courseId}');
    debugPrint('   enrollmentId: ${widget.enrollmentId}');
    debugPrint('   currentTime: $_currentTime');
    debugPrint('   duration: $_duration');
    debugPrint('═══════════════════════════════════════════════════════');

    if (widget.lessonId != null) {
      await _updateLessonStatus();
      await _updateVideoProgress();
    } else {
      debugPrint('⚠️ VideoPlayerScreen: lessonId is null, skipping API calls');
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _updateLessonStatus() async {
    if (widget.lessonId == null) {
      debugPrint('⚠️ _updateLessonStatus: lessonId is null, skipping');
      return;
    }

    debugPrint('🔄 _updateLessonStatus: Calling API...');
    try {
      final result = await _coursesService.changeLessonStatus(
        lessonId: widget.lessonId!,
        lessonStatus: 1,
      );
      debugPrint('🔄 _updateLessonStatus: Result = $result');
    } catch (e) {
      debugPrint('❌ _updateLessonStatus: Error = $e');
    }
  }

  Future<void> _updateVideoProgress() async {
    if (widget.lessonId == null) {
      debugPrint('⚠️ _updateVideoProgress: lessonId is null, skipping');
      return;
    }
    if (widget.courseId == null) {
      debugPrint('⚠️ _updateVideoProgress: courseId is null, skipping');
      return;
    }
    if (widget.enrollmentId == null) {
      debugPrint('⚠️ _updateVideoProgress: enrollmentId is null, skipping');
      return;
    }

    debugPrint('🔄 _updateVideoProgress: Calling API with currentTime=$_currentTime, duration=$_duration...');
    try {
      final result = await _coursesService.changeS3VideoProgress(
        enrollmentId: widget.enrollmentId!,
        courseId: widget.courseId!,
        lessonId: widget.lessonId!,
        currentTime: _currentTime,
        duration: _duration,
      );
      debugPrint('🔄 _updateVideoProgress: Result = $result');
    } catch (e) {
      debugPrint('❌ _updateVideoProgress: Error = $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _onClose,
          ),
          title: Text(
            widget.title,
            style: GoogleFonts.alexandria(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_useWebView && _webViewController != null) {
      return WebViewWidget(controller: _webViewController!);
    }

    if (_chewieController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    return _buildErrorView();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء تحميل الفيديو',
              style: GoogleFonts.alexandria(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'خطأ غير معروف',
              style: GoogleFonts.alexandria(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isLoading = true;
                      _useWebView = false;
                    });
                    _initializePlayer();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'إعادة المحاولة',
                    style: GoogleFonts.alexandria(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F6EB7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                  label: Text(
                    'إغلاق',
                    style: GoogleFonts.alexandria(),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
