// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart' as main_qr;
import 'login_screen.dart';
import 'package:readhoadon/services/api_service.dart';
import 'package:readhoadon/models/trip_model.dart';

class TripListScreen extends StatefulWidget {
  @override
  _TripListScreenState createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  List<Trip> trips = [];
  String errorMessage = '';
  int? selectedTripId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      final api = ApiService();
      final fetchedTrips = await api.getDriverTrips();
      setState(() {
        trips = fetchedTrips;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi: $e';
        isLoading = false;
      });
      
      // Nếu token hết hạn, chuyển về màn hình đăng nhập
      if (e.toString().contains('Phiên đăng nhập đã hết hạn')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  Future<void> _logout() async {
    await ApiService().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // Helper methods for formatting
  String? _formatDateTime(String? isoDateTime) {
    if (isoDateTime == null) return null;
    try {
      final dateTime = DateTime.parse(isoDateTime);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDateTime;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'scheduled':
        return 'Đã lên lịch';
      case 'delayed':
        return 'Trễ giờ';
      case 'cancelled':
        return 'Đã hủy';
      case 'completed':
        return 'Hoàn thành';
      default:
        return status ?? 'Không xác định';
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh Sách Chuyến Đi'),
        actions: [
         
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchTrips,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (isLoading) 
            Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: trips.isEmpty && !isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_bus, size: 64, color: Colors.grey),
                        Text('Không có chuyến đi nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchTrips,
                          child: Text('Tải lại'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final isSelected = selectedTripId == trip.tripId;
                      
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Colors.blue.shade50 : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? Colors.blue : Colors.grey,
                            child: Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '${trip.operatorName ?? 'Nhà xe không xác định'}',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID: ${trip.tripId ?? 'N/A'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              SizedBox(height: 4),
                              if (trip.route?.startLocation != null)
                                Text(
                                  'Từ: ${trip.route!.startLocation}',
                                  style: TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (trip.route?.endLocation != null)
                                Text(
                                  'Đến: ${trip.route!.endLocation}',
                                  style: TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 14, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text(
                                    _formatDateTime(trip.departureTime) ?? 'Chưa có thời gian',
                                    style: TextStyle(fontSize: 12, color: Colors.blue),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    trip.status == 'scheduled' ? Icons.check_circle : 
                                    trip.status == 'delayed' ? Icons.warning : Icons.info,
                                    size: 14,
                                    color: trip.status == 'scheduled' ? Colors.green : 
                                           trip.status == 'delayed' ? Colors.orange : Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _getStatusText(trip.status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: trip.status == 'scheduled' ? Colors.green : 
                                             trip.status == 'delayed' ? Colors.orange : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Spacer(),
                                  if (trip.availableSeats != null && trip.totalSeats != null)
                                    Text(
                                      '${trip.availableSeats}/${trip.totalSeats} chỗ',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                              if (trip.pricePerSeat != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${_formatPrice(trip.pricePerSeat!)} VNĐ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              selectedTripId = trip.tripId;
                            });
                          },
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Colors.green)
                              : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedTripId != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => main_qr.QrScannerScreen(selectedTripId!),
                          ),
                        );
                      }
                    : null,
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Quét QR Vé'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          if (errorMessage.isNotEmpty) 
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}