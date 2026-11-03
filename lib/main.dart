
import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const CardMasterApp());
}

class CardMasterApp extends StatelessWidget {
  const CardMasterApp({super.key});

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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.style,
                  size: 90,
                  color: Colors.amber,
                ),
                const SizedBox(height: 15),
                const Text(
                  'CARD MASTER',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const Text(
                  'OFFLINE MULTIPLAYER',
                  style: TextStyle(
                    letterSpacing: 3,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 55),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('HOST MODE'),
                    onPressed: () => open(
                      context,
                      const HostLoginScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.people),
                    label: const Text('PLAYER MODE'),
                    onPressed: () => open(
                      context,
                      const PlayerScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                const Text(
                  '1 HOST + 8 PLAYERS',
                  style: TextStyle(color: Colors.greenAccent),
                ),
                const Text(
                  'NO INTERNET REQUIRED',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HostLoginScreen extends StatefulWidget {
  const HostLoginScreen({super.key});

  @override
  State<HostLoginScreen> createState() => _HostLoginScreenState();
}

class _HostLoginScreenState extends State<HostLoginScreen> {
  final pin = TextEditingController();
  String error = '';

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  void login() {
    if (pin.text == '0692') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HostScreen(),
        ),
      );
    } else {
      setState(() => error = 'Wrong Password!');
    }
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
            const SizedBox(height: 25),
            TextField(
              controller: pin,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Host Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: login,
              child: const Text('UNLOCK HOST MODE'),
            ),
          ],
        ),
      ),
    );
  }
}

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  int playerLimit = 8;
  String roomCode = '';

  void createRoom() {
    final random = Random();
    setState(() {
      roomCode = (100000 + random.nextInt(900000)).toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HOST CONTROL PANEL')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.wifi_tethering,
                size: 65, color: Colors.greenAccent),
            const Text(
              'HOST MODE',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Select number of players'),
            DropdownButton<int>(
              value: playerLimit,
              items: List.generate(
                7,
                (i) => DropdownMenuItem(
                  value: i + 2,
                  child: Text('${i + 2} Players'),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() => playerLimit = value);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createRoom,
              child: const Text('CREATE ROOM'),
            ),
            const SizedBox(height: 20),
            if (roomCode.isNotEmpty) ...[
              const Text('YOUR ROOM CODE'),
              Text(
                roomCode,
                style: const TextStyle(
                  fontSize: 38,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Maximum $playerLimit Players'),
            ],
            const Spacer(),
            const Text(
              'Room networking will be connected in the next version.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final name = TextEditingController();
  final code = TextEditingController();
  String message = '';

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    super.dispose();
  }

  void joinRoom() {
    if (name.text.trim().isEmpty || code.text.trim().isEmpty) {
      setState(() => message = 'Enter your name and room code.');
      return;
    }

    setState(() {
      message =
          'Details entered. Offline room connection will be added next.';
    });
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
            const Icon(Icons.person, size: 70, color: Colors.amber),
            const Text(
              'JOIN GAME',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Your Player Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Host Room Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: joinRoom,
              child: const Text('JOIN ROOM'),
            ),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.greenAccent),
            ),
          ],
        ),
      ),
    );
  }
}
