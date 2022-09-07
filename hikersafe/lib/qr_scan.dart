import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  Barcode? result;
  String returnValue = "";
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    // if (returnValue.length >= 3) {
    //   Navigator.pop(context, returnValue);
    // }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text("Scan QR Code"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(flex: 5, child: _buildQrView(context)),
          if (result != null)
            Expanded(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context, returnValue);
                    },
                    child: Text(returnValue),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      primary: Colors.black,
                      textStyle: const TextStyle(
                        fontSize: 40,
                        fontFamily: "OpenSan",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        returnValue = result!.code!;
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
