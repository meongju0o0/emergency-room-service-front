import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// MedicationScreen을 사용하기 위해 import
import 'medication_screen.dart';

class DiseaseCodeScreen extends StatefulWidget {
  final String email;
  final String username;
  final String password;
  final List<String> diseaseCodes;

  const DiseaseCodeScreen({
    super.key,
    required this.email,
    required this.username,
    required this.password,
    required this.diseaseCodes,
  });

  @override
  State<DiseaseCodeScreen> createState() => _DiseaseCodeScreenState();
}

class _DiseaseCodeScreenState extends State<DiseaseCodeScreen> {
  final TextEditingController _diseaseController = TextEditingController();
  final List<String> _currentDiseases = [];
  List<String> _filteredDiseaseCodes = [];
  List<String> _filteredDiseaseNames = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 만약 이전 화면에서 이미 넘어온 diseaseCodes가 있다면, 초기값으로 세팅 가능
    _currentDiseases.addAll(widget.diseaseCodes);
  }

  Future<void> _searchDiseases(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredDiseaseCodes = [];
        _filteredDiseaseNames = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const url = 'http://10.0.2.2:8080/medical/disease_query';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'disease_name': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _filteredDiseaseCodes = List<String>.from(data['disease_code'] ?? []);
          _filteredDiseaseNames = List<String>.from(data['disease_name'] ?? []);
        });
      } else {
        setState(() {
          _filteredDiseaseCodes = [];
          _filteredDiseaseNames = [];
        });
      }
    } catch (e) {
      setState(() {
        _filteredDiseaseCodes = [];
        _filteredDiseaseNames = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addDisease(String code) {
    if (code.isNotEmpty && !_currentDiseases.contains(code)) {
      setState(() {
        _currentDiseases.add(code);
      });
    }
  }

  void _removeDisease(String code) {
    setState(() {
      _currentDiseases.remove(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('현재 진단 코드'),
        backgroundColor: Colors.purple.shade50,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// 검색 및 검색결과 리스트
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _diseaseController,
                    onChanged: _searchDiseases,
                    decoration: const InputDecoration(
                      hintText: '질환 이름 검색',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(15),
                      suffixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.builder(
                      itemCount: _filteredDiseaseCodes.length,
                      itemBuilder: (context, index) {
                        final code = _filteredDiseaseCodes[index];
                        final name = _filteredDiseaseNames[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: const Text('D'), // Disease
                          ),
                          title: Text('$code - $name'),
                          onTap: () {
                            _addDisease(code);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 선택된 질환 리스트
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  itemCount: _currentDiseases.length,
                  itemBuilder: (context, index) {
                    final code = _currentDiseases[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade100,
                        child: const Icon(Icons.done),
                      ),
                      title: Text(code),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeDisease(code),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// 다음 화면(약물)으로 이동
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicationScreen(
                    email: widget.email,
                    username: widget.username,
                    password: widget.password,
                    diseaseCodes: _currentDiseases,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text('다음', style: TextStyle(color: Colors.white)),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
