import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'Orderhistory.dart';
import 'homecontent screen.dart';
import 'user profile.dart';
import 'Chatscreen.dart';

class Homescreen extends StatefulWidget {
  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late List<Widget> _screens;
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _screens = [
      HomeContent(),
      OrderHistoryScreen(),
      ChatListScreen(userRole: _userRole),
    ];
  }

  Future<void> _loadUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userRole = doc.data()?['role'] ?? 'user';
        _screens = [
          HomeContent(),
          OrderHistoryScreen(),
          ChatListScreen(userRole: _userRole),
        ];
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chats'),
        ],
      ),
    );
  }
}

class ChatListScreen extends StatefulWidget {
  final String userRole;

  const ChatListScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final query = await _firestore.collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final chats = query.docs;
      final loadedConversations = <ChatConversation>[];

      for (final chat in chats) {
        final participants = chat['participants'] as List<dynamic>;
        final otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
          orElse: () => '',
        ).toString();

        if (otherUserId.isEmpty) continue;

        final otherUserDoc = await _firestore.collection('users')
            .doc(otherUserId)
            .get();

        loadedConversations.add(ChatConversation(
          chatId: chat.id,
          otherUserId: otherUserId,
          otherUserName: otherUserDoc['name'] ?? 'Unknown',
          otherUserImage: otherUserDoc['photoUrl'] ?? otherUserDoc['profileImage'] ?? '',
          lastMessage: chat['lastMessage'] ?? '',
          lastMessageTime: chat['lastMessageTime']?.toDate(),
        ));
      }

      setState(() {
        _conversations = loadedConversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load conversations: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Error loading conversations: $e');
    }
  }

  Future<void> _startNewChat(BuildContext context) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Show dialog to select user to chat with
    final usersSnapshot = await _firestore.collection('users')
        .where('role', isEqualTo: widget.userRole == 'user' ? 'tailor' : 'user')
        .get();

    final users = usersSnapshot.docs.where((doc) => doc.id != currentUserId).toList();

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No users available to chat with')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start new chat'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data();
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['photoUrl'] != null
                      ? NetworkImage(user['photoUrl'])
                      : null,
                  child: user['photoUrl'] == null
                      ? Icon(Icons.person)
                      : null,
                ),
                title: Text(user['name'] ?? 'Unknown'),
                onTap: () async {
                  Navigator.pop(context);
                  await _createNewChat(currentUserId, users[index].id, user['name'] ?? 'Unknown');
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _createNewChat(String currentUserId, String otherUserId, String otherUserName) async {
    try {
      // Generate consistent chat ID by sorting user IDs
      final participants = [currentUserId, otherUserId]..sort();
      final chatId = participants.join('_');

      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        await chatRef.set({
          'participants': participants,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': 'Chat started!',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

        // Add welcome message
        await chatRef.collection('messages').add({
          'text': 'Chat started!',
          'senderId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'text',
        });
      }

      // Navigate to chat screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              currentUserId: currentUserId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _startNewChat(context),
          ),
        ],
      ),
      body: _buildChatListBody(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.message),
        onPressed: () => _startNewChat(context),
      ),
    );
  }

  Widget _buildChatListBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading conversations...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversations,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No conversations yet'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _startNewChat(context),
              child: Text('Start New Chat'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final chat = _conversations[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: chat.otherUserImage.isNotEmpty
                    ? NetworkImage(chat.otherUserImage)
                    : null,
                child: chat.otherUserImage.isEmpty
                    ? Icon(Icons.person)
                    : null,
              ),
              title: Text(chat.otherUserName),
              subtitle: Text(
                chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: chat.lastMessageTime != null
                  ? Text(DateFormat('MMM dd').format(chat.lastMessageTime!))
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chat.chatId,
                      otherUserId: chat.otherUserId,
                      otherUserName: chat.otherUserName,
                      currentUserId: _auth.currentUser?.uid ?? '',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ChatConversation {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;
  final String lastMessage;
  final DateTime? lastMessageTime;

  ChatConversation({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
    required this.lastMessage,
    this.lastMessageTime,
  });
}