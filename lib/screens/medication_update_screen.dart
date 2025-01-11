import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MedicationUpdateScreen extends StatefulWidget {
  final String email;  // 식별용
  final String token;  // JWT

  const MedicationUpdateScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<MedicationUpdateScreen> createState() => _MedicationUpdateScreenState();
}

class _MedicationUpdateScreenState extends State<MedicationUpdateScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _medicationController = TextEditingController();

  // 사용자가 선택(보유) 중인 약물
  final List<String> _currentMedications = [];

  // 기존 질병 정보 (수정하지 않지만, PUT 시 함께 보내야 해서 보관)
  List<String> _existingDiseases = [];

  // 검색 결과
  List<String> _filteredMedicationCodes = [];
  List<String> _filteredMedicationNames = [];

  bool _isLoading = false;
  bool _isFetchingUserInfo = false;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo(); // 처음 진입 시 기존 user info GET
  }

  /// 1) 현재 사용자 정보 GET → 복용 중인 약 + 기존 질병 목록 불러오기
  Future<void> _fetchUserInfo() async {
    setState(() {
      _isFetchingUserInfo = true;
    });

    try {
      const url = 'http://10.0.2.2:8080/users/user_info';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', // JWT
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // 예: {
        //   "id": 2,
        //   "email": "test@example.com",
        //   "username": "testuser",
        //   "disease_codes": [...],
        //   "medicine_codes": [...]
        // }

        // 기존 약물 코드
        final List<dynamic> meds = data['medicine_codes'] ?? [];
        // 기존 질병 코드
        final List<dynamic> diseases = data['disease_codes'] ?? [];

        setState(() {
          // 약물
          _currentMedications.clear();
          for (var m in meds) {
            _currentMedications.add(m.toString());
          }
          // 질병 (PUT 때 사용)
          _existingDiseases = diseases.map((d) => d.toString()).toList();
        });
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData['error'] ?? 'Failed to fetch user info');
      }
    } catch (e) {
      _showErrorDialog('서버와 연결에 실패했습니다: $e');
    } finally {
      setState(() {
        _isFetchingUserInfo = false;
      });
    }
  }

  /// 2) 검색 로직 (약물)
  Future<void> _searchMedications(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredMedicationCodes = [];
        _filteredMedicationNames = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const url = 'http://10.0.2.2:8080/medical/drug_query';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'drug_name': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _filteredMedicationCodes = List<String>.from(data['drug_code'] ?? []);
          _filteredMedicationNames = List<String>.from(data['drug_name'] ?? []);
        });
      } else {
        setState(() {
          _filteredMedicationCodes = [];
          _filteredMedicationNames = [];
        });
      }
    } catch (e) {
      setState(() {
        _filteredMedicationCodes = [];
        _filteredMedicationNames = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addMedication(String code) {
    if (code.isNotEmpty && !_currentMedications.contains(code)) {
      setState(() {
        _currentMedications.add(code);
      });
    }
  }

  void _removeMedication(String code) {
    setState(() {
      _currentMedications.remove(code);
    });
  }

  /// 3) PUT 요청으로 약물 정보 수정
  ///    - 기존 질병 정보(_existingDiseases)도 함께 담아서 보냄
  Future<void> _updateMedicationInfo() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _showErrorDialog('비밀번호를 입력하세요.');
      return;
    }

    // 질병 목록은 기존 값 사용
    final List<String> diseaseCodes = List.from(_existingDiseases);

    final body = {
      'email': widget.email,
      'username': '',
      'password': password,
      'disease_codes': diseaseCodes,       // 기존 질병 정보 보존
      'medicine_codes': _currentMedications,
    };

    try {
      const url = 'http://10.0.2.2:8080/users/update'; // PUT endpoint
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // 업데이트 성공
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('수정 성공'),
            content: const Text('복용 중인 약 목록이 수정되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // dialog
                  Navigator.pop(context); // 이전 화면
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData['error'] ?? '수정 실패');
      }
    } catch (e) {
      _showErrorDialog('서버와 연결에 실패했습니다. $e');
    }
  }

  /// 에러 다이얼로그
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
    // 사용자 약물/질병 정보 가져오는 중이면 로딩
    if (_isFetchingUserInfo) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('복용 중인 약 수정'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('복용 중인 약 수정'),
        backgroundColor: Colors.purple.shade50,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 상단 비밀번호 입력
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호 입력',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 검색 및 검색결과 리스트
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _medicationController,
                    onChanged: _searchMedications,
                    decoration: const InputDecoration(
                      hintText: '약물 이름 검색',
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
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.builder(
                      itemCount: _filteredMedicationCodes.length,
                      itemBuilder: (context, index) {
                        final code = _filteredMedicationCodes[index];
                        final name = _filteredMedicationNames[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: const Text('M'),
                          ),
                          title: Text('$code - $name'),
                          onTap: () {
                            _addMedication(code);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 선택된 약물
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  itemCount: _currentMedications.length,
                  itemBuilder: (context, index) {
                    final code = _currentMedications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade100,
                        child: const Icon(Icons.done),
                      ),
                      title: Text(code),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _removeMedication(code);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _updateMedicationInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text('완료', style: TextStyle(color: Colors.white)),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
