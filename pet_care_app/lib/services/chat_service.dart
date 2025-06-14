import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();
  final String _apiKey =
      'AIzaSyCbxJEVMB0FHdIKLNNCl717nMWUw5ZLqTQ'; // Replace with your API key
  //final String _geminiEndpoint = 'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateText';
  final String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent';

 Future<String> getResponseFromGemini(String userMessage, {Map<String, dynamic>? context}) async {
  _logger.i('Sending message to Gemini: $userMessage with context: $context');

  try {
    // Generate a detailed context description with a role-specific prompt
    final String contextDescription = context != null
        ? _buildDetailedContextDescription(context)
        : 'No additional context provided.';

    // Include the system prompt and user message
    final fullMessage = '$contextDescription\nUser Message: $userMessage';

    final response = await http.post(
      Uri.parse('$_geminiEndpoint?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': fullMessage}
            ]
          }
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 200}
      }),
    );

    _logger.i('Received response status: ${response.statusCode}');
    _logger.d('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey('candidates') &&
          data['candidates'][0]['content']['parts'].isNotEmpty) {
        String aiResponse =
            data['candidates'][0]['content']['parts'][0]['text'];
        _logger.i('AI Response: $aiResponse');
        return aiResponse;
      } else {
        _logger.e('Unexpected response format: $data');
        return 'The AI responded in an unexpected format. Please try again later or contact support if the issue persists.';
      }
    } else {
      _logger.e('Error response: ${response.body}');

      String errorMessage;
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['error']['message'] ?? 'Unknown error';
      } catch (_) {
        errorMessage =
            'An unknown error occurred while processing the response.';
      }

      return 'Failed to process your request. Error Code: ${response.statusCode}, Message: $errorMessage. Please try again later.';
    }
  } catch (e) {
    _logger.e('Failed to connect to Gemini AI: $e');
    return 'Connection to the AI service failed. Please check your network connection and try again.';
  }
}

