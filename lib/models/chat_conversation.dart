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