import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'user_update_screen.dart';

class ShowHospitalScreen extends StatefulWidget {
  final Map<String, dynamic> hospitalData;

  final String token;
  final String email;

  const ShowHospitalScreen({
    super.key,
    required this.hospitalData,
    required this.token,
    required this.email,
  });

  @override
  State<ShowHospitalScreen> createState() => _ShowHospitalScreenState();
}

class _ShowHospitalScreenState extends State<ShowHospitalScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(37.2635727, 127.0286009),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _setupMarkers();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _setupMarkers() {
    final xPosList = widget.hospitalData['x_pos_list'] as List?;
    final yPosList = widget.hospitalData['y_pos_list'] as List?;
    final hpidList = widget.hospitalData['hpid_list'] as List?;

    if (xPosList == null || yPosList == null || hpidList == null) return;

    for (int i = 0; i < hpidList.length; i++) {
      final String hospitalName = hpidList[i];
      final double lon = xPosList[i].toDouble();
      final double lat = yPosList[i].toDouble();

      _markers.add(
        Marker(
          markerId: MarkerId('hospital_$i'),
          position: LatLng(lat, lon),
          infoWindow: InfoWindow(
            title: hospitalName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hpidList = widget.hospitalData['hpid_list'] as List?;
    final courseList = widget.hospitalData['course_list'] as List?;
    final addrList = widget.hospitalData['addr_list'] as List?;
    final mapList = widget.hospitalData['map_list'] as List?;
    final telList = widget.hospitalData['tel_list'] as List?;

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
          // 지도 영역
          SizedBox(
            height: 400,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialPosition,
              markers: _markers,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: hpidList?.length ?? 0,
              itemBuilder: (context, index) {
                final name = hpidList![index];
                final course = courseList?[index] ?? '';
                final addr = addrList?[index] ?? '';
                final mapInfo = mapList?[index] ?? '';
                final tel = telList?[index] ?? '';

                return ListTile(
                  title: Text(name),
                  subtitle: Text('$addr\n$course'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tel),
                      if (mapInfo != null && mapInfo.toString().isNotEmpty)
                        Text(
                          mapInfo,
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
