import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'show_hospital_screen.dart';
import 'user_update_screen.dart';

class SelectCourseScreen extends StatefulWidget {
  final String email;
  final String token;

  const SelectCourseScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<SelectCourseScreen> createState() => _SelectCourseScreenState();
}

class _SelectCourseScreenState extends State<SelectCourseScreen> {
  final List<String> _allCourses = [
    '내과',
    '외과',
    '산부인과',
    '신경과',
    '정형외과',
    '소아청소년과',
    '응급의학과',
    '가정의학과',
  ];

  final List<String> _selectedCourses = [];

  Map<String, dynamic>? _hospitalData;
  bool _isLoading = false;

  void _toggleCourseSelection(String course) {
    setState(() {
      if (_selectedCourses.contains(course)) {
        _selectedCourses.remove(course);
      } else {
        _selectedCourses.add(course);
      }
    });
  }

  Future<void> _fetchHospitals() async {
    if (_selectedCourses.isEmpty) {
      _showErrorDialog('하나 이상의 진료과목을 선택하세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _hospitalData = null;
    });

    try {
      const url = 'http://10.0.2.2:8080/medical/hosp_query';

      final body = jsonEncode({
        "email": widget.email,
        "course": _selectedCourses,
        "x_pos": 127.0286009,
        "y_pos": 37.2635727,
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
          _hospitalData = responseData;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShowHospitalScreen(
              hospitalData: responseData,
              token: widget.token,
              email: widget.email,
            ),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData['error'] ?? '병원 리스트 요청 실패');
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
    final selectedText = _selectedCourses.isEmpty
        ? '선택된 과목이 없습니다.'
        : _selectedCourses.join(', ');

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
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              selectedText,
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // 과목 리스트
          Expanded(
            child: ListView.builder(
              itemCount: _allCourses.length,
              itemBuilder: (context, index) {
                final course = _allCourses[index];
                final isSelected = _selectedCourses.contains(course);
                return ListTile(
                  title: Text(course),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.purple)
                      : const Icon(Icons.circle_outlined),
                  onTap: () => _toggleCourseSelection(course),
                );
              },
            ),
          ),

          // 하단 버튼
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ElevatedButton(
                onPressed: _fetchHospitals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  '검색',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
