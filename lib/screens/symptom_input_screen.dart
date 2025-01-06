import 'package:flutter/material.dart';

class SymptomInputScreen extends StatefulWidget {
  const SymptomInputScreen({super.key});

  @override
  State<SymptomInputScreen> createState() => _SymptomInputScreenState();
}

class _SymptomInputScreenState extends State<SymptomInputScreen> {
  final TextEditingController _symptomController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('증상 입력'),
        backgroundColor: Colors.purple.shade50,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300, // 밝은 회색
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _symptomController,
              maxLines: 5, // 텍스트 박스 크기 줄임
              decoration: const InputDecoration(
                hintText: '증상을 입력하세요...',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // 다음 버튼 동작
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}