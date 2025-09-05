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
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                                    color: ticket['status'] == 'used' ? Colors.blue[50] : 
                                           ticket['status'] == 'cancelled' ? Colors.red[50] : Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: ticket['status'] == 'used' ? Colors.blue[300]! :
                                             ticket['status'] == 'cancelled' ? Colors.red[300]! : Colors.green[300]!,
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
                                                color: ticket['status'] == 'valid' ? Colors.green : 
                                                       ticket['status'] == 'used' ? Colors.blue :
                                                       ticket['status'] == 'cancelled' ? Colors.red : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (ticket['status'] == 'used') ...[
                                              Text(' - '),
                                              Text(
                                                'Đã sử dụng',
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                      SizedBox(height: 12),
                                      // Action Buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: (ticket['status'] == 'used' || ticket['status'] == 'cancelled' || ticket['_loading'] == true) ? null : () async {
                                                await _confirmTicketInDialog(ticket['ticketCode']?.toString() ?? '', index, tickets, setDialogState);
                                              },
                                              icon: ticket['_loading'] == true ? 
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                ) : Icon(Icons.check, size: 16),
                                              label: Text('Xác nhận', style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: (ticket['status'] == 'used' || ticket['status'] == 'cancelled' || ticket['_loading'] == true) ? null : () async {
                                                await _cancelTicketInDialog(ticket['ticketCode']?.toString() ?? '', index, tickets, setDialogState);
                                              },
                                              icon: ticket['_loading'] == true ? 
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                ) : Icon(Icons.cancel, size: 16),
                                              label: Text('Hủy vé', style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
                      child: Column(
                        children: [
                          // Nút xác nhận tất cả
                          if (tickets.any((ticket) => ticket['status'] != 'used' && ticket['status'] != 'cancelled'))
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 12),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _confirmAllTickets(tickets, setDialogState);
                                },
                                icon: Icon(Icons.done_all),
                                label: Text('Xác nhận tất cả vé'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          
                          SizedBox(height: 12),

                          // Nút hủy tất cả vé - chỉ hiển thị khi có vé không phải cancelled và used
                          if (tickets.any((ticket) => ticket['status'] != 'cancelled' && ticket['status'] != 'used'))
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 12),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _confirmCancelledAllTickets(tickets, setDialogState);
                                },
                                icon: Icon(Icons.cancel),
                                label: Text('Xác nhận hủy tất cả vé'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromARGB(255, 222, 4, 44),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          Row(
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAllTickets(List<Map<String, dynamic>> tickets, StateSetter setDialogState) async {
    try {
      // Lấy danh sách ticket codes chưa được xử lý
      final availableTickets = tickets
          .where((ticket) => ticket['status'] != 'used' && ticket['status'] != 'cancelled')
          .toList();
      
      if (availableTickets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không có vé nào để xác nhận!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final ticketCodes = availableTickets
          .map((ticket) => ticket['ticketCode']?.toString() ?? '')
          .where((code) => code.isNotEmpty)
          .toList();

      if (ticketCodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tìm thấy mã vé hợp lệ!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Hiển thị dialog xác nhận
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Xác nhận tất cả vé'),
          content: Text('Bạn có chắc chắn muốn xác nhận ${ticketCodes.length} vé?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Có', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang xác nhận ${ticketCodes.length} vé...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );

      final api = ApiService();
      final response = await api.updateTicketStatus(ticketCodes, 'used', 'Hành khách đã lên xe');

      Navigator.of(context).pop(); // Đóng loading dialog

      if (response['code'] == 200) {
        // Cập nhật trạng thái tất cả vé trong dialog
        setDialogState(() {
          for (int i = 0; i < tickets.length; i++) {
            if (ticketCodes.contains(tickets[i]['ticketCode']?.toString())) {
              tickets[i]['status'] = 'used';
              tickets[i]['isUsed'] = true;
            }
          }
        });

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xác nhận thành công ${ticketCodes.length} vé!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Không thể xác nhận tất cả vé');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Đóng loading dialog nếu có

      // Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  ///HỦY TẤT CẢ VÉ
  Future<void> _confirmCancelledAllTickets(List<Map<String, dynamic>> tickets, StateSetter setDialogState) async {
    try {
      // Lấy danh sách ticket codes chưa được xử lý (không phải used và cancelled)
      final availableTickets = tickets
          .where((ticket) => ticket['status'] != 'used' && ticket['status'] != 'cancelled')
          .toList();
      
      if (availableTickets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không có vé nào để hủy!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }      final ticketCodes = availableTickets
          .map((ticket) => ticket['ticketCode']?.toString() ?? '')
          .where((code) => code.isNotEmpty)
          .toList();

      if (ticketCodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tìm thấy mã vé hợp lệ!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Hiển thị dialog xác nhận
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Xác nhận hủy tất cả vé'),
          content: Text('Bạn có chắc chắn muốn hủy ${ticketCodes.length} vé?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Có', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang hủy ${ticketCodes.length} vé...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );

      final api = ApiService();
      final response = await api.updateTicketStatus(ticketCodes, 'cancelled', 'Hành khách đã hủy vé');

      Navigator.of(context).pop(); // Đóng loading dialog

      if (response['code'] == 200) {
        // Cập nhật trạng thái tất cả vé trong dialog
        setDialogState(() {
          for (int i = 0; i < tickets.length; i++) {
            if (ticketCodes.contains(tickets[i]['ticketCode']?.toString())) {
              tickets[i]['status'] = 'cancelled';
              tickets[i]['isUsed'] = true;
            }
          }
        });

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hủy thành công ${ticketCodes.length} vé!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Không thể hủy tất cả vé');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Đóng loading dialog nếu có

      // Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  ///XÁC NHẬN TẤT CẢ VÉ
  Future<void> _confirmTicketInDialog(String ticketCode, int index, List<Map<String, dynamic>> tickets, StateSetter setDialogState) async {
    try {
      // Hiển thị loading mini
      setDialogState(() {
        tickets[index]['_loading'] = true;
      });

      final api = ApiService();
      final response = await api.updateTicketStatus([ticketCode], 'used', 'Hành khách đã lên xe');

      if (response['code'] == 200) {
        // Cập nhật trạng thái vé trong dialog
        setDialogState(() {
          tickets[index]['isUsed'] = true;
          tickets[index]['status'] = 'used';
          tickets[index]['_loading'] = false;
        });

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xác nhận vé thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setDialogState(() {
          tickets[index]['_loading'] = false;
        });
        throw Exception(response['message'] ?? 'Không thể xác nhận vé');
      }
    } catch (e) {
      setDialogState(() {
        tickets[index]['_loading'] = false;
      });

      // Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cancelTicketInDialog(String ticketCode, int index, List<Map<String, dynamic>> tickets, StateSetter setDialogState) async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận hủy vé'),
        content: Text('Bạn có chắc chắn muốn hủy vé $ticketCode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Có', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Hiển thị loading mini
      setDialogState(() {
        tickets[index]['_loading'] = true;
      });

      final api = ApiService();
      final response = await api.updateTicketStatus([ticketCode], 'cancelled', 'Vé đã bị hủy');

      if (response['code'] == 200) {
        // Cập nhật trạng thái vé trong dialog
        setDialogState(() {
          tickets[index]['status'] = 'cancelled';
          tickets[index]['_loading'] = false;
        });

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hủy vé thành công!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setDialogState(() {
          tickets[index]['_loading'] = false;
        });
        throw Exception(response['message'] ?? 'Không thể hủy vé');
      }
    } catch (e) {
      setDialogState(() {
        tickets[index]['_loading'] = false;
      });

      // Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _confirmTicket(String ticketCode, int index, List<Map<String, dynamic>> tickets) async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final api = ApiService();
      final response = await api.updateTicketStatus([ticketCode], 'used', 'Hành khách đã lên xe');

      Navigator.of(context).pop(); // Đóng loading dialog

      if (response['code'] == 200) {
        // Cập nhật trạng thái vé trong danh sách
        setState(() {
          tickets[index]['isUsed'] = true;
          tickets[index]['status'] = 'used';
        });

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xác nhận vé thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Không thể xác nhận vé');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Đóng loading dialog nếu có

      // Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cancelTicket(String ticketCode, int index, List<Map<String, dynamic>> tickets) async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận hủy vé'),
        content: Text('Bạn có chắc chắn muốn hủy vé $ticketCode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Có', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final api = ApiService();
      final response = await api.updateTicketStatus([ticketCode], 'cancelled', 'Vé đã bị hủy');

      Navigator.of(context).pop(); // Đóng loading dialog

      if (response['code'] == 200) {
        // Cập nhật trạng thái vé trong danh sách
        setState(() {
          tickets[index]['status'] = 'cancelled';
        });

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hủy vé thành công!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Không thể hủy vé');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Đóng loading dialog nếu có

      // Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
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
