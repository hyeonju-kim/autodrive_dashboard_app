// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_webrtc/flutter_webrtc.dart';
//
// class ApiTestScreen extends StatefulWidget {
//   const ApiTestScreen({super.key});
//
//   @override
//   State<ApiTestScreen> createState() => _ApiTestScreenState();
// }
//
// class _ApiTestScreenState extends State<ApiTestScreen> {
//   final List<StreamData> streams = [
//     StreamData(id: 1, name: 'Stream 1'),
//     StreamData(id: 2, name: 'Stream 2'),
//     StreamData(id: 3, name: 'Stream 3'),
//     StreamData(id: 4, name: 'Stream 4'),
//   ];
//
//   bool isRefreshing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeStreams();
//   }
//
//   Future<void> _initializeStreams() async {
//     for (var stream in streams) {
//       await _connectStream(stream);
//     }
//   }
//
//   Future<void> _connectStream(StreamData stream) async {
//     try {
//       stream.renderer = RTCVideoRenderer();
//       await stream.renderer?.initialize();
//
//       // TODO: 여기에 실제 Janus WebRTC 연결 로직 추가
//       // Janus Gateway API 호출 및 WebRTC 협상
//
//       setState(() {
//         stream.isConnected = true;
//       });
//     } catch (e) {
//       debugPrint('Error connecting stream ${stream.id}: $e');
//       setState(() {
//         stream.isConnected = false;
//       });
//     }
//   }
//
//   Future<void> _refreshStreams() async {
//     setState(() {
//       isRefreshing = true;
//     });
//
//     for (var stream in streams) {
//       stream.isConnected = false;
//       await stream.renderer?.dispose();
//       await _connectStream(stream);
//     }
//
//     await Future.delayed(const Duration(milliseconds: 500));
//
//     setState(() {
//       isRefreshing = false;
//     });
//   }
//
//   @override
//   void dispose() {
//     for (var stream in streams) {
//       stream.renderer?.dispose();
//     }
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1F2937),
//         title: const Text(
//           'Janus Stream Viewer',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         actions: [
//           IconButton(
//             icon: isRefreshing
//                 ? const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 color: Colors.white,
//               ),
//             )
//                 : const Icon(Icons.refresh),
//             onPressed: isRefreshing ? null : _refreshStreams,
//             tooltip: 'Refresh',
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       backgroundColor: const Color(0xFF111827),
//       body: RefreshIndicator(
//         onRefresh: _refreshStreams,
//         child: ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: streams.length,
//           itemBuilder: (context, index) {
//             final stream = streams[index];
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 16),
//               child: _StreamCard(stream: stream),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//
// class _StreamCard extends StatelessWidget {
//   final StreamData stream;
//
//   const _StreamCard({required this.stream});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: const Color(0xFF1F2937),
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: const BoxDecoration(
//               color: Color(0xFF374151),
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(12),
//                 topRight: Radius.circular(12),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Text(
//                   stream.name,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 16,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const Spacer(),
//                 Container(
//                   width: 8,
//                   height: 8,
//                   decoration: BoxDecoration(
//                     color: stream.isConnected ? Colors.green : Colors.red,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   stream.isConnected ? 'Connected' : 'Disconnected',
//                   style: TextStyle(
//                     color: stream.isConnected ? Colors.green : Colors.red,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           AspectRatio(
//             aspectRatio: 16 / 9,
//             child: Container(
//               color: Colors.black,
//               child: stream.renderer != null && stream.isConnected
//                   ? RTCVideoView(
//                 stream.renderer!,
//                 objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
//               )
//                   : Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const CircularProgressIndicator(
//                       color: Colors.blue,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Loading Stream ${stream.id}...',
//                       style: const TextStyle(color: Colors.grey),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'WebRTC connection',
//                       style: TextStyle(
//                         color: Colors.grey,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: const BoxDecoration(
//               color: Color(0xFF374151),
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(12),
//                 bottomRight: Radius.circular(12),
//               ),
//             ),
//             child: Text(
//               'Stream ID: ${stream.id}',
//               style: const TextStyle(
//                 color: Colors.grey,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class StreamData {
//   final int id;
//   final String name;
//   RTCVideoRenderer? renderer;
//   bool isConnected;
//
//   StreamData({
//     required this.id,
//     required this.name,
//     this.renderer,
//     this.isConnected = false,
//   });
// }