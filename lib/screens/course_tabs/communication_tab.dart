import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/course.dart';
import '../../models/post.dart';
import '../../services/space_service.dart';
import '../../widgets/post_card.dart';

class CommunicationTab extends StatefulWidget {
  final Course course;
  final String? spaceId;
  final bool isLoadingSpace;
  final String? spaceError;
  final VoidCallback? onRetryLoadSpace;

  const CommunicationTab({
    super.key,
    required this.course,
    this.spaceId,
    this.isLoadingSpace = false,
    this.spaceError,
    this.onRetryLoadSpace,
  });

  @override
  State<CommunicationTab> createState() => _CommunicationTabState();
}

class _CommunicationTabState extends State<CommunicationTab> {
  // Mock user data - will be replaced with real data from storage
  final String _userName = 'محمد احمد محمد';
  final String? _userImage = null; // Will use placeholder
  // TODO: Get actual userId from auth service
  static const String _userId = 'c5061673-5b5f-4e5e-ab78-d9f51eef3dd2';

  // Pagination state
  final SpaceService _spaceService = SpaceService();
  final ScrollController _scrollController = ScrollController();
  final List<Post> _posts = [];
  int _pageNumber = 1;
  final int _pageSize = 10;
  int _totalCount = 0;
  bool _isLoadingPosts = false;
  bool _isLoadingMore = false;
  String? _postsError;
  String? _previousSpaceId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load posts if spaceId is available
    if (widget.spaceId != null) {
      _loadPosts();
    }
  }

  @override
  void didUpdateWidget(CommunicationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If spaceId changed or became available, reload posts
    if (widget.spaceId != null && widget.spaceId != _previousSpaceId) {
      _previousSpaceId = widget.spaceId;
      _resetAndLoadPosts();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if we're near the bottom of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  void _resetAndLoadPosts() {
    setState(() {
      _posts.clear();
      _pageNumber = 1;
      _totalCount = 0;
      _postsError = null;
    });
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (widget.spaceId == null || _isLoadingPosts) return;

    setState(() {
      _isLoadingPosts = true;
      _postsError = null;
    });

    try {
      final result = await _spaceService.getPostsPaged(
        spaceId: widget.spaceId!,
        pageNumber: _pageNumber,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
          if (result.success && result.posts != null) {
            _posts.addAll(result.posts!);
            _totalCount = result.totalCount;
            _pageNumber++;
          } else if (!result.success) {
            _postsError = result.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
          _postsError = 'حدث خطأ في تحميل المنشورات';
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    // Don't load more if already loading or all posts are loaded
    if (_isLoadingMore || _isLoadingPosts || widget.spaceId == null) return;
    if (_posts.length >= _totalCount && _totalCount > 0) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _spaceService.getPostsPaged(
        spaceId: widget.spaceId!,
        pageNumber: _pageNumber,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (result.success && result.posts != null) {
            _posts.addAll(result.posts!);
            _totalCount = result.totalCount;
            _pageNumber++;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    _resetAndLoadPosts();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while space is being loaded
    if (widget.isLoadingSpace) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0F6EB7)),
              SizedBox(height: 16),
              Text(
                'جاري تحميل المساحة...',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state if space failed to load
    if (widget.spaceError != null) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFF757575),
              ),
              const SizedBox(height: 16),
              Text(
                widget.spaceError!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (widget.onRetryLoadSpace != null)
                ElevatedButton(
                  onPressed: widget.onRetryLoadSpace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F6EB7),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('إعادة المحاولة'),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F5F5),
      child: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: const Color(0xFF0F6EB7),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _getItemCount(),
          itemBuilder: (context, index) {
            // Course header
            if (index == 0) {
              return _buildCourseHeader();
            }

            // Loading posts indicator (initial load)
            if (_isLoadingPosts && _posts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
                ),
              );
            }

            // Posts error
            if (_postsError != null && _posts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Color(0xFF757575),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _postsError!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6EB7),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Empty state
            if (_posts.isEmpty && !_isLoadingPosts) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: Color(0xFF757575),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد منشورات بعد',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'كن أول من يشارك!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Post items
            final postIndex = index - 1; // Subtract 1 for header
            if (postIndex < _posts.length) {
              final post = _posts[postIndex];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PostCard(
                  postId: post.id,
                  authorName: post.authorName,
                  authorImage: post.authorImage,
                  authorUserId: post.user?.id,
                  currentUserId: _userId,
                  date: post.formattedDate,
                  title: post.title,
                  content: post.plainContent,
                  images: post.images.isNotEmpty ? post.images : null,
                  files: post.files.isNotEmpty ? post.files : null,
                  isCoursPost: false,
                  isPinned: post.isPinned,
                  likesCount: post.likesCount,
                  commentsCount: post.commentsCount,
                  sharesCount: 0,
                  isLikedByMe: post.isLikedByMe,
                  currentUserName: _userName,
                  currentUserImage: _userImage,
                  onLikeChanged: (isLiked, newCount) {
                    // Update local post state
                    setState(() {
                      _posts[postIndex] = Post(
                        id: post.id,
                        spaceId: post.spaceId,
                        title: post.title,
                        content: post.content,
                        viewCount: post.viewCount,
                        commentsCount: post.commentsCount,
                        likesCount: newCount,
                        isLikedByMe: isLiked,
                        isPinned: post.isPinned,
                        pinnedAt: post.pinnedAt,
                        files: post.files,
                        user: post.user,
                        comments: post.comments,
                        created: post.created,
                        createdBy: post.createdBy,
                        lastModified: post.lastModified,
                        lastModifiedBy: post.lastModifiedBy,
                      );
                    });
                  },
                  onPostSheetClosed: _refreshPosts,
                  onPostDeleted: _refreshPosts,
                ),
              );
            }

            // Loading more indicator
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  int _getItemCount() {
    int count = 1; // Header
    if (_isLoadingPosts && _posts.isEmpty) {
      count++; // Loading indicator
    } else if (_postsError != null && _posts.isEmpty) {
      count++; // Error state
    } else if (_posts.isEmpty) {
      count++; // Empty state
    } else {
      count += _posts.length; // Posts
      if (_isLoadingMore) {
        count++; // Loading more indicator
      }
    }
    return count;
  }

  Widget _buildCourseHeader() {
    return Column(
      children: [
        // Stack for cover image and overlapping course image + name
        SizedBox(
          height: 240, // cover(160) + half of course image overlapping (50)
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover image section (full width)
              Container(
                height: 160,
                width: double.infinity,
                child: widget.course.image != null
                    ? Image.network(
                        widget.course.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: const Color(0xFF1A237E));
                        },
                      )
                    : Container(color: const Color(0xFF1A237E)),
              ),
              // Course image box and name (positioned to overlap cover)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Course image on the left
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: widget.course.image != null
                            ? Image.network(
                                widget.course.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.book,
                                    size: 30,
                                    color: Colors.grey,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.book,
                                size: 30,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    // Course name on the right
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'مادة ${widget.course.displayName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Share prompt section
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => _showCreatePostPopup(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'شارك افكارك هنا؟',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreatePostPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostSheet(
        userName: _userName,
        userImage: _userImage,
        courseId: widget.course.id.toString(),
        spaceId: widget.spaceId,
        onPostResult: (success, message) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: success ? const Color(0xFF0F6EB7) : Colors.red,
            ),
          );
          // Refresh posts list on successful post creation
          if (success) {
            _refreshPosts();
          }
        },
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  final String userName;
  final String? userImage;
  final String courseId;
  final String? spaceId;
  final Function(bool success, String message) onPostResult;

  const _CreatePostSheet({
    required this.userName,
    this.userImage,
    required this.courseId,
    this.spaceId,
    required this.onPostResult,
  });

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
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
