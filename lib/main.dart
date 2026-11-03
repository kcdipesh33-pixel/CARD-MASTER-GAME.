import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(const CardMasterApp());

class CardMasterApp extends StatelessWidget {
  const CardMasterApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CARD MASTER',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.amber,
        brightness: Brightness.dark,
      ),
    ),
    home: const HomePage(),
  );
}

class PlayingCard {
  final String id;
  final String rank;
  final String suit;
  final bool joker;

  PlayingCard(this.id, this.rank, this.suit, {this.joker = false});

  String get label => joker ? 'JOKER' : '$rank$suit';

  Map<String, dynamic> toJson() => {
    'id': id,
    'rank': rank,
    'suit': suit,
    'joker': joker,
  };

  factory PlayingCard.fromJson(Map m) => PlayingCard(
    m['id'],
    m['rank'],
    m['suit'],
    joker: m['joker'] == true,
  );
}

class PlayerState {
  final String id;
  final String name;
  List<PlayingCard> hand = [];
  bool ready = false;
  bool shown = false;

  PlayerState(this.id, this.name);

  Map<String, dynamic> publicJson() => {
    'id': id,
    'name': name,
    'count': hand.length,
    'ready': ready,
    'shown': shown,
  };
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('CARD MASTER'), centerTitle: true),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.style, size: 92, color: Colors.amber),
          const SizedBox(height: 16),
          const Text('OFFLINE MULTIPLAYER • UP TO 8 PLAYERS'),
          const SizedBox(height: 30),
          SizedBox(
            width: 230,
            child: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HostPage()),
              ),
              child: const Text('HOST MODE'),
            ),
          ),
          SizedBox(
            width: 230,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinPage()),
              ),
              child: const Text('PLAYER MODE'),
            ),
          ),
        ],
      ),
    ),
  );
}

