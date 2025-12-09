import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmmarket/services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String? peerName;

  const ChatScreen({super.key, this.chatId, this.peerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Current user id from Supabase Auth
  String? _currentUserId;

  late String _chatId;
  String? _peerName;
  String? _peerId;
  bool _initializedFromArgs = false;

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId ?? 'demoChatId';
    _peerName = widget.peerName;
    _currentUserId = SupabaseService.currentUserId;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final argChatId = args['chatId'] as String?;
      final argPeerName = args['peerName'] as String?;
      final argPeerId = args['peerId'] as String?;
      if (argChatId != null && argChatId.isNotEmpty) {
        _chatId = argChatId;
      }
      if (argPeerName != null && argPeerName.isNotEmpty) {
        _peerName = argPeerName;
      }
      if (argPeerId != null && argPeerId.isNotEmpty) {
        _peerId = argPeerId;
      }
    }
    _initializedFromArgs = true;
  }

  RealtimeChannel? _channel;
  Stream<List<Map<String, dynamic>>> get _messagesStream {
    final client = Supabase.instance.client;
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', _chatId)
        .order('created_at', ascending: true)
        .map((rows) => rows
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList());
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final client = Supabase.instance.client;
    _currentUserId ??= SupabaseService.currentUserId;
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send messages')),
      );
      return;
    }

    // Insert message
    await client.from('messages').insert({
      'chat_id': _chatId,
      'sender_id': _currentUserId,
      'text': text,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Update chat summary (ensure both participants are included)
    await client.from('chats').upsert({
      'id': _chatId,
      'last_message': text,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'participants': [
        _currentUserId,
        if (_peerId != null) _peerId,
      ],
      'peer_name': _peerName,
    });

    // Scroll to bottom
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_peerName ?? 'Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final isMe = data['sender_id'] == _currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(
                            color: isMe
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
