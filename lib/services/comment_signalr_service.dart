import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../models/post.dart';

/// SignalR message types for comments
enum CommentMessageType {
  commentCreated,
  commentUpdated,
  commentDeleted,
}

/// SignalR message for comment events
class CommentSignalRMessage {
  final CommentMessageType type;
  final PostComment? comment;
  final List<String>? deletedCommentIds;

  CommentSignalRMessage({
    required this.type,
    this.comment,
    this.deletedCommentIds,
  });
}

/// SignalR service for real-time comment updates
class CommentSignalRService {
  static const String _baseHubUrl = 'https://twassol-api.madrasetna.net/twassolApi/CommentHub';

  HubConnection? _hubConnection;
  final String _postId;
  final String _token;

  // Stream controller for broadcasting messages
  final _messageController = StreamController<CommentSignalRMessage>.broadcast();
  Stream<CommentSignalRMessage> get messages$ => _messageController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  CommentSignalRService({
    required String postId,
    required String token,
  })  : _postId = postId,
        _token = token;

  /// Initialize and connect to SignalR hub
  Future<bool> connect() async {
    final hubUrl = '$_baseHubUrl?postId=$_postId';

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔌 SignalR: Connecting to hub...');
    debugPrint('   URL: $hubUrl');
    debugPrint('   PostId: $_postId');
    debugPrint('   Token: ${_token.length > 20 ? '${_token.substring(0, 20)}...' : _token}');
    debugPrint('═══════════════════════════════════════════════════════');

    // Try Long Polling first since it works with this server, then WebSocket
    final transportOptions = [
      // Option 1: Long Polling (most compatible, works with this server)
      HttpConnectionOptions(
        accessTokenFactory: () async => _token,
        transport: HttpTransportType.LongPolling,
      ),
      // Option 2: Auto (let server negotiate - uses Long Polling or SSE)
      HttpConnectionOptions(
        accessTokenFactory: () async => _token,
      ),
      // Option 3: Server Sent Events
      HttpConnectionOptions(
        accessTokenFactory: () async => _token,
        transport: HttpTransportType.ServerSentEvents,
      ),
      // Option 4: WebSocket (may not be supported by server)
      HttpConnectionOptions(
        accessTokenFactory: () async => _token,
        transport: HttpTransportType.WebSockets,
        skipNegotiation: true,
      ),
    ];

    for (var i = 0; i < transportOptions.length; i++) {
      try {
        debugPrint('🔌 SignalR: Trying transport option ${i + 1}/${transportOptions.length}...');

        _hubConnection = HubConnectionBuilder()
            .withUrl(hubUrl, options: transportOptions[i])
            .withAutomaticReconnect()
            .build();

        // Set up event listeners before connecting
        _setupListeners();
        _setupConnectionHandlers();

        // Start connection with timeout
        await _hubConnection!.start()!.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Connection timed out after 15 seconds');
          },
        );

        _isConnected = true;

        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🟢 SignalR connected successfully with option ${i + 1}!');
        debugPrint('   Connection ID: ${_hubConnection!.connectionId}');
        debugPrint('   State: ${_hubConnection!.state}');
        debugPrint('═══════════════════════════════════════════════════════');

        // Join the post group to receive updates for this specific post
        await _joinPostGroup();

        return true;
      } catch (e) {
        debugPrint('⚠️ SignalR: Transport option ${i + 1} failed: $e');
        _hubConnection = null;
        _isConnected = false;

        // Continue to next transport option
        if (i < transportOptions.length - 1) {
          debugPrint('   Trying next transport option...');
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('❌ SignalR: All transport options failed');
    debugPrint('═══════════════════════════════════════════════════════');
    return false;
  }

  /// Setup connection state handlers
  void _setupConnectionHandlers() {
    if (_hubConnection == null) return;

    _hubConnection!.onclose(({Exception? error}) {
      _isConnected = false;
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔴 SignalR connection CLOSED: $error');
      debugPrint('═══════════════════════════════════════════════════════');
    });

    _hubConnection!.onreconnecting(({Exception? error}) {
      _isConnected = false;
      debugPrint('🟡 SignalR RECONNECTING: $error');
    });

    _hubConnection!.onreconnected(({String? connectionId}) {
      _isConnected = true;
      debugPrint('🟢 SignalR RECONNECTED: $connectionId');
      // Re-join the post group after reconnection
      _joinPostGroup();
    });
  }

  /// Join the post group to receive real-time updates
  Future<void> _joinPostGroup() async {
    if (_hubConnection == null || !_isConnected) return;

    try {
      debugPrint('🔗 SignalR: Joining post group for postId: $_postId');
      await _hubConnection!.invoke('JoinPostGroup', args: [_postId]);
      debugPrint('✅ SignalR: Successfully joined post group');
    } catch (e) {
      debugPrint('⚠️ SignalR: Failed to join post group: $e');
      // Some hubs may not require explicit joining if postId is in the URL
    }
  }

  /// Set up SignalR event listeners
  void _setupListeners() {
    if (_hubConnection == null) return;

    debugPrint('📡 SignalR: Setting up event listeners...');

    // Listen for all possible event names the server might use
    // Based on .NET SignalR hub naming conventions
    final eventNames = [
      // Main event names
      'CommentUpdates',
      'CommentCreated',
      'CommentUpdated',
      'CommentDeleted',
      // Alternative naming conventions
      'ReceiveComment',
      'NewComment',
      'OnCommentCreated',
      'OnCommentUpdated',
      'OnCommentDeleted',
      // camelCase variants
      'commentUpdates',
      'commentCreated',
      'commentUpdated',
      'commentDeleted',
      'receiveComment',
      'newComment',
      // Generic message events
      'ReceiveMessage',
      'SendComment',
      'BroadcastComment',
    ];

    for (final eventName in eventNames) {
      _hubConnection!.on(eventName, (args) {
        debugPrint('📨 SignalR EVENT [$eventName]: $args');
        _handleCommentMessage(args);
      });
    }

    debugPrint('✅ SignalR: ${eventNames.length} event listeners set up');
    debugPrint('   Events: ${eventNames.join(', ')}');
  }

  /// Handle incoming comment message from SignalR
  void _handleCommentMessage(List<Object?>? arguments) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📨 SignalR: Received message!');
    debugPrint('   Raw arguments: $arguments');
    debugPrint('   Arguments type: ${arguments?.runtimeType}');
    debugPrint('   Arguments length: ${arguments?.length}');
    debugPrint('═══════════════════════════════════════════════════════');

    if (arguments == null || arguments.isEmpty) {
      debugPrint('⚠️ SignalR: Empty arguments received');
      return;
    }

    try {
      // Log all arguments for debugging
      for (int i = 0; i < arguments.length; i++) {
        debugPrint('📨 SignalR: Arg[$i] type: ${arguments[i]?.runtimeType}');
        debugPrint('📨 SignalR: Arg[$i] value: ${arguments[i]}');
      }

      // Try to parse the first argument
      final firstArg = arguments[0];

      Map<String, dynamic>? message;

      if (firstArg is Map<String, dynamic>) {
        message = firstArg;
      } else if (firstArg is Map) {
        message = Map<String, dynamic>.from(firstArg);
      } else if (firstArg is String) {
        // Some servers send JSON as string
        debugPrint('📨 SignalR: First arg is String, trying to parse as JSON...');
        try {
          final decoded = jsonDecode(firstArg);
          if (decoded is Map) {
            message = Map<String, dynamic>.from(decoded);
          }
        } catch (e) {
          debugPrint('⚠️ SignalR: Failed to parse string as JSON: $e');
        }
      } else {
        debugPrint('⚠️ SignalR: Unexpected argument type: ${firstArg?.runtimeType}');
        // Try to handle the message anyway if we have a PostComment structure
      }

      if (message == null) {
        debugPrint('⚠️ SignalR: Could not parse message as Map');
        return;
      }

      debugPrint('📨 SignalR: Parsed message: $message');

      // Type can be string or int depending on server implementation
      final rawType = message['Type'] ?? message['type'];
      String? messageType;

      if (rawType is String) {
        messageType = rawType;
      } else if (rawType is int) {
        // Map int to string type
        switch (rawType) {
          case 1:
            messageType = 'CommentCreated';
            break;
          case 2:
            messageType = 'CommentUpdated';
            break;
          case 3:
            messageType = 'CommentDeleted';
            break;
        }
      }

      debugPrint('📨 SignalR: Message type: $messageType (raw: $rawType)');

      switch (messageType) {
        case 'CommentCreated':
          final commentData = (message['Comment'] ?? message['comment']) as Map<String, dynamic>?;
          if (commentData != null) {
            debugPrint('✅ SignalR: CommentCreated data: $commentData');
            final comment = _parseCommentFromSignalR(commentData);
            debugPrint('✅ SignalR: Parsed comment ID: ${comment.id}');
            debugPrint('✅ SignalR: Parsed comment content: ${comment.content}');
            debugPrint('✅ SignalR: Adding to stream controller...');
            _messageController.add(CommentSignalRMessage(
              type: CommentMessageType.commentCreated,
              comment: comment,
            ));
            debugPrint('✅ SignalR: Message added to stream controller!');
          }
          break;

        case 'CommentUpdated':
          final commentData = (message['Comment'] ?? message['comment']) as Map<String, dynamic>?;
          if (commentData != null) {
            debugPrint('✅ SignalR: CommentUpdated data: $commentData');
            final comment = _parseCommentFromSignalR(commentData);
            _messageController.add(CommentSignalRMessage(
              type: CommentMessageType.commentUpdated,
              comment: comment,
            ));
          }
          break;

        case 'CommentDeleted':
          final deletedIds = ((message['DeletedCommentIds'] ?? message['deletedCommentIds']) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList();
          debugPrint('✅ SignalR: CommentDeleted IDs: $deletedIds');
          _messageController.add(CommentSignalRMessage(
            type: CommentMessageType.commentDeleted,
            deletedCommentIds: deletedIds,
          ));
          break;

        default:
          debugPrint('⚠️ SignalR: Unknown message type: $messageType');
          // Try to handle as direct comment if no type
          if (message.containsKey('id') || message.containsKey('Id')) {
            debugPrint('📨 SignalR: Trying to parse as direct comment...');
            final comment = _parseCommentFromSignalR(message);
            _messageController.add(CommentSignalRMessage(
              type: CommentMessageType.commentCreated,
              comment: comment,
            ));
          }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ SignalR: Error parsing message: $e');
      debugPrint('   Stack trace: $stackTrace');
    }
  }

  /// Parse comment from SignalR message (may have different casing)
  PostComment _parseCommentFromSignalR(Map<String, dynamic> data) {
    // SignalR uses PascalCase, convert to camelCase recursively
    // Also fix Arabic text encoding
    final normalizedData = _convertKeysAndFixEncoding(data);
    debugPrint('SignalR normalized comment data: $normalizedData');
    return PostComment.fromJson(normalizedData);
  }

  /// Fix Arabic text that was incorrectly decoded as Latin-1 instead of UTF-8
  String _fixArabicEncoding(String text) {
    try {
      // Check if text looks like it was incorrectly decoded
      // Arabic characters incorrectly decoded as Latin-1 will have high byte values
      if (text.contains('Ø') || text.contains('Ù')) {
        // The text was decoded as Latin-1 but is actually UTF-8
        // Re-encode as Latin-1 bytes, then decode as UTF-8
        final latin1Bytes = latin1.encode(text);
        return utf8.decode(latin1Bytes);
      }
      return text;
    } catch (e) {
      debugPrint('⚠️ SignalR: Failed to fix encoding for: $text, error: $e');
      return text;
    }
  }

  /// Recursively convert map keys from PascalCase to camelCase and fix Arabic encoding
  Map<String, dynamic> _convertKeysAndFixEncoding(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    data.forEach((key, value) {
      // Convert PascalCase to camelCase
      final camelKey = key.isNotEmpty
          ? key[0].toLowerCase() + key.substring(1)
          : key;

      // Recursively convert nested maps and fix string encoding
      if (value is Map<String, dynamic>) {
        result[camelKey] = _convertKeysAndFixEncoding(value);
      } else if (value is Map) {
        result[camelKey] = _convertKeysAndFixEncoding(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[camelKey] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _convertKeysAndFixEncoding(item);
          } else if (item is Map) {
            return _convertKeysAndFixEncoding(Map<String, dynamic>.from(item));
          } else if (item is String) {
            return _fixArabicEncoding(item);
          }
          return item;
        }).toList();
      } else if (value is String) {
        // Fix Arabic text encoding for string values
        result[camelKey] = _fixArabicEncoding(value);
      } else {
        result[camelKey] = value;
      }
    });

    return result;
  }

  /// Disconnect from SignalR hub
  Future<void> disconnect() async {
    try {
      if (_hubConnection != null) {
        await _hubConnection!.stop();
        _hubConnection = null;
      }
      _isConnected = false;
      debugPrint('SignalR disconnected');
    } catch (e) {
      debugPrint('Error disconnecting SignalR: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
