import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:pet_care_app/screens/feed/video_player/video_player_preview.dart';
import 'package:pet_care_app/screens/feed/video_player/video_player_widget.dart';
import 'package:pet_care_app/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String participantName;
  final String participantImageUrl;
  final String type;

  ChatScreen({
    required this.chatId,
    required this.participantName,
    required this.participantImageUrl,
    required this.type,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  StreamSubscription<QuerySnapshot>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesAsRead(widget.chatId);
    _messageController.addListener(() {
      final isTyping = _messageController.text.isNotEmpty;
      _chatService.setTypingStatus(widget.chatId, isTyping);
    });
    _initializeReadMessages();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _chatService.setTypingStatus(
        widget.chatId, false); // Ensure typing stops on exit
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildTypingIndicator(String otherUserId) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _chatService.getTypingStatus(widget.chatId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();

        final typingStatus = snapshot.data!;
        final isTyping = typingStatus[otherUserId] ?? false;

        if (!isTyping) return SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 8),
              Text(
                '${widget.participantName} is typing...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Initializes the real-time listener to mark messages as read
  void _initializeReadMessages() {
    _messageSubscription =
        _chatService.getMessages(widget.chatId).listen((snapshot) async {
      if (snapshot.docs.isEmpty) return; // No messages to process

      final batch = FirebaseFirestore.instance.batch();
      try {
        for (var doc in snapshot.docs) {
          final messageData = doc.data() as Map<String, dynamic>;
          final readBy = messageData['readBy'] ?? [];
          final senderId = messageData['senderId'];

          // Mark as read only if unread and not sent by the current user
          if (!readBy.contains(_currentUserId) && senderId != _currentUserId) {
            Logger().i('Marking message as read: ${doc.id}');
            batch.update(doc.reference, {
              'readBy': FieldValue.arrayUnion([_currentUserId]),
            });
          }
        }

        // Commit the batch update
        await batch.commit();

        // Reset unread count for the chat
        await FirebaseFirestore.instance
            .collection('Chats')
            .doc(widget.chatId)
            .update({
          'unreadCount.$_currentUserId': 0,
        });
      } catch (e) {
        Logger().e('Failed to mark messages as read: $e');
      }
    });
  }

  Widget _buildGradientBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.blue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Container(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          decoration: const BoxDecoration(
            color: Color(0x66000000), // Semi-transparent overlay
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.1, // Adjust opacity to make it subtle
            child: Image.asset(
              'assets/images/appBg.png', // Replace with your paw pattern image
              repeat: ImageRepeat.repeat,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: CircleAvatar(
                  radius: MediaQuery.of(context).size.width * 0.4,
                  backgroundImage: widget.participantImageUrl.isNotEmpty
                    ? NetworkImage(widget.participantImageUrl)
                    : AssetImage(
                      widget.type == 'vet'
                        ? 'assets/images/vetProfile.png'
                        : 'assets/images/petOwnerProfile.png',
                    ) as ImageProvider,
                ),
                ),
              );
              },
              child: CircleAvatar(
              backgroundImage: widget.participantImageUrl.isNotEmpty
                ? NetworkImage(widget.participantImageUrl)
                : AssetImage(
                  widget.type == 'vet'
                    ? 'assets/images/vetProfile.png'
                    : 'assets/images/petOwnerProfile.png',
                  ) as ImageProvider,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.participantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Chats')
                        .doc(widget.chatId)
                        .get(),
                    builder: (context, chatSnapshot) {
                      if (chatSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox
                            .shrink(); // Or show a small loader
                      }

                      if (!chatSnapshot.hasData || !chatSnapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      final chatData =
                          chatSnapshot.data!.data() as Map<String, dynamic>;
                      final participants =
                          chatData['participants'] as List<dynamic>;
                      final otherUserId = _getOtherUserId(participants);

                      return StreamBuilder<Map<String, dynamic>>(
                        stream: _chatService.getTypingStatus(widget.chatId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return SizedBox.shrink();

                          final typingStatus = snapshot.data!;
                          final isTyping = typingStatus[otherUserId] ?? false;

                          if (!isTyping) return SizedBox.shrink();

                          return Text(
                            'Typing...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        flexibleSpace: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1, // Adjust opacity to make it subtle
                child: Image.asset(
                  'assets/images/appBg.png', // Replace with your paw pattern image
                  repeat: ImageRepeat.repeat,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _buildGradientBackground(), // Add the gradient background
          Column(
            children: [
              _buildMessageList(),
              _buildMessageInputBar(),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the list of messages
Widget _buildMessageList() {
  return Expanded(
    child: FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatId)
          .get(),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!chatSnapshot.hasData || !chatSnapshot.data!.exists) {
          return const Center(
            child: Text('Unable to load chat details.'),
          );
        }

        final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
        final participants = chatData['participants'] as List<dynamic>;
        final otherUserId = _getOtherUserId(participants);

        return StreamBuilder<QuerySnapshot>(
          stream: _chatService.getMessages(widget.chatId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No messages yet. Start the conversation!'),
              );
            }

            final messages = snapshot.data!.docs;

            return ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message =
                    messages[index].data() as Map<String, dynamic>;
                final isMe = message['senderId'] == _currentUserId;

                final timestamp = (message['timestamp'] is Timestamp)
                    ? (message['timestamp'] as Timestamp).toDate()
                    : DateTime.now();

                final readBy = message['readBy'] ?? [];

                // Determine if a date header is needed
                final showDateHeader = index == messages.length - 1 ||
                    !_isSameDate(
                        (messages[index + 1].data() as Map<String, dynamic>)['timestamp']
                            .toDate(),
                        timestamp);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showDateHeader)
                      _buildDateHeader(timestamp), // Add date header
                    _buildMessageBubble(
                      content: message['content'] ?? 'No content',
                      type: message['type'] ?? 'text',
                      isMe: isMe,
                      timestamp: timestamp,
                      readBy: readBy,
                      otherUserId: otherUserId,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ),
  );
}

bool _isSameDate(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

Widget _buildDateHeader(DateTime date) {
  final formattedDate = _formatDate(date);

  return Row(
    mainAxisAlignment: MainAxisAlignment.center, // Center the date header
    children: [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey, // Unique subtle background color
          borderRadius: BorderRadius.circular(12), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1), // Slight shadow below the bubble
            ),
          ],
        ),
        child: Text(
          formattedDate,
          style: const TextStyle(
            color: Colors.white, // Distinct text color
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}


String _formatDate(DateTime date) {
  final now = DateTime.now();
  if (_isSameDate(date, now)) {
    return 'Today';
  } else if (_isSameDate(date, now.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}



  /// Gets the other user's ID from the participants list
  String _getOtherUserId(List<dynamic> participants) {
    return participants.firstWhere((id) => id != _currentUserId);
  }

  /// Builds a single message bubble
  Widget _buildMessageBubble({
    required String content,
    required String type, // Add a 'type' parameter to distinguish media types
    required bool isMe,
    required DateTime timestamp,
    required List<dynamic> readBy,
    required String otherUserId,
  }) {
    IconData? statusIcon;
    Color iconColor = Colors.black54;

    // Determine the message status icon and color
    if (isMe) {
      final isReadByOtherUser = readBy.contains(otherUserId);

      if (isReadByOtherUser) {
        statusIcon = Icons.done_all; // Double tick for "read"
        iconColor = Colors.blue; // Blue for "read"
      } else {
        statusIcon = Icons.done_all; // Double tick for "delivered"
        iconColor = Colors.black54; // Gray for "delivered"
      }
    }

    Widget messageContent;

    // Determine the content type and render accordingly
    switch (type) {
      case 'image':
        messageContent = GestureDetector(
            onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                  Navigator.pop(context);
                  },
                ),
                ),
                backgroundColor: Colors.black,
                body: Center(
                child: InteractiveViewer(
                  child: Image.network(content),
                ),
                ),
              ),
              ),
            );
            },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              content,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        );
        break;

      case 'video':
        messageContent = GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerWidget(videoUrl: content),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9, // Maintain aspect ratio dynamically
                    child: VideoPlayerPreview(videoUrl: content),
                  ),
                  Container(
                    color: Colors.black
                        .withOpacity(0.3), // Semi-transparent overlay
                  ),
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 40, // Slightly larger play icon
                  ),
                ],
              ),
            ),
          ),
        );
        break;

      default: // 'text'
        messageContent = Text(
          content,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.start,
        );
        break;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.green : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 3), // Adds subtle shadow
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.75, // Limit bubble width
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            messageContent,
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min ,
              children: [
                Text(
                  TimeOfDay.fromDateTime(timestamp).format(context),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
                if (isMe && statusIcon != null) ...[
                  const SizedBox(width: 5),
                  Icon(
                    statusIcon,
                    size: 14,
                    color: iconColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.green),
              onPressed: _showMediaOptions, // Open media options
            ),
            Flexible(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Send a message...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                ),
                style: const TextStyle(color: Colors.black),
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.green),
              onPressed: _sendMessage, // Send message action
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.blue),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Take a Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.red),
                title: const Text('Record a Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final mediaUrl = await _uploadMediaToStorage(File(pickedFile.path));
        await _chatService.sendMediaMessage(widget.chatId, mediaUrl, 'image');
      }
    } catch (e) {
      print("Failed to pick media: $e");
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60), // Limit recording duration
      );

      if (pickedFile != null) {
        final mediaUrl = await _uploadMediaToStorage(File(pickedFile.path));
        await _chatService.sendMediaMessage(widget.chatId, mediaUrl, 'video');
      }
    } catch (e) {
      print("Failed to pick video: $e");
    }
  }

  Future<String> _uploadMediaToStorage(File file) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref =
          FirebaseStorage.instance.ref().child('chat_media').child(fileName);

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Failed to upload media: $e");
      rethrow;
    }
  }

  /// Sends a message
Future<void> _sendMessage() async {
  final content = _messageController.text.trim();
  if (content.isEmpty) return;

  _messageController.clear();

  // Assuming the other user's ID is fetched from the chat participants
  final chatDoc = await FirebaseFirestore.instance.collection('Chats').doc(widget.chatId).get();
  final participants = chatDoc['participants'] as List<dynamic>;
  final receiverId = _getOtherUserId(participants);


  
  await _chatService.sendMessageWithNotification(widget.chatId, content, receiverId);
}

}
