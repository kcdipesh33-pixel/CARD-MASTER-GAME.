
import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const CardMaster());

class CardMaster extends StatelessWidget {
  const CardMaster({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CARD MASTER',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF10251D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class PlayingCard {
  final String value;
  final String suit;
  bool passed = false;
  bool shown = false;

  PlayingCard(this.value, this.suit);

  String get label => suit == 'JOKER' ? 'JOKER' : '$value$suit';
}

class Player {
  final String name;
  final List<PlayingCard> cards = [];
  bool winRequested = false;

  Player(this.name);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.style, size: 90, color: Colors.amber),
              const SizedBox(height: 15),
              const Text(
                'CARD MASTER',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const Text('OFFLINE MULTIPLAYER'),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HostLogin(),
                    ),
                  ),
                  child: const Text('HOST MODE'),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlayerJoin(),
                    ),
                  ),
                  child: const Text('PLAYER MODE'),
                ),
              ),
              const SizedBox(height: 35),
              const Text('1 HOST + UP TO 8 PLAYERS'),
              const Text('NO INTERNET REQUIRED'),
            ],
          ),
        ),
      ),
    );
  }
}

class HostLogin extends StatefulWidget {
  const HostLogin({super.key});

  @override
  State<HostLogin> createState() => _HostLoginState();
}

class _HostLoginState extends State<HostLogin> {
  final pin = TextEditingController();

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HOST LOGIN')),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 65, color: Colors.amber),
            TextField(
              controller: pin,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Host Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (pin.text == '0692') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HostLobby(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wrong Password')),
                  );
                }
              },
              child: const Text('UNLOCK HOST MODE'),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerJoin extends StatefulWidget {
  const PlayerJoin({super.key});

  @override
  State<PlayerJoin> createState() => _PlayerJoinState();
}

