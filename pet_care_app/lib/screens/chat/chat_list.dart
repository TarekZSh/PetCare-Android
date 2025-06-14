import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/screens/chat/chat_screen.dart';
import 'package:pet_care_app/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:pet_care_app/screens/chat/chatbot_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String searchQuery = '';
  final Map<String, Map<String, dynamic>> participantCache =
      {}; // Cache for participant data
  ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          _buildGradientBackground(),
          Column(
            children: [
              const SizedBox(height: 20),
              _buildSearchField(size),
              _buildChatList(),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openChatbotScreen,
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'Chat with AI',
        child: SvgPicture.asset(
          'assets/icons/magic_wand.svg',
          width: 40,
          height: 40,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _openChatbotScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotScreen(),
      ),
    );
  }

  /// Builds the gradient background.
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
      ],
    );
  }

  /// Builds the search field.
  Widget _buildSearchField(Size size) {
    return Container(
      margin: EdgeInsets.symmetric(
          vertical: size.height * 0.02, horizontal: size.width * 0.05),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04, vertical: size.height * 0.005),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
          ),
          // IconButton(
          //   icon: const Icon(Icons.filter_list, color: Colors.white, size: 24),
          //   onPressed: () {
          //     // Placeholder for filter functionality
          //     print('Filter button pressed');
          //   },
          // ),
        ],
      ),
    );
  }

  /// Builds the chat list.
  Widget _buildChatList() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.petOwner?.id ?? authProvider.vet?.id;

    if (currentUserId == null) {
      return const Center(
        child: Text(
          'Please log in to view chats',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No active chats',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Filter chats based on searchQuery
          final chats = snapshot.data!.docs.where((chatDoc) {
            final chatData = chatDoc.data() as Map<String, dynamic>;
            final participants = chatData['participants'] as List<dynamic>;
            final otherParticipantIds =
                participants.where((id) => id != currentUserId).toList();

            // Check if the participantCache is ready
            final otherParticipants = otherParticipantIds.map((id) {
              return participantCache.containsKey(id)
                  ? participantCache[id]!['name'] as String
                  : '';
            }).join(', ');

            return otherParticipants
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
          }).toList();

          return FutureBuilder<void>(
            future:
                _preFetchParticipantDetails(snapshot.data!.docs, currentUserId),
            builder: (context, participantSnapshot) {
              if (participantSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return _buildChatTile(chat, currentUserId);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _preFetchParticipantDetails(
      List<QueryDocumentSnapshot> chats, String currentUserId) async {
    // Extract participant IDs excluding the current user
    final participantIds = chats
        .map((chat) {
          final data = chat.data() as Map<String, dynamic>;
          final participants = data['participants'] as List<dynamic>;
          return participants.firstWhere((id) => id != currentUserId,
              orElse: () => null);
        })
        .where((id) => id != null && !participantCache.containsKey(id))
        .toSet();

    if (participantIds.isEmpty) return;

    // Fetch details for each participant
    for (var participantId in participantIds) {
      if (!participantCache.containsKey(participantId)) {
        try {
          // Check in pet_owners collection
          final petOwnerDoc = await FirebaseFirestore.instance
              .collection('pet_owners')
              .doc(participantId)
              .get();

          if (petOwnerDoc.exists) {
            participantCache[participantId!] = {
              ...petOwnerDoc.data()!,
              'type': 'pet_owner',
            };
            continue;
          }

          // Check in vets collection
          final vetDoc = await FirebaseFirestore.instance
              .collection('vets')
              .doc(participantId)
              .get();

          if (vetDoc.exists) {
            participantCache[participantId!] = {
              ...vetDoc.data()!,
              'type': 'vet',
            };
          }
        } catch (e) {
          print('Failed to fetch participant details for $participantId: $e');
        }
      }
    }
  }

/// Builds a single chat tile.
Widget _buildChatTile(QueryDocumentSnapshot chat, String currentUserId) {
  final chatData = chat.data() as Map<String, dynamic>;

  // Safely handle the timestamp field
  final timestamp = chatData['timestamp'] is Timestamp
      ? (chatData['timestamp'] as Timestamp).toDate()
      : DateTime.now(); // Fallback to current time if not a valid Timestamp

  final participants = chatData['participants'] as List<dynamic>;
  final otherParticipantId = participants
      .firstWhere((id) => id != currentUserId, orElse: () => null);

  if (otherParticipantId == null ||
      !participantCache.containsKey(otherParticipantId)) {
    return const ListTile(
      title: Text('Loading participant...'),
    );
  }

  final participantData = participantCache[otherParticipantId];
  final name = participantData?['name'] ?? 'Unknown User';
  final imageUrl = participantData?['profileImageUrl'] ??
      participantData?['imageUrl'] ??
      '';
  final unreadCount = chatData['unreadCount']?[currentUserId] ?? 0;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    child: Dismissible(
      key: Key(chat.id), // Unique key for each chat
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _confirmDeleteChat(context);
      },
      onDismissed: (direction) async {
        try {
          await _chatService.deleteChat(chat.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat deleted successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete chat: $e')),
          );
        }
      },
      child: Card(
        color: Colors.white.withOpacity(0.9),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : AssetImage(
                        participantData?['type'] == 'vet'
                            ? 'assets/images/vetProfile.png'
                            : 'assets/images/petOwnerProfile.png',
                      ) as ImageProvider,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            chatData['lastMessage']?.isNotEmpty == true
                ? chatData['lastMessage']
                : 'No messages yet',
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chat.id,
                  participantName: name,
                  participantImageUrl: imageUrl,
                  type: participantData?['type'],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// Confirmation dialog for deleting a chat.
Future<bool?> _confirmDeleteChat(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

}
