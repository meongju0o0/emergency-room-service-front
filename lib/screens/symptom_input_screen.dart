import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'select_course_screen.dart';
import 'user_update_screen.dart';

class SymptomInputScreen extends StatefulWidget {
  final String token;
  final String email;

  const SymptomInputScreen({super.key, required this.token, required this.email});

  @override
  State<SymptomInputScreen> createState() => _SymptomInputScreenState();
}

class _SymptomInputScreenState extends State<SymptomInputScreen> {
  final TextEditingController _symptomController = TextEditingController();
  String? _responseText;
  bool _isLoading = false;

  Future<void> _submitSymptom() async {
    final symptom = _symptomController.text.trim();

    if (symptom.isEmpty) {
      _showErrorDialog('증상을 입력하세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _responseText = null;
    });

    try {
      const url = 'http://10.0.2.2:8080/medical/nl_query';

      final body = jsonEncode({
        'email': widget.email,
        'query': symptom,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _responseText = responseData['result'] ?? '서버로부터 적절한 응답이 없습니다.';
        });
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(
          errorData['error'] ?? '서버 요청에 실패했습니다.',
        );
      }
    } catch (e) {
      _showErrorDialog('서버 연결에 실패했습니다.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('병원 검색 결과'),
        backgroundColor: Colors.purple.shade50,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserUpdateScreen(
                    email: widget.email,
                    token: widget.token,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 증상 입력 텍스트 박스 (상단)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _symptomController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: '증상을 입력하세요...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitSymptom,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              '입력',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _responseText != null
                    ? SingleChildScrollView(
                  child: Text(
                    _responseText!,
                    style: const TextStyle(fontSize: 16),
                  ),
                )
                    : const Center(
                  child: Text(
                    '응답 메시지가 여기에 표시됩니다.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          /// 다음 화면으로 이동 (SelectCourseScreen) + email 전달
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                // 병원 필터링 항목 선택 페이지로 넘어감
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectCourseScreen(
                      email: widget.email,
                      token: widget.token,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text(
                '다음',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