class _PlayerJoinState extends State<PlayerJoin> {
  final name = TextEditingController();
  final code = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PLAYER MODE')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: code,
              decoration: const InputDecoration(
                labelText: 'Room Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hotspot room connection is not yet implemented.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class HostLobby extends StatefulWidget {
  const HostLobby({super.key});

  @override
  State<HostLobby> createState() => _HostLobbyState();
}

class _HostLobbyState extends State<HostLobby> {
  int playerCount = 2;
  String roomCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HOST CONTROL')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.wifi, size: 65, color: Colors.greenAccent),
            const Text(
              'CREATE GAME ROOM',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            const Text('Select Players'),
            DropdownButton<int>(
              value: playerCount,
              items: List.generate(
                7,
                (i) => DropdownMenuItem(
                  value: i + 2,
                  child: Text('${i + 2} Players'),
                ),
              ),
              onChanged: (v) {
                if (v != null) setState(() => playerCount = v);
              },
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  roomCode =
                      (100000 + Random().nextInt(900000)).toString();
                });
              },
              child: const Text('CREATE ROOM'),
            ),
            if (roomCode.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('ROOM CODE'),
              Text(
                roomCode,
                style: const TextStyle(
                  fontSize: 38,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('$playerCount Players'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CardGame(
                        playerCount: playerCount,
                      ),
                    ),
                  );
                },
                child: const Text('START GAME'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CardGame extends StatefulWidget {
  final int playerCount;

  const CardGame({super.key, required this.playerCount});

  @override
  State<CardGame> createState() => _CardGameState();
}

class _CardGameState extends State<CardGame> {
  final List<Player> players = [];
  final Set<int> selected = {};

  final List<String> suits = ['♠', '♥', '♦', '♣'];
  final List<String> values = [
    'A', '2', '3', '4', '5', '6', '7',
    '8', '9', '10', 'J', 'Q', 'K'
  ];

  int currentPlayer = 0;
  String selectedNumber = '';
  bool served = false;
  bool draw = false;
  String winner = '';

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.playerCount; i++) {
      players.add(Player('Player ${i + 1}'));
    }
  }

  void serveCards() {
    final deck = <PlayingCard>[];

    for (final suit in suits) {
      for (final value in values) {
        deck.add(PlayingCard(value, suit));
      }
    }

    for (int i = 0; i < 4; i++) {
      deck.add(PlayingCard('JOKER', 'JOKER'));
    }

    deck.shuffle(Random());

    for (final player in players) {
      player.cards.clear();
      player.winRequested = false;

      for (int i = 0; i < 7; i++) {
        player.cards.add(deck.removeLast());
      }
    }

    setState(() {
      served = true;
      selectedNumber = '';
      selected.clear();
      winner = '';
      draw = false;
      currentPlayer = 0;
    });
  }

  void passCards() {
    if (selected.isEmpty || selectedNumber.isEmpty) return;

    final player = players[currentPlayer];

    for (final index in selected) {
      final card = player.cards[index];

      if (card.value == selectedNumber || card.suit == 'JOKER') {
        card.passed = true;
      }
    }

    setState(() => selected.clear());
  }

  void showCard(int index) {
    setState(() {
      players[currentPlayer].cards[index].shown = true;
    });
  }

  void requestWin() {
    setState(() {
      players[currentPlayer].winRequested = true;
    });
  }

  void confirmWinner(int index) {
    setState(() {
      winner = players[index].name;
    });
  }

  void kickPlayer(int index) async {
    if (players.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one player must remain.'),
        ),
      );
      return;
    }

    final playerName = players[index].name;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('KICK PLAYER?'),
        content: Text('Remove $playerName from this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('KICK'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      players.removeAt(index);
      selected.clear();

      if (currentPlayer >= players.length) {
        currentPlayer = players.length - 1;
      } else if (index < currentPlayer) {
        currentPlayer--;
      }

      if (players.isNotEmpty && players.every((p) => p.winRequested)) {
        draw = true;
      }
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$playerName was removed from the game.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!served) {
      return Scaffold(
        appBar: AppBar(title: const Text('CARD GAME')),
        body: Center(
          child: ElevatedButton(
            onPressed: serveCards,
            child: const Text('SERVE 7 CARDS'),
          ),
        ),
      );
    }

    final player = players[currentPlayer];
    final activeCards = player.cards
        .asMap()
        .entries
        .where((e) => !e.value.passed)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('CARD MASTER GAME')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Text(
              'Players Remaining: ${players.length}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 12),
            DropdownButton<int>(
              value: currentPlayer,
              isExpanded: true,
              items: List.generate(
                players.length,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(players[i].name),
                ),
              ),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    currentPlayer = v;
                    selected.clear();
                  });
                }
              },
            ),
            const Text('HOST: Select Card Number'),
            Wrap(
              spacing: 8,
              children: values.map((v) {
                return ElevatedButton(
                  onPressed: () => setState(() {
                    selectedNumber = v;
                    selected.clear();
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedNumber == v
                        ? Colors.amber
                        : Colors.blueGrey,
                  ),
                  child: Text(v),
                );
              }).toList(),
            ),
            const SizedBox(height: 15),
            Text(
              '${player.name} - Cards',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Cards remaining: ${activeCards.length}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: player.cards.asMap().entries.map((entry) {
                final i = entry.key;
                final card = entry.value;
                final isSelected = selected.contains(i);

                return GestureDetector(
                  onTap: card.passed
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              selected.remove(i);
                            } else {
                              selected.add(i);
                            }
                          });
                        },
                  child: Container(
                    width: 76,
                    height: 105,
                    decoration: BoxDecoration(
                      color: card.passed
                          ? Colors.green
                          : isSelected
                              ? Colors.orange
                              : Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.black),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      card.passed
                          ? 'PASSED ✓'
                          : card.shown
                              ? card.label
                              : card.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: card.passed
                            ? Colors.white
                            : (card.suit == '♥' || card.suit == '♦')
                                ? Colors.red
                                : Colors.black,
                        fontSize: card.passed ? 12 : 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: selected.isEmpty || selectedNumber.isEmpty
                  ? null
                  : passCards,
              child: Text('PASS SELECTED (${selected.length})'),
            ),
            OutlinedButton(
              onPressed: selected.length == 1
                  ? () => showCard(selected.first)
                  : null,
              child: const Text('SHOW ONE CARD'),
            ),
            if (activeCards.isEmpty)
              ElevatedButton(
                onPressed: requestWin,
                child: const Text('WIN REQUEST + SHOW ALL CARDS'),
              ),
            const Divider(height: 30),
            const Text(
              'HOST CONTROL PANEL',
              style: TextStyle(fontSize: 20, color: Colors.amber),
            ),
            const Text(
              'Manage Players / Kick Players',
              style: TextStyle(color: Colors.white70),
            ),
            ...players.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;

              return Card(
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    p.winRequested
                        ? 'WIN REQUEST: ${p.cards.map((c) => c.label).join(', ')}'
                        : 'Passed: ${p.cards.where((c) => c.passed).length}/7',
                  ),
                  trailing: Wrap(
                    spacing: 0,
                    children: [
                      if (p.winRequested)
                        IconButton(
                          tooltip: 'Confirm Winner',
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          onPressed: () => confirmWinner(i),
                        ),
                      IconButton(
                        tooltip: 'Kick Player',
                        icon: const Icon(
                          Icons.person_remove,
                          color: Colors.red,
                        ),
                        onPressed: () => kickPlayer(i),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (players.where((p) => p.winRequested).length >= 2)
              ElevatedButton(
                onPressed: () => setState(() => draw = true),
                child: const Text('DECLARE DRAW'),
              ),
            if (winner.isNotEmpty)
              Text(
                'WINNER: $winner',
                style: const TextStyle(
                  fontSize: 25,
                  color: Colors.greenAccent,
                ),
              ),
            if (draw)
              const Text(
                'GAME DRAW!',
                style: TextStyle(fontSize: 25, color: Colors.amber),
              ),
            ElevatedButton(
              onPressed: serveCards,
              child: const Text('NEW GAME / SERVE AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}
