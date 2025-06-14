import 'package:flutter/material.dart';
import 'package:pet_care_app/services/chat_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatService _chatService = ChatService();
  final Logger _logger = Logger();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = [];
  bool _isBotTyping = false; // To track bot's typing status
  Map<String, dynamic>? _userContext; // Store user context

  @override
  void initState() {
    super.initState();
    _initializeUserContext(); // Fetch user context during initialization
  }

  Future<void> _initializeUserContext() async {
    try {
      // Access AuthProvider using context
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Determine user role and fetch context directly from AuthProvider
      if (authProvider.petOwner != null) {
        final petOwner = authProvider.petOwner!;
        setState(() {
          _userContext = {
            'role': 'petOwner',
            'name': petOwner.name,
            'pets': petOwner.pets
                .map((pet) => pet.toMap())
                .toList(), // Use existing pets data
          };
        });
        _logger.i(
            'User context for pet owner initialized with existing pet data.');
      } else if (authProvider.vet != null) {
        final vet = authProvider.vet!;
        setState(() {
          _userContext = {
            'role': 'vet',
            'name': vet.name,
            'specializations': vet.specializations,
            'patients': vet.patients
                .map((pet) => pet.toMap())
                .toList(), // Use existing patients data
          };
        });
        _logger
            .i('User context for vet initialized with existing patient data.');
      } else {
        _logger.e('No authenticated user found in AuthProvider.');
      }
    } catch (e) {
      _logger.e('Failed to initialize user context: $e');
    }
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isEmpty) {
      _logger.w('Empty message, not sending.');
      return;
    }

    // Add user message to the chat
    setState(() {
      _messages.add({'sender': 'user', 'text': message});
      _controller.clear();
      _isBotTyping = true; // Show typing indicator
    });

    _logger.i('Sending message: $message');

    try {
      // Include user context in the chatbot API call
      String botResponse = await _chatService.getResponseFromGemini(
        message,
        context: _userContext, // Pass the user context
      );
      _logger.i('Received chatbot response: $botResponse');

      // Add chatbot response to the chat
      setState(() {
        _messages.add({'sender': 'bot', 'text': botResponse});
        _isBotTyping = false; // Hide typing indicator
      });
    } catch (e) {
      _logger.e('Failed to fetch chatbot response: $e');
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Something went wrong. Please try again later.'
        });
        _isBotTyping = false; // Hide typing indicator
      });
    }
  }

  // Rest of the widget code remains the same...

  Widget _buildTypingIndicator() {
    if (!_isBotTyping) return SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.shade300,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TypingAnimation(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Expanded(
      child: ListView.builder(
        reverse: true, // Start from the bottom (latest messages)
        itemCount: _messages.length +
            (_isBotTyping ? 1 : 0), // Include typing indicator
        itemBuilder: (context, index) {
          // Show typing indicator if it's the last item
          if (_isBotTyping && index == 0) {
            return _buildTypingIndicator();
          }

          // Reverse the index to display the latest message at the bottom
          final message = _messages[
              _messages.length - 1 - (index - (_isBotTyping ? 1 : 0))];

          return Align(
            alignment: message['sender'] == 'user'
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message['sender'] == 'user' ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: message['sender'] == 'user'
                      ? const Radius.circular(12)
                      : const Radius.circular(0),
                  bottomRight: message['sender'] == 'user'
                      ? const Radius.circular(0)
                      : const Radius.circular(12),
                ),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: message['sender'] == 'user'
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message['text'] ?? 'No content',
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                          color: Colors.white), // Customize the text color
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TimeOfDay.now().format(context), // Display the current time
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInputBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
          children: [
            Flexible(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Ask something...',
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
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                      backgroundImage:
                          AssetImage('assets/images/pawHelper1.png'),
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/pawHelper1.png'),
                radius: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'PawHelper',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        flexibleSpace: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1, // Subtle background pattern
                child: Image.asset(
                  'assets/images/appBg.png', // Paw pattern or other background
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
          _buildGradientBackground(),
          Column(
            children: [
              Expanded(child: _buildMessageList()),
              _buildMessageInputBar(),
            ],
          ),
        ],
      ),
    );
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
}

class TypingAnimation extends StatefulWidget {
  @override
  _TypingAnimationState createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<TypingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return FadeTransition(
          opacity: _animation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: CircleAvatar(
              radius: 4.0,
              backgroundColor: Colors.white,
            ),
          ),
        );
      }),
    );
  }
}
