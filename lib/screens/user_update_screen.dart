import 'package:flutter/material.dart';

import 'disease_update_screen.dart';
import 'medication_update_screen.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/token_utils.dart';

class UserUpdateScreen extends StatefulWidget {
  final String email;
  final String token; // 기존 보유 중인 토큰 (필요 없다면 제거 가능)

  const UserUpdateScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<UserUpdateScreen> createState() => _UserUpdateScreenState();
}

class _UserUpdateScreenState extends State<UserUpdateScreen> {
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;      // 인증 요청 중 로딩 표시
  bool _isAuthenticated = false; // 인증 성공 여부
  String? _newToken;             // 서버가 새 토큰을 주면 저장 (원하면 사용)

  Future<void> _authenticateUser() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _showErrorDialog('비밀번호를 입력하세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 실제 로그인 엔드포인트 예시 (상황에 맞게 수정)
      const loginUrl = 'http://10.0.2.2:8080/users/read';

      final body = jsonEncode({
        "email": widget.email,
        "password": password,
      });

      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', // JWT 토큰
        },
        body: body,
      );

      if (response.statusCode == 200) {
        // 인증 성공
        final data = jsonDecode(response.body);
        // 예: { "message": "Login successful", "token": "xxx" }
        final message = data['message'];
        final newToken = encodeToken(data['token']);

        if (message == 'Login successful') {
          setState(() {
            _isAuthenticated = true;
            _newToken = newToken; // 필요하다면 저장
          });
        } else {
          _showErrorDialog('인증 실패: $message');
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData['error'] ?? '인증 실패');
      }
    } catch (e) {
      _showErrorDialog('서버 연결에 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 버튼 눌렀을 때, 인증 상태를 확인 후 페이지 이동
  void _goToDiseaseUpdateScreen() {
    if (!_isAuthenticated) {
      _showErrorDialog('먼저 비밀번호로 인증해주세요.');
      return;
    }
    // 인증 성공 시, 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiseaseUpdateScreen(
          email: widget.email,
          token: _newToken ?? widget.token,
          // 여기서 새로 발급받은 토큰(_newToken)이 있으면 넘기고
          // 없으면 기존 token(widget.token)을 넘김
        ),
      ),
    );
  }

  void _goToMedicationUpdateScreen() {
    if (!_isAuthenticated) {
      _showErrorDialog('먼저 비밀번호로 인증해주세요.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationUpdateScreen(
          email: widget.email,
          token: _newToken ?? widget.token,
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원정보 수정'),
        backgroundColor: Colors.purple.shade50,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // email은 수정 불가능
              Text(
                '이메일: ${widget.email}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 기존 비밀번호 입력 필드
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '기존 비밀번호 입력',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // 인증하기 버튼
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _authenticateUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  '인증하기',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),

              // (1) 질병 목록 수정
              ElevatedButton(
                onPressed: _goToDiseaseUpdateScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAuthenticated ? Colors.purple : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('질병 목록 수정', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // (2) 복용 중인 약 수정
              ElevatedButton(
                onPressed: _goToMedicationUpdateScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAuthenticated ? Colors.purple : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('복용 중인 약 수정', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
