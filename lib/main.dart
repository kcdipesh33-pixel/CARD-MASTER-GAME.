import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(const CardMaster());

class CardMaster extends StatelessWidget {
  const CardMaster({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CARD MASTER',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CARD MASTER')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            const Text('OFFLINE MULTIPLAYER'),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HostPage()),
              ),
              child: const Text('HOST MODE'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerPage()),
              ),
              child: const Text('PLAYER MODE'),
            ),
          ],
        ),
      ),
    );
  }
}

class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  final pin = TextEditingController();
  final players = <String, WebSocketChannel>{};
  HttpServer? server;
  String roomCode = '';
  String status = 'Host password: 0692';
  bool unlocked = false;

  Future<void> startServer() async {
    try {
      roomCode = (100000 + Random().nextInt(900000)).toString();

      server = await shelf_io.serve(
        webSocketHandler((socket) {
          String? playerId;

          socket.stream.listen((message) {
            try {
              final data = jsonDecode(message);
              if (data['type'] == 'join') {
                if (data['code'] != roomCode) {
                  socket.sink.add(jsonEncode({
                    'type': 'error',
                    'message': 'Wrong room code',
                  }));
                  socket.sink.close();
                  return;
                }

                if (players.length >= 8) {
                  socket.sink.add(jsonEncode({
                    'type': 'error',
                    'message': 'Room is full',
                  }));
                  socket.sink.close();
                  return;
                }

                playerId =
                    '${DateTime.now().microsecondsSinceEpoch}';
                players[playerId!] = socket;
                socket.sink.add(jsonEncode({
                  'type': 'joined',
                  'id': playerId,
                  'room': roomCode,
                }));
                broadcastPlayers();
              }
            } catch (_) {}
          }, onDone: () {
            if (playerId != null) {
              players.remove(playerId);
              broadcastPlayers();
            }
          });
        }),
        InternetAddress.anyIPv4,
        8765,
      );

      setState(() => status =
          'Server running on port 8765. Share room code: $roomCode');
    } catch (e) {
      setState(() => status = 'Server error: $e');
    }
  }

  void broadcastPlayers() {
    final message = jsonEncode({
      'type': 'players',
      'players': players.keys.toList(),
    });
    for (final socket in players.values) {
      socket.sink.add(message);
    }
    if (mounted) setState(() {});
  }

  void kick(String id) {
    final socket = players.remove(id);
    socket?.sink.add(jsonEncode({'type': 'kicked'}));
    socket?.sink.close();
    broadcastPlayers();
  }

  @override
  void dispose() {
    for (final socket in players.values) {
      socket.sink.close();
    }
    server?.close(force: true);
    pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HOST CONTROL')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: !unlocked
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: pin,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Host Password',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (pin.text == '0692') {
                        setState(() => unlocked = true);
                      } else {
                        setState(() => status = 'Wrong password');
                      }
                    },
                    child: const Text('UNLOCK'),
                  ),
                  Text(status),
                ],
              )
            : ListView(
                children: [
                  ElevatedButton(
                    onPressed: server == null ? startServer : null,
                    child: const Text('START HOST SERVER'),
                  ),
                  SelectableText('Room Code: $roomCode'),
                  SelectableText(status),
                  Text('Players connected: ${players.length}/8'),
                  ...players.keys.map((id) => ListTile(
                        title: Text('Player ${id.substring(id.length - 5)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_remove,
                              color: Colors.red),
                          onPressed: () => kick(id),
                        ),
                      )),
                ],
              ),
      ),
    );
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final name = TextEditingController();
  final code = TextEditingController();
  final address = TextEditingController();
  WebSocketChannel? channel;
  String status = 'Enter host address and room code';
  bool connected = false;

  void join() {
    try {
      final host = address.text.trim();
      final uri = Uri.parse(
        host.startsWith('ws://') ? host : 'ws://$host:8765',
      );
      channel = WebSocketChannel.connect(uri);

      channel!.stream.listen((message) {
        final data = jsonDecode(message);

        if (data['type'] == 'joined') {
          setState(() {
            connected = true;
            status = 'Connected to room ${data['room']}';
          });
        } else if (data['type'] == 'kicked') {
          setState(() {
            connected = false;
            status = 'You were kicked by Host';
          });
          channel?.sink.close();
        } else if (data['type'] == 'error') {
          setState(() => status = data['message']);
        }
      }, onError: (e) {
        setState(() => status = 'Connection failed: $e');
      });

      channel!.sink.add(jsonEncode({
        'type': 'join',
        'name': name.text.trim(),
        'code': code.text.trim(),
      }));
      setState(() => status = 'Connecting...');
    } catch (e) {
      setState(() => status = 'Connection error: $e');
    }
  }

  @override
  void dispose() {
    channel?.sink.close();
    name.dispose();
    code.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PLAYER MODE')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Player Name'),
            ),
            TextField(
              controller: address,
              decoration: const InputDecoration(
                labelText: 'Host IP (example 192.168.43.1)',
              ),
            ),
            TextField(
              controller: code,
              decoration: const InputDecoration(labelText: 'Room Code'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: connected ? null : join,
              child: const Text('JOIN ROOM'),
            ),
            Text(status),
          ],
        ),
      ),
    );
  }
}