String _buildDetailedContextDescription(Map<String, dynamic> context) {
  final StringBuffer description = StringBuffer();

  // Add a role-specific system instruction
  final String role = context['role'];
  if (role == 'petOwner') {
    description.writeln(
        'You are assisting a pet owner. Help them take care of their pets by providing information on health, vaccinations, medical history, and care tips.');
  } else if (role == 'vet') {
    description.writeln(
        'You are assisting a veterinarian. Support them with their patients by providing insights on medical histories, treatments, and patient management.');
  } else {
    description.writeln(
        'You are a helpful assistant for pet-related tasks. Provide general information and assistance about pets.');
  }

  // Add user details
  description.writeln('User Role: $role');
  description.writeln('User Name: ${context['name']}');

  // Add pet or patient details based on the role
  if (role == 'petOwner' && context.containsKey('pets')) {
    description.writeln('Pets:');
    for (var pet in context['pets']) {
      description.writeln('- ${pet['name']} (${pet['species']}):');
      description.writeln('  - Breed: ${pet['breed']}');
      description.writeln('  - Medical History: ${pet['medicalHistory']}');
      description.writeln('  - Vaccinations: ${pet['vaccinations']}');
      description.writeln('  - Special Notes: ${pet['specialNotes']}');
      description.writeln('  - Preferences: ${pet['preferences']}');
    }
  } else if (role == 'vet' && context.containsKey('patients')) {
    description.writeln('Patients:');
    for (var patient in context['patients']) {
      description.writeln('- ${patient['name']} (${patient['species']}):');
      description.writeln('  - Breed: ${patient['breed']}');
      description.writeln('  - Medical History: ${patient['medicalHistory']}');
      description.writeln('  - Vaccinations: ${patient['vaccinations']}');
      description.writeln('  - Special Notes: ${patient['specialNotes']}');
      description.writeln('  - Preferences: ${patient['preferences']}');
    }
  }

  return description.toString();
}


  /// Upload a file (image or video) to Firebase Storage
  Future<void> sendMediaMessage(
      String chatId, String mediaUrl, String type) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      await _firestore.collection('Messages').add({
        'chatId': chatId,
        'senderId': userId,
        'content': mediaUrl,
        'type': type, // 'image', 'video', etc.
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [userId],
      });

      // Update chat with the last message info
      await _firestore.collection('Chats').doc(chatId).update({
        'lastMessage': 'Media file sent',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Failed to send media message: $e");
      rethrow;
    }
  }

  /// Create a new chat
  Future<String> createChat(List<String> participants) async {
    try {
      final chatRef = await _firestore.collection('Chats').add({
        'participants': participants,
        'lastMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
        'unreadCount': {
          for (var participant in participants)
            participant: 0, // Initialize unread count for all participants
        },
      });
      return chatRef.id; // Returns the ID of the created chat
    } catch (e) {
      print("Failed to create chat: $e");
      rethrow;
    }
  }

  Future<void> sendMessageWithNotification(
      String chatId, String content, String receiverId) async {
    try {
      await sendMessage(chatId, content); // Send the message

      String senderName;
      // Fetch the sender's name from Firestore
      final userDoc = await _firestore.collection('vets').doc(_auth.currentUser!.uid).get();
      if (userDoc.exists) {
        senderName = userDoc.data()?['name'] ?? 'Unknown Vet';
      } else {
        final petOwnerDoc = await _firestore.collection('pet_owners').doc(_auth.currentUser!.uid).get();
        if (petOwnerDoc.exists) {
          senderName = petOwnerDoc.data()?['name'] ?? 'Unknown Pet Owner';
        } else {
          senderName = 'Unknown User';
        }
      }
      // Fetch the receiver's device token
      final receiverDoc =
          await _firestore.collection('users').doc(receiverId).get();
      final deviceToken = receiverDoc.data()?['deviceToken'];

      if (deviceToken != null) {
        await sendPushNotification(
            deviceToken, content, chatId, senderName); // Send the push notification
      }
    } catch (e) {
      print('Error sending message with notification: $e');
    }
  }

  Future<void> sendPushNotification(
      String token, String message, String chatId, String senderName) async {
    const String projectId =
        'petcare-31013'; // Replace with your Firebase project ID
    final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

    // Path to your service account JSON key
    final serviceAccountKey =
        await rootBundle.loadString('assets/keys/keys-chat.json');
    ;

    final serviceAccount = jsonDecode(serviceAccountKey);

    final accountCredentials =
        ServiceAccountCredentials.fromJson(serviceAccount);

    // Obtain an OAuth 2 access token
    final client = await clientViaServiceAccount(accountCredentials, [
      'https://www.googleapis.com/auth/firebase.messaging',
    ]);

    // Prepare the notification payload
    final body = jsonEncode({
      'message': {
        'token': token,
        'notification': {
          'title': 'You recieved a new message from $senderName',
          'body': message,
        },
        'data': {
          'chatId': chatId,
        },
      },
    });

    // Send the notification
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      print('Push notification sent successfully!');
    } else {
      print('Failed to send push notification: ${response.body}');
    }

    client.close(); // Close the HTTP client
  }

  Future<void> sendMessage(String chatId, String content) async {
    if (content.trim().isEmpty)
      throw Exception("Message content cannot be empty");

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      // Add a new message with the sender's ID in `readBy`
      await _firestore.collection('Messages').add({
        'chatId': chatId,
        'senderId': userId,
        'content': content.trim(),
        'type': 'text', // Default type
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [userId], // Include the sender's ID
        'status': 'sent', // Default status
      });

      // Update the chat document with the latest message
      final chatDoc = await _firestore.collection('Chats').doc(chatId).get();
      final unreadCount = chatDoc.data()?['unreadCount'] ?? {};

      // Increment unread count for all participants except the sender
      for (var participant in unreadCount.keys) {
        if (participant != userId) {
          unreadCount[participant] = (unreadCount[participant] ?? 0) + 1;
        }
      }

      await _firestore.collection('Chats').doc(chatId).update({
        'lastMessage': content.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'unreadCount': unreadCount,
      });
    } catch (e) {
      print("Failed to send message in chat $chatId: $e");
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      // Optimistically reset unread count locally
      await _firestore.collection('Chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });

      // Update messages in the background
      final unreadMessages = await _firestore
          .collection('Messages')
          .where('chatId', isEqualTo: chatId)
          .where('readBy', arrayContains: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
      await batch.commit();
    } catch (e) {
      print("Failed to mark messages as read: $e");
      rethrow;
    }
  }

  Future<void> deleteChat(String chatId) async {
  try {
    // Delete all messages associated with the chat
    final messagesSnapshot = await _firestore
        .collection('Messages')
        .where('chatId', isEqualTo: chatId)
        .get();
    for (var messageDoc in messagesSnapshot.docs) {
      await messageDoc.reference.delete();
    }

    // Delete the chat document itself
    await _firestore.collection('Chats').doc(chatId).delete();
  } catch (e) {
    _logger.e('Failed to delete chat: $e');
    rethrow;
  }
}


  /// Fetch chats for the current user
  Stream<QuerySnapshot> getUserChats() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      return _firestore
          .collection('Chats')
          .where('participants', arrayContains: userId)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      print("Failed to fetch user chats: $e");
      return const Stream.empty();
    }
  }

  /// Fetch messages in a chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    try {
      return _firestore
          .collection('Messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      print("Failed to fetch messages: $e");
      return const Stream.empty();
    }
  }

  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("User not logged in");
      }

      // Update typing status with merge to avoid overwriting other data
      await _firestore.collection('Chats').doc(chatId).set(
        {
          'typing': {userId: isTyping},
        },
        SetOptions(
            merge: true), // Use merge to prevent overwriting other fields
      );
    } catch (e) {
      print('Failed to set typing status for chat $chatId: $e');
    }
  }

  Stream<Map<String, dynamic>> getTypingStatus(String chatId) {
    return _firestore
        .collection('Chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        print('Chat document does not exist: $chatId');
        return {};
      }

      final data = snapshot.data();
      if (data == null) {
        print('No data found in chat document: $chatId');
        return {};
      }

      final typingStatus = data['typing'];
      if (typingStatus is Map<String, dynamic>) {
        return typingStatus;
      } else {
        print('Invalid typing status format in chat document: $chatId');
        return {};
      }
    });
  }
}
