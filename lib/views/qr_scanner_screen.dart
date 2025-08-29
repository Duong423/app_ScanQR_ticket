// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:readhoadon/services/api_service.dart';

class QrScannerScreen extends StatefulWidget {
  final int tripId;

  QrScannerScreen(this.tripId);

  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String errorMessage = '';
  String successMessage = '';
  bool isScanning = true;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (isScanning) {
        setState(() {
          isScanning = false;
        });
        controller.pauseCamera();
        _validateQrCode(scanData.code!);
      }
    });
  }

  Future<void> _validateQrCode(String qrCode) async {
    try {
      print('QR Code scanned: $qrCode');
      
      // Giải mã QR code để lấy bookingCode
      String bookingCode;
      try {
        // Thử parse JSON nếu QR code là JSON
        final qrData = jsonDecode(qrCode);
        if (qrData is Map<String, dynamic> && qrData.containsKey('bookingCode')) {
          bookingCode = qrData['bookingCode'].toString();
        } else {
          // Nếu không phải JSON, coi như QR code chính là bookingCode
          bookingCode = qrCode;
        }
      } catch (e) {
        // Nếu không parse được JSON, extract từ text
        // Tìm pattern "Mã đặ chỗ: XXXXXX" trong QR code
        final bookingCodePattern = RegExp(r'Mã đặt chỗ:\s*([A-Za-z0-9]+)');
        final match = bookingCodePattern.firstMatch(qrCode);
        
        if (match != null && match.group(1) != null) {
          bookingCode = match.group(1)!;
        } else {
          // Nếu không tìm thấy pattern, coi như QR code chính là bookingCode
          bookingCode = qrCode.trim();
        }
      }
      
      print('Extracted booking code: $bookingCode');
      
      final api = ApiService();
      final response = await api.validateBookingTrip(widget.tripId, bookingCode);
      
      // Kiểm tra response và hiển thị ticket codes
      if (response['code'] == 200 && response['result'] != null) {
        final result = response['result'];
        List<Map<String, dynamic>> tickets = [];
        
        // Xử lý danh sách tickets từ response
        if (result is Map<String, dynamic> && result.containsKey('tickets')) {
          final ticketsData = result['tickets'];
          if (ticketsData is List) {
            tickets = ticketsData.cast<Map<String, dynamic>>();
          }
        }
        
        setState(() {
          successMessage = 'Xác thực thành công! Tìm thấy ${tickets.length} vé.';
          errorMessage = '';
        });
        
        // Hiển thị dialog với danh sách tickets
        _showTicketsDialog(tickets, bookingCode, result);
      } else {
        throw Exception(response['message'] ?? 'Không tìm thấy vé hợp lệ');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi: $e';
        successMessage = '';
      });
      
      // Hiển thị dialog lỗi
      _showResultDialog(false, errorMessage);
    }
  }

  void _showTicketsDialog(List<Map<String, dynamic>> tickets, String bookingCode, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tìm thấy danh sách vé thành công',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Code: $bookingCode',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (result['passengerInfo'] != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'Hành khách: ${result['passengerInfo']}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                        SizedBox(height: 16),
                        Text(
                          'Danh sách vé (${tickets.length} vé):',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ticket['isUsed'] == true ? Colors.red[50] : Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ticket['isUsed'] == true ? Colors.red[300]! : Colors.green[300]!,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Vé ${index + 1}: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Expanded(
                                        child: Text(
                                          ticket['ticketCode']?.toString() ?? 'N/A',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (ticket['seatNumber'] != null) ...[
                                    SizedBox(height: 4),
                                    Text('Ghế: ${ticket['seatNumber']}'),
                                  ],
                                  if (ticket['passengerName'] != null) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      'Tên: ${ticket['passengerName']}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (ticket['status'] != null) ...[
                                    SizedBox(height: 4),
                                    Wrap(
                                      children: [
                                        Text('Trạng thái: '),
                                        Text(
                                          ticket['status'].toString(),
                                          style: TextStyle(
                                            color: ticket['status'] == 'valid' ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (ticket['isUsed'] == true) ...[
                                          Text(' - '),
                                          Text(
                                            'Đã sử dụng',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Đóng dialog
                          Navigator.of(context).pop(); // Quay lại danh sách chuyến đi
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showResultDialog(bool isSuccess, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              SizedBox(width: 8),
              Text(isSuccess ? 'Thành công' : 'Lỗi'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                if (isSuccess) {
                  Navigator.of(context).pop(); // Quay lại danh sách chuyến đi
                } else {
                  _resetScanner(); // Tiếp tục quét
                }
              },
              child: Text(isSuccess ? 'OK' : 'Quét lại'),
            ),
          ],
        );
      },
    );
  }

  void _resetScanner() {
    setState(() {
      isScanning = true;
      errorMessage = '';
      successMessage = '';
    });
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quét QR Vé'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.green,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Chuyến đi ID: ${widget.tripId}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!isScanning)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: _resetScanner,
                        child: Text('Quét lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (isScanning)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Hướng camera vào mã QR để quét',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
