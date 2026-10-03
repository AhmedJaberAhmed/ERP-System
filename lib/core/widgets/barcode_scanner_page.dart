// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
//
// /// Full-screen camera scanner. Pops with the first scanned code.
// ///   final code = await BarcodeScannerPage.scan(context);
// class BarcodeScannerPage extends StatefulWidget {
//   const BarcodeScannerPage({super.key});
//
//   static Future<String?> scan(BuildContext context) =>
//       Navigator.of(context).push<String>(
//         MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
//       );
//
//   @override
//   State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
// }
//
// class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
//   final _controller = MobileScannerController(
//     detectionSpeed: DetectionSpeed.noDuplicates,
//   );
//   bool _done = false;
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void _onDetect(BarcodeCapture capture) {
//     if (_done) return;
//     for (final b in capture.barcodes) {
//       final value = b.rawValue;
//       if (value != null && value.isNotEmpty) {
//         _done = true;
//         Navigator.of(context).pop(value);
//         return;
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Scan barcode'),
//         actions: [
//           IconButton(
//             tooltip: 'Flash',
//             icon: const Icon(Icons.flash_on),
//             onPressed: () => _controller.toggleTorch(),
//           ),
//           IconButton(
//             tooltip: 'Switch camera',
//             icon: const Icon(Icons.cameraswitch_outlined),
//             onPressed: () => _controller.switchCamera(),
//           ),
//         ],
//       ),
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           MobileScanner(
//             controller: _controller,
//             onDetect: _onDetect,
//             errorBuilder: (context, error, child) => Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Text(
//                   'Camera unavailable. Check camera permission.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Theme.of(context).colorScheme.error),
//                 ),
//               ),
//             ),
//           ),
//           Center(
//             child: Container(
//               width: 280,
//               height: 160,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.white, width: 2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
