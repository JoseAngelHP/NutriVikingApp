import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nutri_viking_app/Pages/result_screen.dart';
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';

class QrScanner extends StatefulWidget {
  const QrScanner({super.key});

  @override
  State<QrScanner> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScanner> {
  bool isScanCompleted = false;
  bool isFlashOn = false;
  bool isFrontCamera = false;
  MobileScannerController controller = MobileScannerController();

  void closeScreen() {
    isScanCompleted = false;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  isFlashOn = !isFlashOn;
                });
                controller.toggleTorch();
              },
              icon: Icon(Icons.flash_on, color: isFlashOn ? Colors.blue : Colors.grey)),
          IconButton(
              onPressed: () {
                setState(() {
                  isFrontCamera = !isFrontCamera;
                });
                controller.switchCamera();
              },
              icon: Icon(Icons.camera_front, color: isFrontCamera ? Colors.blue : Colors.grey)),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          "Código QR",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xffc21500),
              Color(0xffffc500),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Coloque el código QR en el área",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "El escaneo se iniciará automáticamente",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Container con tamaño fijo para que parezca una calcomanía mediana
                  Container(
                    width: 350, // Ajusta entre 150-250 según tu preferencia
                    height: 350, // Mantén el mismo valor para un tamaño cuadrado
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(20), // Bordes redondeados
                      child: MobileScanner(
                        controller: controller,
                        onDetect: (capture) {
                          if (!isScanCompleted) {
                            final List<Barcode> barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty) {
                              String code = barcodes.first.rawValue ?? '---';
                              isScanCompleted = true;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ResultScreen(
                                    closeScreen: closeScreen,
                                    code: code,
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  // Superposición transparente del QRScannerOverlay para que coincida
                  QRScannerOverlay(overlayColor: Colors.transparent),
                ],
              ),
            ),
            /*Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  "Developed by Jose Prado",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
