import 'package:flutter/material.dart';
import 'medication_screen.dart';

class DiseaseCodeScreen extends StatefulWidget {
  const DiseaseCodeScreen({super.key});

  @override
  State<DiseaseCodeScreen> createState() => _DiseaseCodeScreenState();
}

class _DiseaseCodeScreenState extends State<DiseaseCodeScreen> {
  final TextEditingController _diseaseCodeController = TextEditingController();
  final List<String> _currentDiseaseCodes = [];
  final List<String> _dummyDiseaseCodes = [
    'A01', 'A02', 'B01', 'B02', 'C01', 'C02', 'D01'
  ];
  List<String> _filteredDiseaseCodes = [];

  @override
  void initState() {
    super.initState();
    _filteredDiseaseCodes = List.from(_dummyDiseaseCodes);
  }

  void _addDiseaseCode(String code) {
    if (code.isNotEmpty && !_currentDiseaseCodes.contains(code)) {
      setState(() {
        _currentDiseaseCodes.add(code);
        _diseaseCodeController.clear();
        _filterDiseaseCodes('');
      });
    }
  }

  void _filterDiseaseCodes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDiseaseCodes = List.from(_dummyDiseaseCodes);
      } else {
        _filteredDiseaseCodes = _dummyDiseaseCodes
            .where((code) => code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기저 질환 질병 코드'),
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
                    controller: _diseaseCodeController,
                    onChanged: _filterDiseaseCodes,
                    decoration: const InputDecoration(
                      hintText: '질병 코드 검색',
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
                    itemCount: _filteredDiseaseCodes.length,
                    itemBuilder: (context, index) {
                      final code = _filteredDiseaseCodes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: const Text('A'),
                        ),
                        title: Text(code),
                        onTap: () {
                          _addDiseaseCode(code);
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
                  itemCount: _currentDiseaseCodes.length,
                  itemBuilder: (context, index) {
                    final code = _currentDiseaseCodes[index];
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
                            _currentDiseaseCodes.remove(code);
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
          // 다음 버튼 추가
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MedicationScreen()),
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}