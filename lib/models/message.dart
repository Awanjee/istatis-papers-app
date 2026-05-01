enum MessageRole { user, assistant }

class Message {
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  Message({required this.content, required this.role, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}
