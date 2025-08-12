import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/storage.dart';
import '../chat_page.dart';

class ChatsListPage extends StatefulWidget {
  final String currentEmail;
  final bool isProfesor;
  const ChatsListPage({super.key, required this.currentEmail, required this.isProfesor});

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  bool _loading = true;
  List<_ChatInfo> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await Storage.getUsers();
    final me = users[widget.currentEmail] ?? {};
    final Map chats = me['chats'] ?? {};
    final items = <_ChatInfo>[];

    chats.forEach((key, value) {
      // key: chat_emailA_emailB
      final parts = key.toString().split('_');
      if (parts.length >= 3) {
        final a = parts[1];
        final b = parts[2];
        final partner = widget.currentEmail == a ? b : a;
        // intentar extraer último mensaje si existe
        String? lastText;
        String? lastTime;
        try {
          final list = jsonDecode(value) as List<dynamic>;
          if (list.isNotEmpty) {
            final last = Map<String, dynamic>.from(list.last);
            lastText = (last['texto'] ?? '').toString();
            lastTime = (last['fecha'] ?? '').toString();
          }
        } catch (_) {}
        items.add(_ChatInfo(key, partner, lastText, lastTime));
      }
    });

    // ordenar por última actividad desc
    items.sort((a, b) => (b.lastTime ?? '').compareTo(a.lastTime ?? ''));

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _openChat(String partnerEmail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          emailUsuario: widget.isProfesor ? partnerEmail : widget.currentEmail,
          emailProfesor: widget.isProfesor ? widget.currentEmail : partnerEmail,
          nombreProfesor: widget.isProfesor ? widget.currentEmail : partnerEmail,
          esProfesor: widget.isProfesor,
          nombreUsuario: widget.isProfesor ? partnerEmail : widget.currentEmail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis chats')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Aún no tienes chats.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final it = _items[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.forum_outlined),
                        title: Text(it.partnerEmail),
                        subtitle: Text(
                          it.lastText ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openChat(it.partnerEmail),
                      ),
                    );
                  },
                ),
    );
  }
}

class _ChatInfo {
  final String chatKey;
  final String partnerEmail;
  final String? lastText;
  final String? lastTime;
  _ChatInfo(this.chatKey, this.partnerEmail, this.lastText, this.lastTime);
}
