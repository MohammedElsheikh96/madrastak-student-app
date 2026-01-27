import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/space_service.dart';
import '../services/comment_signalr_service.dart';

class PostCard extends StatefulWidget {
  final String? postId;
  final String authorName;
  final String authorImage;
  final String date;
  final String? title;
  final String content;
  final List<String>? images;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isCoursPost;
  final bool isPinned;
  final bool isLikedByMe;
  final String currentUserName;
  final String? currentUserImage;
  final VoidCallback? onCommentTap;
  final void Function(bool isLiked, int newCount)? onLikeChanged;
  final VoidCallback? onPostSheetClosed;

  const PostCard({
    super.key,
    this.postId,
    required this.authorName,
    required this.authorImage,
    required this.date,
    this.title,
    required this.content,
    this.images,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isCoursPost = false,
    this.isPinned = false,
    this.isLikedByMe = false,
    required this.currentUserName,
    this.currentUserImage,
    this.onCommentTap,
    this.onLikeChanged,
    this.onPostSheetClosed,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final SpaceService _spaceService = SpaceService();
  late bool _isLikedByMe;
  late int _likesCount;
  bool _isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    _isLikedByMe = widget.isLikedByMe;
    _likesCount = widget.likesCount;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLikedByMe != widget.isLikedByMe) {
      _isLikedByMe = widget.isLikedByMe;
    }
    if (oldWidget.likesCount != widget.likesCount) {
      _likesCount = widget.likesCount;
    }
  }

