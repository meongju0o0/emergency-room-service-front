import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MedicationScreen extends StatefulWidget {
  final String email;
  final String username;
  final String password;
  final List<String> diseaseCodes;

  const MedicationScreen({
    super.key,
    required this.email,
    required this.username,
    required this.password,
    required this.diseaseCodes,
  });

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final TextEditingController _medicationController = TextEditingController();
  final List<String> _currentMedications = [];
  List<String> _filteredMedicationCodes = [];
  List<String> _filteredMedicationNames = [];
  bool _isLoading = false;

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

  Future<void> _submitRegistration() async {
    final body = {
      'email': widget.email,
      'username': widget.username,
      'password': widget.password,
      'disease_codes': widget.diseaseCodes,
      'medicine_codes': _currentMedications,
    };

    try {
      const url = 'http://10.0.2.2:8080/users/add';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('회원가입 성공'),
            content: const Text('회원가입이 완료되었습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData['error'] ?? '회원가입 실패');
      }
    } catch (e) {
      _showErrorDialog('서버와의 연결에 실패했습니다.');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('현재 복용 중인 약물'),
        backgroundColor: Colors.purple.shade50,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
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
                    height: 200,
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
                            child: const Text('M'), // Medication
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

          const SizedBox(height: 20),

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
            onPressed: _submitRegistration,
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
