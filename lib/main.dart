
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

