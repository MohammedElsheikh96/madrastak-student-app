class Post {
  final String? id;
  final String? spaceId;
  final String? title;
  final String? content;
  final int viewCount;
  final int commentsCount;
  final int likesCount;
  final bool isLikedByMe;
  final bool isPinned;
  final String? pinnedAt;
  final List<PostFile> files;
  final PostUser? user;
  final List<dynamic> comments;
  final String? created;
  final String? createdBy;
  final String? lastModified;
  final String? lastModifiedBy;

  Post({
    this.id,
    this.spaceId,
    this.title,
    this.content,
    this.viewCount = 0,
    this.commentsCount = 0,
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.isPinned = false,
    this.pinnedAt,
    this.files = const [],
    this.user,
    this.comments = const [],
    this.created,
    this.createdBy,
    this.lastModified,
    this.lastModifiedBy,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Parse files
    List<PostFile> filesList = [];
    if (json['files'] != null) {
      for (var file in json['files']) {
        filesList.add(PostFile.fromJson(file));
      }
    }

    // Parse user
    PostUser? postUser;
    if (json['user'] != null) {
      postUser = PostUser.fromJson(json['user']);
    }

    // Parse comments
    List<dynamic> commentsList = [];
    if (json['comments'] != null) {
      commentsList = json['comments'] as List<dynamic>;
    }

    return Post(
      id: json['id']?.toString(),
      spaceId: json['spaceId']?.toString(),
      title: json['title'],
      content: json['content'],
      viewCount: json['viewCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      isLikedByMe: json['islikedByMe'] ?? false,
      isPinned: json['isPinned'] ?? false,
      pinnedAt: json['pinnedAt'],
      files: filesList,
      user: postUser,
      comments: commentsList,
      created: json['created'],
      createdBy: json['createdBy'],
      lastModified: json['lastModified'],
      lastModifiedBy: json['lastModifiedBy'],
    );
  }

  // Get author name from user object
  String get authorName => user?.name ?? '';

  // Get author image from user object
  String get authorImage => user?.profileImageUrl ?? '';

  // Get image URLs from files
  List<String> get images {
    return files
        .where((file) => file.type?.startsWith('image/') ?? false)
        .map((file) => file.path ?? '')
        .where((path) => path.isNotEmpty)
        .toList();
  }

  // Get document files (PDF, Word, PowerPoint, Excel)
  List<PostFile> get documentFiles {
    return files.where((file) => file.isDocument).toList();
  }

  // Strip HTML tags from content
  String get plainContent {
    if (content == null) return '';
    // Remove HTML tags
    return content!
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  // Format date for display
  String get formattedDate {
    if (created == null || created!.isEmpty) return '';
    try {
      final date = DateTime.parse(created!);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} يوم';
      } else {
        // Format as date
        final months = [
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
        ];
        return '${date.day} ${months[date.month - 1]}، ${date.year}';
      }
    } catch (e) {
      return created ?? '';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spaceId': spaceId,
      'title': title,
      'content': content,
      'viewCount': viewCount,
      'commentsCount': commentsCount,
      'likesCount': likesCount,
      'islikedByMe': isLikedByMe,
      'isPinned': isPinned,
      'pinnedAt': pinnedAt,
      'files': files.map((f) => f.toJson()).toList(),
      'user': user?.toJson(),
      'comments': comments,
      'created': created,
      'createdBy': createdBy,
      'lastModified': lastModified,
      'lastModifiedBy': lastModifiedBy,
    };
  }
}

class PostFile {
  final String? name;
  final String? type;
  final int? size;
  final String? path;
  final String? externalId;

  PostFile({
    this.name,
    this.type,
    this.size,
    this.path,
    this.externalId,
  });

  factory PostFile.fromJson(Map<String, dynamic> json) {
    return PostFile(
      name: json['name'],
      type: json['type'],
      size: json['size'],
      path: json['path'],
      externalId: json['externalId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'size': size,
      'path': path,
      'externalId': externalId,
    };
  }

  bool get isImage => type?.startsWith('image/') ?? false;

  /// Check if file is a PDF
  bool get isPdf {
    final ext = _extension.toLowerCase();
    return ext == 'pdf' || type == 'application/pdf';
  }

  /// Check if file is a Word document
  bool get isWord {
    final ext = _extension.toLowerCase();
    return ext == 'doc' || ext == 'docx' ||
           type == 'application/msword' ||
           type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }

  /// Check if file is a PowerPoint presentation
  bool get isPowerPoint {
    final ext = _extension.toLowerCase();
    return ext == 'ppt' || ext == 'pptx' ||
           type == 'application/vnd.ms-powerpoint' ||
           type == 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
  }

  /// Check if file is an Excel spreadsheet
  bool get isExcel {
    final ext = _extension.toLowerCase();
    return ext == 'xls' || ext == 'xlsx' ||
           type == 'application/vnd.ms-excel' ||
           type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }

  /// Check if file is a document (PDF, Word, PowerPoint, or Excel)
  bool get isDocument => isPdf || isWord || isPowerPoint || isExcel;

  /// Get file extension from name
  String get _extension {
    if (name == null || !name!.contains('.')) return '';
    return name!.split('.').last;
  }

  /// Get file extension for display
  String get fileExtension => _extension.toUpperCase();

  /// Get file type label in Arabic
  String get fileTypeLabel {
    if (isPdf) return 'PDF';
    if (isWord) return 'Word';
    if (isPowerPoint) return 'PowerPoint';
    if (isExcel) return 'Excel';
    return fileExtension;
  }

  /// Get formatted file size
  String get formattedSize {
    if (size == null) return '';
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class PostUser {
  final String? id;
  final String? profileImageUrl;
  final String? name;
  final String? profileSpaceId;

  PostUser({
    this.id,
    this.profileImageUrl,
    this.name,
    this.profileSpaceId,
  });

  factory PostUser.fromJson(Map<String, dynamic> json) {
    return PostUser(
      id: json['id'],
      profileImageUrl: json['profileImageUrl'],
      name: json['name'],
      profileSpaceId: json['profileSpaceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileImageUrl': profileImageUrl,
      'name': name,
      'profileSpaceId': profileSpaceId,
    };
  }
}

class PostsPagedResponse {
  final List<Post> posts;
  final int totalCount;

  PostsPagedResponse({
    required this.posts,
    required this.totalCount,
  });

  factory PostsPagedResponse.fromJson(Map<String, dynamic> json) {
    List<Post> postsList = [];
    if (json['posts'] != null) {
      for (var post in json['posts']) {
        postsList.add(Post.fromJson(post));
      }
    }

    return PostsPagedResponse(
      posts: postsList,
      totalCount: json['count'] ?? 0,
    );
  }
}

class PostComment {
  final String? id;
  final String? postId;
  final String? parentCommentId;
  final String? creatorUserName;
  final String? creatorProfilePictureUrl;
  final String? content;
  final int likesCount;
  final int repliesCount;
  final bool isLikedByMe;
  final String? created;
  final String? createdBy;
  final String? lastModified;
  final String? lastModifiedBy;
  final List<PostComment> replies;

  PostComment({
    this.id,
    this.postId,
    this.parentCommentId,
    this.creatorUserName,
    this.creatorProfilePictureUrl,
    this.content,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.isLikedByMe = false,
    this.created,
    this.createdBy,
    this.lastModified,
    this.lastModifiedBy,
    this.replies = const [],
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    // Parse nested replies if present
    List<PostComment> repliesList = [];
    if (json['replies'] != null) {
      for (var reply in json['replies']) {
        repliesList.add(PostComment.fromJson(reply));
      }
    }

    return PostComment(
      id: json['id']?.toString(),
      postId: json['postId']?.toString(),
      parentCommentId: json['parentCommentId']?.toString(),
      creatorUserName: json['creatorUserName'],
      creatorProfilePictureUrl: json['creatorProfilePictureUrl'],
      content: json['content'],
      likesCount: json['likesCount'] ?? 0,
      repliesCount: json['repliesCount'] ?? 0,
      isLikedByMe: json['islikedByMe'] ?? false,
      created: json['created'],
      createdBy: json['createdBy'],
      lastModified: json['lastModified'],
      lastModifiedBy: json['lastModifiedBy'],
      replies: repliesList,
    );
  }

  // Create a copy with updated replies
  PostComment copyWith({
    String? id,
    String? postId,
    String? parentCommentId,
    String? creatorUserName,
    String? creatorProfilePictureUrl,
    String? content,
    int? likesCount,
    int? repliesCount,
    bool? isLikedByMe,
    String? created,
    String? createdBy,
    String? lastModified,
    String? lastModifiedBy,
    List<PostComment>? replies,
  }) {
    return PostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      creatorUserName: creatorUserName ?? this.creatorUserName,
      creatorProfilePictureUrl: creatorProfilePictureUrl ?? this.creatorProfilePictureUrl,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      created: created ?? this.created,
      createdBy: createdBy ?? this.createdBy,
      lastModified: lastModified ?? this.lastModified,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      replies: replies ?? this.replies,
    );
  }

  // Check if this is a reply (has parent comment)
  bool get isReply => parentCommentId != null && parentCommentId!.isNotEmpty && parentCommentId != 'null';

  // Format date for display
  String get formattedDate {
    if (created == null || created!.isEmpty) return '';
    try {
      final date = DateTime.parse(created!);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ساعة';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} يوم';
      } else {
        final months = [
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
        ];
        return '${date.day} ${months[date.month - 1]}';
      }
    } catch (e) {
      return created ?? '';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'parentCommentId': parentCommentId,
      'creatorUserName': creatorUserName,
      'creatorProfilePictureUrl': creatorProfilePictureUrl,
      'content': content,
      'likesCount': likesCount,
      'repliesCount': repliesCount,
      'islikedByMe': isLikedByMe,
      'created': created,
      'createdBy': createdBy,
      'lastModified': lastModified,
      'lastModifiedBy': lastModifiedBy,
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }

  /// Build a comment tree from a flat list of comments
  /// Returns only root comments with their nested replies
  static List<PostComment> buildCommentTree(List<PostComment> comments, {String? parentCommentId}) {
    final List<PostComment> commentTree = [];

    for (final comment in comments) {
      // Get parent ID
      final commentParentId = comment.parentCommentId;
      final commentId = comment.id;

      // Check if this comment belongs to the current parent
      bool isMatch;
      if (parentCommentId == null) {
        // Looking for root comments (no parent)
        isMatch = commentParentId == null ||
                  commentParentId.isEmpty ||
                  commentParentId == 'null';
      } else {
        // Looking for replies to a specific parent
        isMatch = commentParentId == parentCommentId;
      }

      if (isMatch) {
        // Recursively get replies for this comment
        final replies = buildCommentTree(comments, parentCommentId: commentId);

        // Create comment with nested replies
        final commentWithReplies = comment.copyWith(
          replies: replies,
        );

        commentTree.add(commentWithReplies);
      }
    }

    return commentTree;
  }
}

// Full post detail with parsed comments
class PostDetail {
  final Post post;
  final List<PostComment> comments;

  PostDetail({
    required this.post,
    required this.comments,
  });

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    // Parse post
    final post = Post.fromJson(json);

    // Parse comments
    List<PostComment> commentsList = [];
    if (json['comments'] != null) {
      for (var comment in json['comments']) {
        commentsList.add(PostComment.fromJson(comment));
      }
    }

    return PostDetail(
      post: post,
      comments: commentsList,
    );
  }

  // Get root comments (not replies)
  List<PostComment> get rootComments {
    return comments.where((c) => !c.isReply).toList();
  }

  // Get replies for a specific comment
  List<PostComment> getRepliesFor(String commentId) {
    return comments.where((c) => c.parentCommentId == commentId).toList();
  }
}
