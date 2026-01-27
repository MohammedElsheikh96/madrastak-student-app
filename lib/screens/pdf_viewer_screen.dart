import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final int? lessonId;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.lessonId,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  /// Create Dio instance with SSL certificate bypass
  Dio _createDio() {
    final dio = Dio();
    dio.options.headers['Accept'] = '*/*';

    // Bypass SSL certificate verification for madrastak.moe.edu.eg
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };

    return dio;
  }

  Future<void> _loadPdf() async {
    try {
      debugPrint('PdfViewerScreen: Loading PDF from: ${widget.pdfUrl}');

      final dir = await getTemporaryDirectory();
      final fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${dir.path}/$fileName';

      final dio = _createDio();

      await dio.download(
        widget.pdfUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint('PdfViewerScreen: Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      debugPrint('PdfViewerScreen: PDF downloaded to: $filePath');

      if (mounted) {
        setState(() {
          _localPath = filePath;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('PdfViewerScreen: Error loading PDF: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      // Always try to save to public Downloads folder
      Directory? downloadsDir;
      String filePath;

      if (Platform.isAndroid) {
        // Try public Downloads folder first
        final publicDownloads = Directory('/storage/emulated/0/Download');

        if (await publicDownloads.exists()) {
          // Check if we can write to it
          try {
            final testFile = File('${publicDownloads.path}/.test_write');
            await testFile.writeAsString('test');
            await testFile.delete();
            downloadsDir = publicDownloads;
          } catch (e) {
            // Need permission
            debugPrint('PdfViewerScreen: Cannot write to Downloads, requesting permission');
            var status = await Permission.storage.request();

            if (!status.isGranted) {
              status = await Permission.manageExternalStorage.request();
            }

            if (status.isGranted) {
              downloadsDir = publicDownloads;
            }
          }
        }

        // Fallback to app-specific directory if Downloads not accessible
        if (downloadsDir == null) {
          downloadsDir = await getExternalStorageDirectory();
          if (downloadsDir != null) {
            // Create a Downloads subfolder in app directory
            final appDownloads = Directory('${downloadsDir.path}/Downloads');
            if (!await appDownloads.exists()) {
              await appDownloads.create(recursive: true);
            }
            downloadsDir = appDownloads;
          }
        }

        // Last fallback
        if (downloadsDir == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'يجب منح إذن التخزين لتحميل الملف',
                  style: GoogleFonts.alexandria(),
                ),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'الإعدادات',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
            setState(() {
              _isDownloading = false;
            });
          }
          return;
        }
      } else {
        downloadsDir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
      }

      final fileName = '${widget.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      filePath = '${downloadsDir.path}/$fileName';

      debugPrint('PdfViewerScreen: Downloading PDF to: $filePath');

      final dio = _createDio();

      await dio.download(
        widget.pdfUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      // Verify file was created
      final downloadedFile = File(filePath);
      if (!await downloadedFile.exists()) {
        throw Exception('File was not saved');
      }

      final fileSize = await downloadedFile.length();
      debugPrint('PdfViewerScreen: File saved successfully, size: $fileSize bytes');

      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحميل الملف في مجلد التنزيلات',
              style: GoogleFonts.alexandria(),
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'فتح',
              textColor: Colors.white,
              onPressed: () async {
                await OpenFilex.open(filePath);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('PdfViewerScreen: Error downloading PDF: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء تحميل الملف',
              style: GoogleFonts.alexandria(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F6EB7),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
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
          actions: [
            if (!_isLoading && _error == null)
              _isDownloading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          value: _downloadProgress > 0 ? _downloadProgress : null,
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download, color: Colors.white),
                      onPressed: _downloadPdf,
                      tooltip: 'تحميل',
                    ),
          ],
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF0F6EB7),
            ),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل الملف...',
              style: GoogleFonts.alexandria(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
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
                'حدث خطأ أثناء تحميل الملف',
                style: GoogleFonts.alexandria(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.alexandria(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _loadPdf();
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
            ],
          ),
        ),
      );
    }

    if (_localPath != null) {
      return Stack(
        children: [
          PDFView(
            filePath: _localPath!,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0;
              });
            },
            onViewCreated: (controller) {
              debugPrint('PdfViewerScreen: PDF view created');
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page ?? 0;
              });
            },
            onError: (error) {
              debugPrint('PdfViewerScreen: PDF error: $error');
              setState(() {
                _error = error.toString();
              });
            },
            onPageError: (page, error) {
              debugPrint('PdfViewerScreen: Page $page error: $error');
            },
          ),
          if (_totalPages > 0)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
