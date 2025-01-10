import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/dialog_utils.dart';
import '../utils/token_utils.dart';

import 'symptom_input_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    Future<void> login() async {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        if (context.mounted) {
          showErrorDialog(context, 'Please fill in both fields');
        }
        return;
      }

      try {
        const url = 'http://10.0.2.2:8080/users/read';

        final body = jsonEncode({
          'email': email,
          'password': password,
        });

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if (!context.mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['token'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SymptomInputScreen(
                  token: encodeToken(data['token']),
                  email: email,
                ),
              ),
            );

          } else {
            showErrorDialog(context, 'Unexpected error occurred.');
          }
        } else {
          final errorData = jsonDecode(response.body);
          showErrorDialog(
            context,
            errorData['error'] ?? 'Invalid credentials',
          );
        }
      } catch (e) {
        if (context.mounted) {
          showErrorDialog(context, 'Failed to connect to the server.');
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
        backgroundColor: Colors.purple.shade50,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'email',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(15),
                  suffixIcon: Icon(Icons.close),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(15),
                  suffixIcon: Icon(Icons.close),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text(
                '로그인',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