class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  final pin = TextEditingController();
  final Random rng = Random.secure();

  HttpServer? server;

  final Map<String, WebSocketChannel> sockets = {};
  final Map<String, PlayerState> players = {};

  List<PlayingCard> deck = [];
  List<PlayingCard> hostHand = [];

  final Set<String> drawRequests = {};

  String room = '';
  String status = 'Password: 0692';

  bool unlocked = false;
  bool started = false;
  bool winPending = false;

  String? winnerRequest;
  String? currentWinner;

  void send(WebSocketChannel socket, Map<String, dynamic> data) {
    try {
      socket.sink.add(jsonEncode(data));
    } catch (_) {}
  }

  void sendPlayer(String id, Map<String, dynamic> data) {
    final socket = sockets[id];
    if (socket != null) send(socket, data);
  }

  void broadcast(Map<String, dynamic> data) {
    for (final socket in sockets.values) {
      send(socket, data);
    }
  }

  List<Map<String, dynamic>> get roster =>
      players.values.map((p) => p.publicJson()).toList();

  void stateToPlayers() {
    broadcast({
      'type': 'state',
      'players': roster,
      'started': started,
      'winPending': winPending,
      'winnerRequest': winnerRequest,
      'winner': currentWinner,
    });

    for (final entry in players.entries) {
      sendPlayer(entry.key, {
        'type': 'private_hand',
        'hand': entry.value.hand.map((c) => c.toJson()).toList(),
      });
    }
  }

  Future<void> startServer() async {
    try {
      room = (100000 + rng.nextInt(900000)).toString();

      server = await shelf_io.serve(
        webSocketHandler((WebSocketChannel socket) {
          String? playerId;

          socket.stream.listen(
            (raw) {
              try {
                final data =
                    jsonDecode(raw as String) as Map<String, dynamic>;

                if (data['type'] == 'join') {
                  if (playerId != null) return;

                  if (data['code'] != room) {
                    send(socket, {
                      'type': 'error',
                      'message': 'Wrong room code',
                    });
                    socket.sink.close();
                    return;
                  }

                  if (players.length >= 8) {
                    send(socket, {
                      'type': 'error',
                      'message': 'Room is full',
                    });
                    socket.sink.close();
                    return;
                  }

                  final name = (data['name'] ?? '').toString().trim();

                  if (name.isEmpty || name.length > 18) {
                    send(socket, {
                      'type': 'error',
                      'message': 'Enter a name (1–18 characters)',
                    });
                    socket.sink.close();
                    return;
                  }

                  if (players.values.any(
                    (p) => p.name.toLowerCase() == name.toLowerCase(),
                  )) {
                    send(socket, {
                      'type': 'error',
                      'message': 'Name already used',
                    });
                    socket.sink.close();
                    return;
                  }

                  playerId =
                      '${DateTime.now().microsecondsSinceEpoch}${rng.nextInt(999)}';

                  sockets[playerId!] = socket;
                  players[playerId!] = PlayerState(playerId!, name);

                  send(socket, {
                    'type': 'joined',
                    'id': playerId,
                    'room': room,
                  });

                  stateToPlayers();

                  if (mounted) {
                    setState(() => status = '$name joined');
                  }
                } else if (playerId != null &&
                    players.containsKey(playerId)) {
                  handlePlayer(playerId!, data);
                }
              } catch (_) {}
            },
            onDone: () {
              if (playerId != null) {
                sockets.remove(playerId);
                players.remove(playerId);
                drawRequests.remove(playerId);

                if (winnerRequest == playerId) {
                  winnerRequest = null;
                  winPending = false;
                }

                stateToPlayers();

                if (mounted) {
                  setState(() => status = 'A player disconnected');
                }
              }
            },
          );
        }),
        InternetAddress.anyIPv4,
        8765,
      );

      if (mounted) {
        setState(() => status = 'Server running • Port 8765');
      }
    } catch (e) {
      if (mounted) setState(() => status = 'Server error: $e');
    }
  }

  void handlePlayer(String id, Map<String, dynamic> data) {
    final player = players[id]!;
    final type = data['type'];

    if (type == 'leave') {
      sockets.remove(id);
      players.remove(id);
      drawRequests.remove(id);
      stateToPlayers();
      return;
    }

    if (type == 'ready') {
      player.ready = data['ready'] == true;
      stateToPlayers();
    }

    if (type == 'pass' && started) {
      final ids = (data['ids'] as List? ?? []).cast<String>();

      final selected = player.hand
          .where((card) => ids.contains(card.id))
          .toList();

      if (selected.isNotEmpty && selected.length == ids.length) {
        final nonJokers = selected.where((c) => !c.joker).toList();
        final ranks = nonJokers.map((c) => c.rank).toSet();

        if (ranks.length <= 1) {
          player.hand.removeWhere((c) => ids.contains(c.id));
          hostHand.addAll(selected);

          sendPlayer(id, {'type': 'passed', 'ids': ids});

          broadcast({
            'type': 'notice',
            'message':
                '${player.name} passed ${selected.length} card(s) to Host',
          });

          stateToPlayers();

          if (mounted) setState(() {});
        }
      }
    }

    if (type == 'show_one' && started) {
      final card = player.hand.firstWhere(
        (c) => c.id == data['id'],
        orElse: () => PlayingCard('', '', ''),
      );

      if (card.id.isNotEmpty) {
        player.shown = true;

        broadcast({
          'type': 'shown_card',
          'player': player.name,
          'card': card.toJson(),
        });

        stateToPlayers();
      }
    }

    if (type == 'win_request' && started && !winPending) {
      winPending = true;
      winnerRequest = id;

      stateToPlayers();

      broadcast({
        'type': 'notice',
        'message': '${player.name} requests a win',
      });

      if (mounted) setState(() {});
    }

    if (type == 'draw_request' && started) {
      drawRequests.add(id);

      broadcast({
        'type': 'notice',
        'message': '${player.name} requested a draw',
      });

      if (mounted) setState(() {});
    }
  }

  List<PlayingCard> makeDeck() {
    const suits = ['♠', '♥', '♦', '♣'];
    const ranks = [
      'A', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', 'J', 'Q', 'K',
    ];

    final cards = <PlayingCard>[];

    for (final suit in suits) {
      for (final rank in ranks) {
        cards.add(
          PlayingCard(
            '${suit}_${rank}_${rng.nextInt(1 << 30)}',
            rank,
            suit,
          ),
        );
      }
    }

    for (int i = 0; i < 4; i++) {
      cards.add(
        PlayingCard('joker_$i', 'JOKER', '★', joker: true),
      );
    }

    cards.shuffle(rng);
    return cards;
  }

  void deal() {
    if (players.isEmpty) return;

    if (players.length > 8) return;

    drawRequests.clear();
    deck = makeDeck();
    hostHand = [];

    for (final player in players.values) {
      player.hand = List.generate(7, (_) => deck.removeLast());
      player.ready = false;
      player.shown = false;
    }

    started = true;
    winPending = false;
    winnerRequest = null;
    currentWinner = null;

    stateToPlayers();

    setState(() => status = 'Cards dealt: 7 each');
  }

  void approveDraw(String id) {
    if (!drawRequests.contains(id)) return;

    if (hostHand.isEmpty) {
      setState(() => status = 'No passed cards available to draw');
      return;
    }

    final player = players[id];
    if (player == null) return;

    final card = hostHand.removeAt(rng.nextInt(hostHand.length));
    player.hand.add(card);

    drawRequests.remove(id);

    sendPlayer(id, {
      'type': 'private_hand',
      'hand': player.hand.map((c) => c.toJson()).toList(),
    });

    broadcast({
      'type': 'notice',
      'message': 'Host approved a draw for ${player.name}',
    });

    stateToPlayers();
    setState(() => status = 'Draw approved');
  }

  void rejectDraw(String id) {
    drawRequests.remove(id);
    sendPlayer(id, {'type': 'draw_rejected'});
    stateToPlayers();
    setState(() => status = 'Draw request rejected');
  }

  void confirmWinner() {
    if (winnerRequest == null) return;

    currentWinner = players[winnerRequest!]?.name ?? 'Unknown';
    winPending = false;

    broadcast({
      'type': 'winner_confirmed',
      'winner': currentWinner,
    });

    stateToPlayers();

    setState(() => status = 'Winner confirmed: $currentWinner');
  }

  void rejectWin() {
    final id = winnerRequest;

    if (id != null) {
      sendPlayer(id, {'type': 'win_rejected'});
    }

    winPending = false;
    winnerRequest = null;

    stateToPlayers();

    setState(() => status = 'Win request rejected');
  }

  void kick(String id) {
    drawRequests.remove(id);

    final socket = sockets.remove(id);
    players.remove(id);

    if (socket != null) {
      send(socket, {'type': 'kicked'});
      socket.sink.close();
    }

    if (winnerRequest == id) {
      winnerRequest = null;
      winPending = false;
    }

    stateToPlayers();
    setState(() => status = 'Player removed');
  }

  void newGame() => deal();

  @override
  void dispose() {
    for (final socket in sockets.values) {
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
        padding: const EdgeInsets.all(16),
        child: !unlocked
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('HOST PASSWORD'),
                  TextField(
                    controller: pin,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter 0692',
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        unlocked = pin.text == '0692';
                        if (!unlocked) status = 'Wrong password';
                      });
                    },
                    child: const Text('UNLOCK'),
                  ),
                  Text(status),
                ],
              )
            : ListView(
                children: [
                  FilledButton(
                    onPressed: server == null ? startServer : null,
                    child: const Text('START HOST SERVER'),
                  ),
                  SelectableText(
                    'ROOM CODE: $room',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.amber,
                    ),
                  ),
                  const Text(
                    'Connect all phones to the same hotspot or Wi-Fi. '
                    'Players need the Host phone IP and Room Code.',
                  ),
                  Text(status),
                  Text('PLAYERS: ${players.length}/8'),

                  ...players.entries.map(
                    (entry) => Card(
                      child: ListTile(
                        title: Text(entry.value.name),
                        subtitle: Text(
                          entry.value.ready ? 'Ready' : 'Not ready',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.person_remove,
                            color: Colors.red,
                          ),
                          onPressed: () => kick(entry.key),
                        ),
                      ),
                    ),
                  ),

                  if (!started)
                    FilledButton(
                      onPressed: players.isNotEmpty ? deal : null,
                      child: const Text('DEAL 7 CARDS EACH'),
                    ),

                  if (started) ...[
                    Text('Host is Controller only • Passed cards: ${hostHand.length}'),

                    if (hostHand.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        children: hostHand
                            .map(
                              (card) => Chip(
                                backgroundColor: Colors.green.shade700,
                                label: Text(card.label),
                              ),
                            )
                            .toList(),
                      ),

                    if (drawRequests.isNotEmpty) ...[
                      const Text(
                        'DRAW REQUESTS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      ...drawRequests.map(
                        (id) => Card(
                          child: ListTile(
                            title: Text(players[id]?.name ?? 'Player'),
                            subtitle: const Text('Requests one passed card'),
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => approveDraw(id),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => rejectDraw(id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (winPending)
                      Card(
                        color: Colors.orange.shade900,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Text(
                                '${players[winnerRequest]?.name ?? "Player"} WIN REQUEST',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                players[winnerRequest]
                                        ?.hand
                                        .map((c) => c.label)
                                        .join('  ') ??
                                    '',
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: confirmWinner,
                                      child: const Text('CONFIRM WINNER'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: rejectWin,
                                      child: const Text('REJECT'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                    FilledButton(
                      onPressed: newGame,
                      child: const Text('NEW 
