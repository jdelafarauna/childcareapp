import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/storage.dart';

class ChatPage extends StatefulWidget {
  final String emailUsuario;
  final String emailProfesor;
  final String nombreProfesor;
  final bool esProfesor;
  final String? nombreUsuario;

  const ChatPage({
    super.key,
    required this.emailUsuario,
    required this.emailProfesor,
    required this.nombreProfesor,
    this.esProfesor = false,
    this.nombreUsuario,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _chat = [];
  final TextEditingController _mensajeCtrl = TextEditingController();
  bool _loading = true;

  String get chatKey {
    final sortedEmails = [widget.emailUsuario, widget.emailProfesor]..sort();
    return 'chat_${sortedEmails[0]}_${sortedEmails[1]}';
  }

  Future<Map<String, dynamic>> _getUsers() => Storage.getUsers();

  Future<void> _loadChat() async {
    final users = await _getUsers();
    final base = users[widget.esProfesor ? widget.emailProfesor : widget.emailUsuario] ?? {};
    final chats = base['chats'] ?? {};
    final chatStr = chats[chatKey];

    if (chatStr != null && chatStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(chatStr);
        _chat = decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {
        _chat = [];
      }
    } else {
      _chat = [];
    }
    setState(() => _loading = false);
  }

  Future<void> _saveChat() async {
    final users = await _getUsers();
    final emailA = widget.esProfesor ? widget.emailProfesor : widget.emailUsuario;
    final emailB = widget.esProfesor ? widget.emailUsuario : widget.emailProfesor;
    final chatStr = jsonEncode(_chat);

    users[emailA] ??= {};
    users[emailA]['chats'] ??= {};
    users[emailA]['chats'][chatKey] = chatStr;

    users[emailB] ??= {};
    users[emailB]['chats'] ??= {};
    users[emailB]['chats'][chatKey] = chatStr;

    await Storage.saveUsers(users);
  }

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  void _send() async {
    final txt = _mensajeCtrl.text.trim();
    if (txt.isEmpty) return;
    final msg = {
      'emisor': widget.esProfesor ? 'profesor' : 'usuario',
      'texto': txt,
      'fecha': DateTime.now().toIso8601String(),
    };
    setState(() {
      _chat.add(msg);
      _mensajeCtrl.clear();
    });
    await _saveChat();
  }

  Widget _bubble(Map<String, dynamic> m) {
    final esEmisor = (widget.esProfesor && m['emisor'] == 'profesor') ||
        (!widget.esProfesor && m['emisor'] == 'usuario');
    final align = esEmisor ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = esEmisor ? Colors.blue[300] : Colors.grey[300];
    final fg = esEmisor ? Colors.white : Colors.black87;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Text(m['texto'], style: TextStyle(color: fg)),
          ),
          Text(
            DateTime.parse(m['fecha']).toLocal().toString().substring(0, 16),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text('Chat con ${widget.nombreProfesor}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _chat.length,
              itemBuilder: (_, i) => _bubble(_chat[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _send, child: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
