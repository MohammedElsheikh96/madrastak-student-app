import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/post.dart';
import '../services/space_service.dart';
import 'post_card.dart';
import 'create_post_sheet.dart';

/// A reusable widget that displays a list of posts for a given course/space.
/// Can be used in both HomeTab and CommunicationTab.
class PostsListWidget extends StatefulWidget {
  /// The course to display posts for
  final Course course;

  /// Optional pre-loaded spaceId (if null, will be fetched)
  final String? spaceId;

  /// Whether the space is currently loading
  final bool isLoadingSpace;

  /// Error message if space loading failed
  final String? spaceError;

  /// Callback to retry loading space
  final VoidCallback? onRetryLoadSpace;

  /// Whether to show the course header (cover image, name, etc.)
  final bool showCourseHeader;

  /// Current user name for post creation
  final String userName;

  /// Current user image for post creation
  final String? userImage;

  /// Current user ID for checking post ownership
  final String? currentUserId;

  const PostsListWidget({
    super.key,
    required this.course,
    this.spaceId,
    this.isLoadingSpace = false,
    this.spaceError,
    this.onRetryLoadSpace,
    this.showCourseHeader = true,
    required this.userName,
    this.userImage,
    this.currentUserId,
  });

  @override
  State<PostsListWidget> createState() => _PostsListWidgetState();
}

class _PostsListWidgetState extends State<PostsListWidget> {
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
  void didUpdateWidget(PostsListWidget oldWidget) {
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
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: _getItemCount(),
          itemBuilder: (context, index) {
            // Course header (if enabled)
            if (widget.showCourseHeader && index == 0) {
              return _buildCourseHeader();
            }

            // Adjust index if header is shown
            final adjustedIndex = widget.showCourseHeader ? index - 1 : index;

            // Loading posts indicator (initial load)
            if (_isLoadingPosts && _posts.isEmpty) {
              if (adjustedIndex == 0) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
                  ),
                );
              }
              return const SizedBox.shrink();
            }

            // Posts error
            if (_postsError != null && _posts.isEmpty) {
              if (adjustedIndex == 0) {
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
              return const SizedBox.shrink();
            }

            // Empty state
            if (_posts.isEmpty && !_isLoadingPosts) {
              if (adjustedIndex == 0) {
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
              return const SizedBox.shrink();
            }

            // Post items
            if (adjustedIndex < _posts.length) {
              final post = _posts[adjustedIndex];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PostCard(
                  postId: post.id,
                  authorName: post.authorName,
                  authorImage: post.authorImage,
                  authorUserId: post.user?.id,
                  currentUserId: widget.currentUserId,
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
                  currentUserName: widget.userName,
                  currentUserImage: widget.userImage,
                  onLikeChanged: (isLiked, newCount) {
                    // Update local post state
                    setState(() {
                      _posts[adjustedIndex] = Post(
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
    int count = widget.showCourseHeader ? 1 : 0; // Header
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
              SizedBox(
                height: 160,
                width: double.infinity,
                child: widget.course.coverImage != null
                    ? Image.network(
                        widget.course.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF1A237E),
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: Colors.white54,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFF1A237E),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Colors.white54,
                          ),
                        ),
                      ),
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
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: widget.course.image != null
                            ? Image.network(
                                widget.course.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFF5F5F5),
                                    child: const Icon(
                                      Icons.menu_book,
                                      size: 40,
                                      color: Color(0xFF0F6EB7),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: const Color(0xFFF5F5F5),
                                child: const Icon(
                                  Icons.menu_book,
                                  size: 40,
                                  color: Color(0xFF0F6EB7),
                                ),
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
      builder: (context) => CreatePostSheet(
        userName: widget.userName,
        userImage: widget.userImage,
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