  Future<void> _handleLike() async {
    if (_isLikeLoading || widget.postId == null) return;

    final wasLiked = _isLikedByMe;
    final oldCount = _likesCount;

    // Optimistic update
    setState(() {
      _isLikedByMe = !wasLiked;
      _likesCount = wasLiked ? oldCount - 1 : oldCount + 1;
      _isLikeLoading = true;
    });

    // Notify parent
    widget.onLikeChanged?.call(_isLikedByMe, _likesCount);

    // Call API
    final success = wasLiked
        ? await _spaceService.unlikePost(widget.postId!)
        : await _spaceService.likePost(widget.postId!);

    // Rollback if failed
    if (!success && mounted) {
      setState(() {
        _isLikedByMe = wasLiked;
        _likesCount = oldCount;
      });
      widget.onLikeChanged?.call(wasLiked, oldCount);
    }

    if (mounted) {
      setState(() {
        _isLikeLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Author avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: widget.isCoursPost
                        ? const Color(0xFF0F6EB7)
                        : Colors.grey.shade200,
                    image: !widget.isCoursPost && widget.authorImage.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.authorImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.isCoursPost
                      ? const Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 24,
                        )
                      : (widget.authorImage.isEmpty
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null),
                ),
                const SizedBox(width: 12),
                // Author name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.authorName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.more_horiz, color: Color(0xFF757575)),
              ],
            ),
          ),
          // Post title (bold)
          if (widget.title != null && widget.title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (widget.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: const Color(0xFF0F6EB7),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.title!,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Post content (normal)
          if (widget.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: (widget.title != null && widget.title!.isNotEmpty) ? 8 : 0,
              ),
              child: Text(
                widget.content,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  height: 1.6,
                ),
              ),
            ),
          // Post images grid
          if (widget.images != null && widget.images!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _PostImagesGrid(
                images: widget.images!,
                onImageTap: (index) =>
                    _showImageGallery(context, widget.images!, index),
              ),
            ),
          // Post actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like button with gesture detector
                GestureDetector(
                  onTap: _handleLike,
                  child: Row(
                    children: [
                      Icon(
                        _isLikedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 18,
                        color: _isLikedByMe
                            ? const Color(0xFF0F6EB7)
                            : const Color(0xFF757575),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_likesCount اعجاب',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isLikedByMe
                              ? const Color(0xFF0F6EB7)
                              : const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                // Comment button
                GestureDetector(
                  onTap:
                      widget.onCommentTap ??
                      () => _showSinglePostPopup(context),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: const Color(0xFF757575),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.commentsCount} تعليق',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Comment input
          GestureDetector(
            onTap: widget.onCommentTap ?? () => _showSinglePostPopup(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text(
                    'اكتب تعليقك هنا',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: widget.currentUserImage != null
                        ? NetworkImage(widget.currentUserImage!)
                        : null,
                    child: widget.currentUserImage == null
                        ? const Icon(Icons.send, size: 16, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageGallery(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ImageGalleryViewer(images: images, initialIndex: initialIndex);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showSinglePostPopup(BuildContext context) {
    if (widget.postId == null || widget.postId!.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SinglePostSheet(
        postId: widget.postId!,
        currentUserName: widget.currentUserName,
        currentUserImage: widget.currentUserImage,
        onClose: widget.onPostSheetClosed,
      ),
    );
  }
}

// Post Images Grid Widget
class _PostImagesGrid extends StatelessWidget {
  final List<String> images;
  final Function(int) onImageTap;

  const _PostImagesGrid({required this.images, required this.onImageTap});

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => onImageTap(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            images[0],
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, size: 50, color: Colors.grey),
            ),
          ),
        ),
      );
    } else if (images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onImageTap(0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.network(
                  images[0],
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(height: 150, color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => onImageTap(1),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Image.network(
                  images[1],
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(height: 150, color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // 2x2 grid for 4 images
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onImageTap(0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      images[0],
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 120, color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => onImageTap(1),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                    child: Image.network(
                      images[1],
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 120, color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onImageTap(2),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      images.length > 2 ? images[2] : '',
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 120, color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => onImageTap(3),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.network(
                      images.length > 3 ? images[3] : '',
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 120, color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }
}

// Single Post Sheet with Comments
class SinglePostSheet extends StatefulWidget {
  final String postId;
  final String currentUserName;
  final String? currentUserImage;
  final VoidCallback? onClose;

  const SinglePostSheet({
    super.key,
    required this.postId,
    required this.currentUserName,
    this.currentUserImage,
    this.onClose,
  });

  @override
  State<SinglePostSheet> createState() => _SinglePostSheetState();
}

class _SinglePostSheetState extends State<SinglePostSheet> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpaceService _spaceService = SpaceService();

  String? _replyingToCommentId;
  bool _isLoading = true;
  String? _error;
  PostDetail? _postDetail;

  // Like state for post
  bool _isPostLikedByMe = false;
  int _postLikesCount = 0;
  bool _isPostLikeLoading = false;

  // Like state for comments (commentId -> {isLiked, likesCount})
  final Map<String, bool> _commentLikeStates = {};
  final Map<String, int> _commentLikeCounts = {};
  final Set<String> _commentLikeLoading = {};

  // Track which comments have replies expanded
  final Set<String> _expandedReplies = {};

  // Comment submission state
  bool _isSubmittingComment = false;
  bool _isSubmittingReply = false;

  // SignalR for real-time updates
  CommentSignalRService? _signalRService;
  StreamSubscription<CommentSignalRMessage>? _signalRSubscription;

  // Local comments list (for real-time updates)
  List<PostComment> _allComments = [];

  // Comment tree (hierarchical structure with nested replies)
  List<PostComment> _commentTree = [];

  /// Rebuild the comment tree from the flat list of comments
  void _rebuildCommentTree() {
    _commentTree = PostComment.buildCommentTree(_allComments);
    debugPrint('📋 Comment tree rebuilt: ${_commentTree.length} root comments');
  }

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _spaceService.getPostById(widget.postId);
      if (result.success && result.postDetail != null) {
        setState(() {
          _postDetail = result.postDetail;
          _isPostLikedByMe = result.postDetail!.post.isLikedByMe;
          _postLikesCount = result.postDetail!.post.likesCount;
          // Initialize local comments list
          _allComments = List.from(result.postDetail!.comments);
          // Build comment tree for hierarchical display
          _rebuildCommentTree();
          _isLoading = false;
        });
        // Connect to SignalR after loading
        _connectToSignalR();
      } else {
        setState(() {
          _error = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل المنشور';
        _isLoading = false;
      });
    }
  }

  /// Connect to SignalR for real-time comment updates
  Future<void> _connectToSignalR() async {
    // Use static token for now (same as SpaceService)
    const token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjJiODVmZTk2LTU3ZjgtNDBiNi05NjAxLTMyYTA3Mjg4NmUxMSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvdXNlcmRhdGEiOiJjNTA2MTY3My01YjVmLTRlNWUtYWI3OC1kOWY1MWVlZjNkZDIiLCJuYW1lIjoi2LnYqNiv2KfZhNmH2KfYr9mJINmF2K3ZhdivINi52KjYr9in2YTZh9in2K_ZiSDYudmE2Ykg2KfZhNi02YrZiNmJIiwiZW1haWwiOiIxNDU0MUBzYWJyb2FkLm1vZS5lZHUuZWciLCJwaG9uZV9udW1iZXIiOiIiLCJwcm9maWxlX3BpY3R1cmVfdXJsIjoiIiwic3RhZ2VfbmFtZSI6Itin2YTYqti52YTZitmFINin2YTYp9i52K_Yp9iv2YogIiwiZ3JhZGVfbmFtZSI6Itin2YTYtdmBINin2YTYq9in2YbZiiDYp9mE2KfYudiv2KfYr9mKIiwiY291bnRyeV9uYW1lIjoi2KXZiti32KfZhNmK2KciLCJuYmYiOjE3Njk1MTQ3MTEsImV4cCI6MTc2OTg2MDMxMSwiaWF0IjoxNzY5NTE0NzExfQ.uLbi6Ih3MsUq-Hyastmj2HP7IPpw9EgGz01gvsi3NiY';

    _signalRService = CommentSignalRService(
      postId: widget.postId,
      token: token,
    );

    // Subscribe to stream BEFORE connecting so we catch messages during connection
    _signalRSubscription = _signalRService!.messages$.listen(
      _handleSignalRMessage,
    );
    debugPrint('🔔 SinglePostSheet: Subscribed to SignalR messages stream');

    // Connect (even if it fails, messages may arrive during the process)
    final connected = await _signalRService!.connect();
    debugPrint('🔔 SinglePostSheet: SignalR connect result: $connected');
  }

  /// Handle incoming SignalR messages
  void _handleSignalRMessage(CommentSignalRMessage message) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔔 SinglePostSheet: Received SignalR message!');
    debugPrint('   Type: ${message.type}');
    debugPrint('   Comment: ${message.comment?.id}');
    debugPrint('   Mounted: $mounted');
    debugPrint('═══════════════════════════════════════════════════════');

    if (!mounted) {
      debugPrint('⚠️ SinglePostSheet: Widget not mounted, ignoring message');
      return;
    }

    switch (message.type) {
      case CommentMessageType.commentCreated:
        if (message.comment != null) {
          debugPrint('✅ SinglePostSheet: Handling new comment...');
          _handleNewComment(message.comment!);
        } else {
          debugPrint('⚠️ SinglePostSheet: Comment is null for commentCreated');
        }
        break;
      case CommentMessageType.commentUpdated:
        if (message.comment != null) {
          _handleUpdatedComment(message.comment!);
        }
        break;
      case CommentMessageType.commentDeleted:
        if (message.deletedCommentIds != null) {
          _handleDeletedComments(message.deletedCommentIds!);
        }
        break;
    }
  }

  /// Handle new comment from SignalR
  void _handleNewComment(PostComment newComment) {
    debugPrint('📝 SinglePostSheet: _handleNewComment called');
    debugPrint('   New comment ID: ${newComment.id}');
    debugPrint('   New comment content: ${newComment.content}');
    debugPrint('   Parent comment ID: ${newComment.parentCommentId}');
    debugPrint('   Current comments count: ${_allComments.length}');

    // Check if comment already exists
    if (_allComments.any((c) => c.id == newComment.id)) {
      debugPrint('⚠️ SinglePostSheet: Comment already exists, skipping');
      return;
    }

    debugPrint('✅ SinglePostSheet: Adding new comment to list...');
    setState(() {
      _allComments.add(newComment);
      debugPrint('   New comments count: ${_allComments.length}');
      // Rebuild comment tree for hierarchical display
      _rebuildCommentTree();
      // Rebuild PostDetail with updated comments
      if (_postDetail != null) {
        _postDetail = PostDetail(
          post: _postDetail!.post,
          comments: _allComments,
        );
        debugPrint('✅ SinglePostSheet: PostDetail rebuilt with new comments');
      }
    });
  }

  /// Handle updated comment from SignalR
  void _handleUpdatedComment(PostComment updatedComment) {
    final index = _allComments.indexWhere((c) => c.id == updatedComment.id);
    if (index == -1) return;

    setState(() {
      _allComments[index] = updatedComment;
      // Update local like state if needed
      _commentLikeStates[updatedComment.id!] = updatedComment.isLikedByMe;
      _commentLikeCounts[updatedComment.id!] = updatedComment.likesCount;
      // Rebuild comment tree
      _rebuildCommentTree();
      // Rebuild PostDetail with updated comments
      if (_postDetail != null) {
        _postDetail = PostDetail(
          post: _postDetail!.post,
          comments: _allComments,
        );
      }
    });
  }

  /// Handle deleted comments from SignalR
  void _handleDeletedComments(List<String> deletedIds) {
    setState(() {
      _allComments.removeWhere((c) => deletedIds.contains(c.id));
      // Rebuild comment tree
      _rebuildCommentTree();
      // Rebuild PostDetail with updated comments
      if (_postDetail != null) {
        _postDetail = PostDetail(
          post: _postDetail!.post,
          comments: _allComments,
        );
      }
    });
  }

  /// Submit a new comment
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmittingComment || _postDetail == null) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final result = await _spaceService.createComment(
        postId: widget.postId,
        content: content,
      );

      if (mounted) {
        if (result.success) {
          _commentController.clear();
          // If we got the comment back and SignalR didn't add it yet, add it
          if (result.comment != null &&
              !_allComments.any((c) => c.id == result.comment!.id)) {
            _handleNewComment(result.comment!);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في إضافة التعليق'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  /// Submit a reply to a comment
  Future<void> _submitReply(String parentCommentId) async {
    final content = _replyController.text.trim();
    if (content.isEmpty || _isSubmittingReply || _postDetail == null) return;

    setState(() {
      _isSubmittingReply = true;
    });

    try {
      final result = await _spaceService.createComment(
        postId: widget.postId,
        content: content,
        parentCommentId: parentCommentId,
      );

      if (mounted) {
        if (result.success) {
          _replyController.clear();
          setState(() {
            _replyingToCommentId = null;
            // Auto-expand replies for the parent comment
            _expandedReplies.add(parentCommentId);
          });
          // If we got the comment back and SignalR didn't add it yet, add it
          if (result.comment != null &&
              !_allComments.any((c) => c.id == result.comment!.id)) {
            _handleNewComment(result.comment!);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في إضافة الرد'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReply = false;
        });
      }
    }
  }

  Future<void> _handlePostLike() async {
    if (_isPostLikeLoading || _postDetail == null) return;

    final wasLiked = _isPostLikedByMe;
    final oldCount = _postLikesCount;

    // Optimistic update
    setState(() {
      _isPostLikedByMe = !wasLiked;
      _postLikesCount = wasLiked ? oldCount - 1 : oldCount + 1;
      _isPostLikeLoading = true;
    });

    // Call API
    final success = wasLiked
        ? await _spaceService.unlikePost(_postDetail!.post.id!)
        : await _spaceService.likePost(_postDetail!.post.id!);

    // Rollback if failed
    if (!success && mounted) {
      setState(() {
        _isPostLikedByMe = wasLiked;
        _postLikesCount = oldCount;
      });
    }

    if (mounted) {
      setState(() {
        _isPostLikeLoading = false;
      });
    }
  }

  /// Get like state for a comment (from local state or original comment)
  bool _isCommentLiked(PostComment comment) {
    return _commentLikeStates[comment.id] ?? comment.isLikedByMe;
  }

  /// Get like count for a comment (from local state or original comment)
  int _getCommentLikeCount(PostComment comment) {
    return _commentLikeCounts[comment.id] ?? comment.likesCount;
  }

  Future<void> _handleCommentLike(PostComment comment) async {
    final commentId = comment.id;
    if (commentId == null || _commentLikeLoading.contains(commentId)) return;

    final wasLiked = _isCommentLiked(comment);
    final oldCount = _getCommentLikeCount(comment);

    // Optimistic update
    setState(() {
      _commentLikeStates[commentId] = !wasLiked;
      _commentLikeCounts[commentId] = wasLiked ? oldCount - 1 : oldCount + 1;
      _commentLikeLoading.add(commentId);
    });

    // Call API
    final success = wasLiked
        ? await _spaceService.unlikeComment(commentId)
        : await _spaceService.likeComment(commentId);

    // Rollback if failed
    if (!success && mounted) {
      setState(() {
        _commentLikeStates[commentId] = wasLiked;
        _commentLikeCounts[commentId] = oldCount;
      });
    }

    if (mounted) {
      setState(() {
        _commentLikeLoading.remove(commentId);
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    _scrollController.dispose();
    // Clean up SignalR
    _signalRSubscription?.cancel();
    _signalRService?.dispose();
    // Notify parent to refresh posts (for updated comment counts, likes, etc.)
    widget.onClose?.call();
    super.dispose();
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content based on loading state
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPostData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F6EB7),
                          ),
                          child: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        // Post content
                        _buildPostContent(),
                        const Divider(height: 1),
                        // Comments section
                        _buildCommentsSection(),
                      ],
                    ),
                  ),
          ),
          // Comment input - fixed at bottom with safe area
          if (!_isLoading && _error == null)
            AnimatedPadding(
              duration: const Duration(milliseconds: 100),
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: SafeArea(top: false, child: _buildCommentInput()),
            ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    if (_postDetail == null) return const SizedBox.shrink();

    final post = _postDetail!.post;
    final authorImage = post.authorImage;
    final authorName = post.authorName;
    final date = post.formattedDate;
    final title = post.title;
    final content = post.plainContent;
    final images = post.images;
    final isPinned = post.isPinned;
    final commentsCount = post.commentsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Author avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                  image: authorImage.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(authorImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: authorImage.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              // Author name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.more_horiz, color: Color(0xFF757575)),
            ],
          ),
        ),
        // Post title (bold)
        if (title != null && title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (isPinned)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.push_pin,
                      size: 16,
                      color: const Color(0xFF0F6EB7),
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Post content (normal)
        if (content.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: (title != null && title.isNotEmpty) ? 8 : 0,
            ),
            child: Text(
              content,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
                height: 1.6,
              ),
            ),
          ),
        // Post images grid
        if (images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPostImagesGrid(images),
          ),
        // Post actions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Like button with gesture detector
              GestureDetector(
                onTap: _handlePostLike,
                child: Row(
                  children: [
                    Icon(
                      _isPostLikedByMe
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      size: 18,
                      color: _isPostLikedByMe
                          ? const Color(0xFF0F6EB7)
                          : const Color(0xFF757575),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_postLikesCount اعجاب',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isPostLikedByMe
                            ? const Color(0xFF0F6EB7)
                            : const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              // Comment button
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: const Color(0xFF757575),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$commentsCount تعليق',
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
    );
  }

  Widget _buildPostImagesGrid(List<String> images) {
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _showNetworkImageGallery(images, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            images[0],
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, size: 50, color: Colors.grey),
            ),
          ),
        ),
      );
    } else if (images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showNetworkImageGallery(images, 0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.network(
                  images[0],
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(height: 150, color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => _showNetworkImageGallery(images, 1),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Image.network(
                  images[1],
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(height: 150, color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // 2x2 grid for 4 images
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showNetworkImageGallery(images, 0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      images[0],
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 120, color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showNetworkImageGallery(images, 1),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                    child: Image.network(
                      images[1],
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 120, color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showNetworkImageGallery(images, 2),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      images.length > 2 ? images[2] : '',
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 120, color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showNetworkImageGallery(images, 3),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.network(
                      images.length > 3 ? images[3] : '',
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 120, color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  void _showNetworkImageGallery(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ImageGalleryViewer(images: images, initialIndex: initialIndex);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (_postDetail == null) return const SizedBox.shrink();

    // Use the comment tree (hierarchical structure)
    if (_commentTree.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'لا توجد تعليقات بعد',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Column(
      children: _commentTree
          .map((comment) => _buildCommentItem(comment))
          .toList(),
    );
  }

  Widget _buildCommentItem(PostComment comment, {int depth = 0}) {
    // Use nested replies from comment tree (supports unlimited nesting)
    final replies = comment.replies;
    final bool showReplies = _expandedReplies.contains(comment.id);

    // Calculate indentation based on depth (max 3 levels of indentation)
    final indentLevel = depth.clamp(0, 3);
    final rightPadding = 16.0 + (indentLevel * 40.0);

    return Container(
      padding: EdgeInsets.only(
        right: rightPadding,
        left: 16,
        top: 12,
        bottom: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Header row: Avatar + (Name, Date) on left, More button on right
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    comment.creatorProfilePictureUrl != null &&
                        comment.creatorProfilePictureUrl!.isNotEmpty
                    ? NetworkImage(comment.creatorProfilePictureUrl!)
                    : null,
                child:
                    comment.creatorProfilePictureUrl == null ||
                        comment.creatorProfilePictureUrl!.isEmpty
                    ? const Icon(Icons.person, size: 18, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 8),
              // Name and date column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.creatorUserName ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      comment.formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // More button
              const Icon(Icons.more_horiz, size: 18, color: Color(0xFF9E9E9E)),
            ],
          ),
          const SizedBox(height: 8),
          // Comment bubble - aligned to the right, under the name
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    comment.content ?? '',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Comment actions row
          Row(
            children: [
              // Like button with gesture detector
              GestureDetector(
                onTap: () => _handleCommentLike(comment),
                child: Row(
                  children: [
                    Icon(
                      _isCommentLiked(comment)
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      size: 14,
                      color: _isCommentLiked(comment)
                          ? const Color(0xFF0F6EB7)
                          : const Color(0xFF757575),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_getCommentLikeCount(comment)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isCommentLiked(comment)
                            ? const Color(0xFF0F6EB7)
                            : const Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'اعجاب',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isCommentLiked(comment)
                            ? const Color(0xFF0F6EB7)
                            : const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Reply button
              GestureDetector(
                onTap: () {
                  setState(() {
                    // Toggle reply input - if already replying to this comment, close it
                    if (_replyingToCommentId == comment.id) {
                      _replyingToCommentId = null;
                      _replyController.clear();
                    } else {
                      _replyingToCommentId = comment.id;
                    }
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: _replyingToCommentId == comment.id
                          ? const Color(0xFF0F6EB7)
                          : const Color(0xFF757575),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${comment.repliesCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _replyingToCommentId == comment.id
                            ? const Color(0xFF0F6EB7)
                            : const Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'رد',
                      style: TextStyle(
                        fontSize: 12,
                        color: _replyingToCommentId == comment.id
                            ? const Color(0xFF0F6EB7)
                            : const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Far left: show replies link (available at all depths)
              if (replies.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (showReplies) {
                        _expandedReplies.remove(comment.id);
                      } else {
                        _expandedReplies.add(comment.id!);
                      }
                    });
                  },
                  child: Text(
                    showReplies
                        ? 'إخفاء الردود'
                        : 'اظهر ${replies.length} رد ...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0F6EB7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          // Reply input (shows when replying to this comment)
          if (_replyingToCommentId == comment.id)
            _buildReplyInput(comment.id ?? ''),
          // Replies (collapsible) - supports unlimited nesting depth
          if (replies.isNotEmpty && showReplies)
            ...replies.map(
              (reply) => _buildCommentItem(reply, depth: depth + 1),
            ),
          if (depth == 0) const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildReplyInput(String commentId) {
    return Container(
      margin: const EdgeInsets.only(top: 12, right: 52),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: TextField(
              controller: _replyController,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              autofocus: true,
              enabled: !_isSubmittingReply,
              decoration: InputDecoration(
                hintText: 'اكتب ردك هنا...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onSubmitted: (_) => _submitReply(commentId),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: _isSubmittingReply ? null : () => _submitReply(commentId),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isSubmittingReply
                    ? Colors.grey.shade400
                    : const Color(0xFF0F6EB7),
                shape: BoxShape.circle,
              ),
              child: _isSubmittingReply
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          // Cancel button
          GestureDetector(
            onTap: _isSubmittingReply
                ? null
                : () {
                    setState(() {
                      _replyingToCommentId = null;
                      _replyController.clear();
                    });
                  },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isSubmittingReply
                    ? Colors.grey.shade200
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: _isSubmittingReply ? Colors.grey.shade400 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: TextField(
              controller: _commentController,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              enabled: !_isSubmittingComment,
              decoration: InputDecoration(
                hintText: 'اكتب تعليقك هنا',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 12),
          // Send button
          GestureDetector(
            onTap: _isSubmittingComment ? null : _submitComment,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isSubmittingComment
                    ? Colors.grey.shade400
                    : const Color(0xFF0F6EB7),
                shape: BoxShape.circle,
              ),
              child: _isSubmittingComment
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Image Gallery Viewer with Slider
class ImageGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageGalleryViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Image slider
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
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
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            // Close button
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            // Page indicator
            if (widget.images.length > 1)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            // Image counter
            if (widget.images.length > 1)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Local Image Gallery Viewer for File objects
class LocalImageGalleryViewer extends StatefulWidget {
  final List<File> imageFiles;
  final int initialIndex;

  const LocalImageGalleryViewer({
    super.key,
    required this.imageFiles,
    required this.initialIndex,
  });

  @override
  State<LocalImageGalleryViewer> createState() =>
      _LocalImageGalleryViewerState();
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Image slider
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
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Close button
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            // Page indicator
            if (widget.imageFiles.length > 1)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.imageFiles.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            // Image counter
            if (widget.imageFiles.length > 1)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageFiles.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
