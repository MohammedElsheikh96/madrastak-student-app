import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/space_service.dart';

/// A reusable bottom sheet widget for creating new posts
class CreatePostSheet extends StatefulWidget {
  final String userName;
  final String? userImage;
  final String courseId;
  final String? spaceId;
  final Function(bool success, String message) onPostResult;

  const CreatePostSheet({
    super.key,
    required this.userName,
    this.userImage,
    required this.courseId,
    this.spaceId,
    required this.onPostResult,
  });

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController _contentController = TextEditingController();
  final SpaceService _spaceService = SpaceService();
  final ImagePicker _imagePicker = ImagePicker();

  List<File> _selectedFiles = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickMediaFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في اختيار الملفات');
    }
  }

  Future<void> _pickMediaFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (image != null) {
        setState(() {
          _selectedFiles.add(File(image.path));
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في فتح الكاميرا');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        setState(() {
          _selectedFiles.add(File(video.path));
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في اختيار الفيديو');
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(
            result.files
                .where((file) => file.path != null)
                .map((file) => File(file.path!)),
          );
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في اختيار الملفات');
    }
  }

  Future<void> _pickGif() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gif'],
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(
            result.files
                .where((file) => file.path != null)
                .map((file) => File(file.path!)),
          );
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في اختيار GIF');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF0F6EB7),
                ),
                title: const Text('اختيار صور من المعرض'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMediaFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0F6EB7)),
                title: const Text('التقاط صورة بالكاميرا'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMediaFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF0F6EB7)),
                title: const Text('اختيار فيديو'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.attach_file,
                  color: Color(0xFF0F6EB7),
                ),
                title: const Text('اختيار ملف'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFiles();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedFiles.isEmpty) {
      _showErrorSnackBar('يرجى كتابة محتوى أو إضافة ملفات');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _spaceService.createPost(
        content: content.isEmpty ? ' ' : content,
        spaceId: widget.spaceId,
        files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
      );

      if (mounted) {
        widget.onPostResult(result.success, result.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('حدث خطأ في نشر المنشور');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final statusBarHeight = mediaQuery.padding.top;

    return Container(
      height: screenHeight - statusBarHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Close button
                      GestureDetector(
                        onTap: _isLoading ? null : () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: _isLoading
                              ? Colors.grey.shade300
                              : const Color(0xFF757575),
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'انشاء منشور',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const Spacer(),
                      // Placeholder for symmetry
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // User info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: widget.userImage != null
                            ? NetworkImage(widget.userImage!)
                            : null,
                        child: widget.userImage == null
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // User name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content input - Scrollable to handle keyboard
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: keyboardHeight > 0 ? 16 : 0,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            minLines: 3,
                            enabled: !_isLoading,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              hintText: 'شارك افكارك هنا؟',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9E9E9E),
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        // Selected files preview
                        if (_selectedFiles.isNotEmpty) _buildFilesPreview(),
                      ],
                    ),
                  ),
                ),
                // Bottom section - moves up with keyboard
                AnimatedPadding(
                  duration: const Duration(milliseconds: 100),
                  padding: EdgeInsets.only(bottom: keyboardHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Attachment options
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            // GIF option
                            GestureDetector(
                              onTap: _isLoading ? null : _pickGif,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'GIF',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _isLoading
                                            ? Colors.grey.shade300
                                            : const Color(0xFF757575),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.gif_box_outlined,
                                      size: 20,
                                      color: _isLoading
                                          ? Colors.grey.shade300
                                          : const Color(0xFF757575),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Image/Video/File option
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : _showMediaPickerOptions,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'صورة/فيديو/ملف',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _isLoading
                                            ? Colors.grey.shade300
                                            : const Color(0xFF757575),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.attach_file,
                                      size: 20,
                                      color: _isLoading
                                          ? Colors.grey.shade300
                                          : const Color(0xFF757575),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Post button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitPost,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canSubmit()
                                  ? const Color(0xFF0F6EB7)
                                  : const Color(0xFFBDBDBD),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'نشر',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
              ),
            ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    return _contentController.text.trim().isNotEmpty ||
        _selectedFiles.isNotEmpty;
  }

  Widget _buildFilesPreview() {
    // Separate image files from other files
    final imageFiles = <File>[];
    final otherFiles = <File>[];

    for (final file in _selectedFiles) {
      final fileName = file.path.split('/').last.split('\\').last;
      if (_isImageFile(fileName)) {
        imageFiles.add(file);
      } else {
        otherFiles.add(file);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Images grid (same style as post images)
          if (imageFiles.isNotEmpty) _buildImagesGridLocal(imageFiles),
          // Other files list
          if (otherFiles.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: imageFiles.isNotEmpty ? 8 : 0),
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: otherFiles.length,
                  itemBuilder: (context, index) {
                    final file = otherFiles[index];
                    final fileName = file.path.split('/').last.split('\\').last;
                    final fileIndex = _selectedFiles.indexOf(file);

                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(left: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildFileIcon(fileName),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeFile(fileIndex),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagesGridLocal(List<File> images) {
    if (images.length == 1) {
      return _buildSingleImageLocal(images[0], 0, images);
    } else if (images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: _buildGridImageLocal(
              images[0],
              0,
              images,
              const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildGridImageLocal(
              images[1],
              1,
              images,
              const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
        ],
      );
    } else if (images.length == 3) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildGridImageLocal(
                  images[0],
                  0,
                  images,
                  const BorderRadius.only(topRight: Radius.circular(12)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildGridImageLocal(
                  images[1],
                  1,
                  images,
                  const BorderRadius.only(topLeft: Radius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildSingleImageLocal(
            images[2],
            2,
            images,
            height: 120,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      );
    } else {
      // 4+ images - 2x2 grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildGridImageLocal(
                  images[0],
                  0,
                  images,
                  const BorderRadius.only(topRight: Radius.circular(12)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildGridImageLocal(
                  images[1],
                  1,
                  images,
                  const BorderRadius.only(topLeft: Radius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildGridImageLocal(
                  images[2],
                  2,
                  images,
                  const BorderRadius.only(bottomRight: Radius.circular(12)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Stack(
                  children: [
                    _buildGridImageLocal(
                      images[3],
                      3,
                      images,
                      const BorderRadius.only(bottomLeft: Radius.circular(12)),
                    ),
                    if (images.length > 4)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => _showLocalImageGallery(images, 3),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '+${images.length - 4}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSingleImageLocal(
    File file,
    int index,
    List<File> allImages, {
    double height = 200,
    BorderRadius? borderRadius,
  }) {
    final fileIndex = _selectedFiles.indexOf(file);
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showLocalImageGallery(allImages, index),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            child: Image.file(
              file,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: height,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeFile(fileIndex),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridImageLocal(
    File file,
    int index,
    List<File> allImages,
    BorderRadius borderRadius,
  ) {
    final fileIndex = _selectedFiles.indexOf(file);
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showLocalImageGallery(allImages, index),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Image.file(
              file,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 120, color: Colors.grey.shade200),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeFile(fileIndex),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _showLocalImageGallery(List<File> imageFiles, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return LocalImageGalleryViewer(
            imageFiles: imageFiles,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  bool _isImageFile(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  Widget _buildFileIcon(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    IconData icon;
    Color color;

    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      icon = Icons.videocam;
      color = Colors.purple;
    } else if (['pdf'].contains(ext)) {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (['doc', 'docx'].contains(ext)) {
      icon = Icons.description;
      color = Colors.blue;
    } else if (['gif'].contains(ext)) {
      icon = Icons.gif;
      color = Colors.orange;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Container(
      width: 100,
      height: 100,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

/// Local image gallery viewer for previewing selected images
class LocalImageGalleryViewer extends StatefulWidget {
  final List<File> imageFiles;
  final int initialIndex;

  const LocalImageGalleryViewer({
    super.key,
    required this.imageFiles,
    required this.initialIndex,
  });

  @override
  State<LocalImageGalleryViewer> createState() => _LocalImageGalleryViewerState();
}

class _LocalImageGalleryViewerState extends State<LocalImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageFiles.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.file(
                    widget.imageFiles[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.white54,
                    ),
                  ),
                ),
              );
            },
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          // Page indicator
          if (widget.imageFiles.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageFiles.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
