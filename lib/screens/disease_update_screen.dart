import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DiseaseUpdateScreen extends StatefulWidget {
  final String email;  // 수정 불가
  final String token;  // JWT

  const DiseaseUpdateScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<DiseaseUpdateScreen> createState() => _DiseaseUpdateScreenState();
}

class _DiseaseUpdateScreenState extends State<DiseaseUpdateScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();

  /// 사용자 질병 리스트 (UI에 표시 및 수정)
  final List<String> _currentDiseases = [];

  /// 사용자 약물 리스트 (화면에서 수정하지 않지만, PUT 시 함께 보내야 하므로 보관)
  List<String> _existingMedications = [];

  /// 검색 결과
  List<String> _filteredDiseaseCodes = [];
  List<String> _filteredDiseaseNames = [];

  bool _isLoading = false;
  bool _isFetchingUserInfo = false;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo(); // 화면 열릴 때 기존 user info(질병+약물) 불러오기
  }

  /// 1) GET /users/user_info 로 현재 사용자 질병 + 약물 목록 받아오기
  Future<void> _fetchUserInfo() async {
    setState(() {
      _isFetchingUserInfo = true;
    });

    try {
      // 서버에서 사용자 정보를 GET으로 불러옴
      const url = 'http://10.0.2.2:8080/users/user_info';  // 예시: user_info 엔드포인트
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', // JWT 토큰
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // 예: {
        //   "id": 2,
        //   "email": "test@example.com",
        //   "username": "testuser",
        //   "disease_codes": ["I10", "K760", "I49"],
        //   "medicine_codes": ["198100119", "198401396"]
        // }

        // 질병 목록 세팅
        final List<dynamic> diseases = data['disease_codes'] ?? [];
        // 약물 목록 세팅
        final List<dynamic> meds = data['medicine_codes'] ?? [];

        setState(() {
          // 기존 질병
          _currentDiseases.clear();
          for (var d in diseases) {
            _currentDiseases.add(d.toString());
          }

          // 기존 약물
          _existingMedications = meds.map((m) => m.toString()).toList();
        });
      } else {
        // GET 실패 처리
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

  /// 2) 질병 검색 (POST /medical/disease_query)
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

  /// 검색 결과 탭 시 추가
  void _addDisease(String code) {
    if (code.isNotEmpty && !_currentDiseases.contains(code)) {
      setState(() {
        _currentDiseases.add(code);
      });
    }
  }

  /// 선택된 질병 삭제
  void _removeDisease(String code) {
    setState(() {
      _currentDiseases.remove(code);
    });
  }

  /// 3) PUT 요청: 수정된 질병 + 기존 약물을 함께 전송
  Future<void> _updateDiseaseInfo() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _showErrorDialog('비밀번호를 입력하세요.');
      return;
    }

    // 여기서 약물 정보는 수정 안 하므로 기존 값을 그대로 사용
    final List<String> medicineCodes = List.from(_existingMedications);

    final body = {
      'email': widget.email,
      'username': '',  // 필요하다면 기존 username 넘김
      'password': password,
      'disease_codes': _currentDiseases,
      'medicine_codes': medicineCodes, // 약물은 기존 값 그대로
    };

    try {
      const url = 'http://10.0.2.2:8080/users/update'; // PUT Endpoint
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
            content: const Text('질병 목록이 수정되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // dialog 닫기
                  Navigator.pop(context); // 화면 닫고 이전 화면으로 복귀
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
      _showErrorDialog('서버와의 연결에 실패했습니다. $e');
    }
  }

  /// 오류 다이얼로그
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
    // 만약 사용자 정보 조회 중이면 로딩 화면
    if (_isFetchingUserInfo) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('질병 목록 수정'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('질병 목록 수정'),
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
                labelText: '비밀번호 수정',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 질병 검색
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
                    controller: _diseaseController,
                    onChanged: _searchDiseases,
                    decoration: const InputDecoration(
                      hintText: '질병 이름 검색',
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
                      itemCount: _filteredDiseaseCodes.length,
                      itemBuilder: (context, index) {
                        final code = _filteredDiseaseCodes[index];
                        final name = _filteredDiseaseNames[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: const Text('D'),
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

          const SizedBox(height: 10),

          // 선택된 질병
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
                        onPressed: () {
                          _removeDisease(code);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 완료(수정 요청)
          ElevatedButton(
            onPressed: _updateDiseaseInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
