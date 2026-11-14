// import 'package:flutter/material.dart';
// import '../services/api_service.dart';

// class TestScreen extends StatefulWidget {
//   const TestScreen({super.key});

//   @override
//   _TestScreenState createState() => _TestScreenState();
// }

// class _TestScreenState extends State<TestScreen> {
//   String _responseMessage = 'Press the button to test API';

//   void _runTest() async {
//     setState(() {
//       _responseMessage = 'Loading...';
//     });

//     String result = await testConnection();

//     setState(() {
//       _responseMessage = result;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Backend Connection Test')),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(_responseMessage, textAlign: TextAlign.center),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _runTest,
//                 child: const Text('Test Connection'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
