import 'package:flutter/material.dart';
import 'symptom_input_screen.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final TextEditingController _medicationController = TextEditingController();
  final List<String> _currentMedications = []; // 추가된 약물 목록
  final List<String> _dummyMedicationCodes = [ // 더미 데이터
    'M01', 'M02', 'M03', 'M04', 'M05', 'M06', 'M07'
  ];
  List<String> _filteredMedicationCodes = []; // 필터링된 약물 코드 리스트

  @override
  void initState() {
    super.initState();
    // 초기화 시 더미 데이터를 필터링 리스트에 복사
    _filteredMedicationCodes = List.from(_dummyMedicationCodes);
  }

  // 약물 코드를 추가하는 함수
  void _addMedication(String code) {
    if (code.isNotEmpty && !_currentMedications.contains(code)) {
      setState(() {
        _currentMedications.add(code); // 약물 코드 추가
        _medicationController.clear(); // 입력 필드 초기화
        _filterMedications(''); // 필터링 재설정
      });
    }
  }

  // 검색어에 따라 약물 코드 필터링
  void _filterMedications(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMedicationCodes = List.from(_dummyMedicationCodes);
      } else {
        _filteredMedicationCodes = _dummyMedicationCodes
            .where((code) => code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
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
          // 검색창 및 검색 결과 리스트
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
                    onChanged: _filterMedications,
                    decoration: const InputDecoration(
                      hintText: '약물 코드 검색',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(15),
                      suffixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 200, // 검색 결과 리스트에 고정 높이 설정
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.builder(
                    itemCount: _filteredMedicationCodes.length,
                    itemBuilder: (context, index) {
                      final code = _filteredMedicationCodes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: const Text('M'),
                        ),
                        title: Text(code),
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
          // 현재 추가된 약물 리스트
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
                          setState(() {
                            _currentMedications.remove(code);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 완료 버튼 추가
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SymptomInputScreen()),
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
              '완료',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}