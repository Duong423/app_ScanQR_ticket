// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart' as main_qr;
import 'login_screen.dart';
import 'passenger_list_screen.dart';
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

  Future<void> _updateTripStatus(Trip trip, String newStatus) async {
    try {
      setState(() {
        isLoading = true;
      });

      await ApiService().updateTripStatus(trip.tripId!, newStatus);
      
      // Cập nhật status của trip trong danh sách
      setState(() {
        final index = trips.indexWhere((t) => t.tripId == trip.tripId);
        if (index != -1) {
          trips[index] = Trip(
            tripId: trip.tripId,
            operatorName: trip.operatorName,
            route: trip.route,
            departureTime: trip.departureTime,
            arrivalTime: trip.arrivalTime,
            availableSeats: trip.availableSeats,
            totalSeats: trip.totalSeats,
            pricePerSeat: trip.pricePerSeat,
            status: newStatus, // Cập nhật status mới
          );
        }
        isLoading = false;
      });

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật trạng thái chuyến đi thành công'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showStatusUpdateDialog(Trip trip) async {
    final statusOptions = [
      {'value': 'scheduled', 'label': 'Đã lên lịch', 'icon': Icons.schedule, 'color': Colors.blue},
      {'value': 'departed', 'label': 'Đã khởi hành', 'icon': Icons.directions_bus, 'color': Colors.orange},
      {'value': 'on_time', 'label': 'Đúng giờ', 'icon': Icons.check_circle, 'color': Colors.green},
      {'value': 'delayed', 'label': 'Trễ giờ', 'icon': Icons.warning, 'color': Colors.amber},
      {'value': 'arrived', 'label': 'Đã đến', 'icon': Icons.location_on, 'color': Colors.teal},
      {'value': 'cancelled', 'label': 'Đã hủy', 'icon': Icons.cancel, 'color': Colors.red},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.update, color: Colors.blue),
              SizedBox(width: 8),
              Text('Cập nhật trạng thái'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuyến đi: ${trip.operatorName ?? 'N/A'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'ID: ${trip.tripId}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Chọn trạng thái mới:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                ...statusOptions.map((option) {
                  final isCurrentStatus = option['value'] == trip.status;
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isCurrentStatus ? (option['color'] as Color).withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrentStatus ? Border.all(
                        color: (option['color'] as Color).withOpacity(0.3),
                      ) : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (option['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          option['icon'] as IconData,
                          color: option['color'] as Color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        option['label'] as String,
                        style: TextStyle(
                          fontWeight: isCurrentStatus ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrentStatus ? (option['color'] as Color) : null,
                        ),
                      ),
                      trailing: isCurrentStatus 
                        ? Icon(Icons.check, color: option['color'] as Color)
                        : null,
                      onTap: isCurrentStatus ? null : () {
                        Navigator.of(context).pop();
                        _updateTripStatus(trip, option['value'] as String);
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
          ],
        );
      },
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
      case 'departed':
        return 'Đã khởi hành';
      case 'on_time':
        return 'Đúng giờ';
      case 'delayed':
        return 'Trễ giờ';
      case 'arrived':
        return 'Đã đến';
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Danh Sách Chuyến Đi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        shadowColor: Colors.grey.withOpacity(0.1),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.refresh, color: Color.fromARGB(255, 27, 170, 72), size: 20),
            ),
            onPressed: _fetchTrips,
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout, color: Colors.red[600], size: 20),
            ),
            onPressed: _logout,
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Header with loading
          if (isLoading) 
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 27, 170, 72)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải danh sách chuyến đi...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          // Trip count info
          if (!isLoading && trips.isNotEmpty)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 27, 170, 72),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.directions_bus, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng cộng',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 27, 170, 72),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${trips.length} chuyến đi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 27, 170, 72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedTripId != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Đã chọn',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber[600], size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nhấn vào chuyến đi để xem khách hàng • Nhấn giữ để chọn quét QR',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: trips.isEmpty && !isLoading
                ? Center(
                    child: Container(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.directions_bus_filled,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Không có chuyến đi nào',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Hiện tại chưa có chuyến đi nào được phân công',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _fetchTrips,
                            icon: Icon(Icons.refresh),
                            label: Text('Tải lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final isSelected = selectedTripId == trip.tripId;
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected 
                                ? Color.fromARGB(255, 27, 170, 72).withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                              blurRadius: isSelected ? 15 : 10,
                              offset: Offset(0, isSelected ? 8 : 5),
                            ),
                          ],
                          border: isSelected 
                            ? Border.all(color: Color.fromARGB(255, 27, 170, 72).withOpacity(0.5), width: 2)
                            : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              // Chuyển sang màn hình danh sách khách hàng
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PassengerListScreen(trip: trip),
                                ),
                              );
                            },
                            onLongPress: () {
                              // Long press để chọn trip cho quét QR
                              setState(() {
                                selectedTripId = trip.tripId;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã chọn chuyến đi để quét QR'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isSelected 
                                              ? [Color.fromARGB(255, 27, 170, 72), Color.fromARGB(255, 27, 170, 72)]
                                              : [Colors.grey[400]!, Colors.grey[600]!],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.directions_bus,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${trip.operatorName ?? 'Nhà xe không xác định'}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'ID: ${trip.tripId ?? 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Nút cập nhật status
                                      Container(
                                        margin: EdgeInsets.only(right: 8),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(8),
                                            onTap: () => _showStatusUpdateDialog(trip),
                                            child: Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.blue[200]!),
                                              ),
                                              child: Icon(
                                                Icons.update,
                                                color: Colors.blue[600],
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Colors.green[600],
                                            size: 20,
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 16),
                                  
                                  // Route info
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        if (trip.route?.startLocation != null)
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: Colors.green[600],
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Từ: ${trip.route!.startLocation}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (trip.route?.startLocation != null && trip.route?.endLocation != null)
                                          Container(
                                            margin: EdgeInsets.symmetric(vertical: 8),
                                            height: 20,
                                            child: Row(
                                              children: [
                                                SizedBox(width: 4),
                                                Container(
                                                  width: 1,
                                                  color: Colors.grey[300],
                                                ),
                                                SizedBox(width: 8),
                                                Icon(Icons.more_vert, color: Colors.grey[400], size: 16),
                                              ],
                                            ),
                                          ),
                                        if (trip.route?.endLocation != null)
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: Colors.red[600],
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Đến: ${trip.route!.endLocation}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  
                                  SizedBox(height: 16),
                                  
                                  // Time and status row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.schedule, size: 16, color: Color.fromARGB(255, 27, 170, 72)),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _formatDateTime(trip.departureTime) ?? 'Chưa có thời gian',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: trip.status == 'scheduled' ? Colors.blue[50] : 
                                                 trip.status == 'departed' ? Colors.orange[50] :
                                                 trip.status == 'on_time' ? Colors.green[50] :
                                                 trip.status == 'delayed' ? Colors.amber[50] : 
                                                 trip.status == 'arrived' ? Colors.teal[50] :
                                                 trip.status == 'cancelled' ? Colors.red[50] : Colors.grey[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: trip.status == 'scheduled' ? Colors.blue[200]! : 
                                                   trip.status == 'departed' ? Colors.orange[200]! :
                                                   trip.status == 'on_time' ? Colors.green[200]! :
                                                   trip.status == 'delayed' ? Colors.amber[200]! : 
                                                   trip.status == 'arrived' ? Colors.teal[200]! :
                                                   trip.status == 'cancelled' ? Colors.red[200]! : Colors.grey[200]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              trip.status == 'scheduled' ? Icons.schedule : 
                                              trip.status == 'departed' ? Icons.directions_bus :
                                              trip.status == 'on_time' ? Icons.check_circle :
                                              trip.status == 'delayed' ? Icons.warning : 
                                              trip.status == 'arrived' ? Icons.location_on :
                                              trip.status == 'cancelled' ? Icons.cancel : Icons.info,
                                              size: 14,
                                              color: trip.status == 'scheduled' ? Colors.blue[600] : 
                                                     trip.status == 'departed' ? Colors.orange[600] :
                                                     trip.status == 'on_time' ? Colors.green[600] :
                                                     trip.status == 'delayed' ? Colors.amber[600] : 
                                                     trip.status == 'arrived' ? Colors.teal[600] :
                                                     trip.status == 'cancelled' ? Colors.red[600] : Colors.grey[600],
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              _getStatusText(trip.status),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: trip.status == 'scheduled' ? Colors.blue[700] : 
                                                       trip.status == 'departed' ? Colors.orange[700] :
                                                       trip.status == 'on_time' ? Colors.green[700] :
                                                       trip.status == 'delayed' ? Colors.amber[700] : 
                                                       trip.status == 'arrived' ? Colors.teal[700] :
                                                       trip.status == 'cancelled' ? Colors.red[700] : Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 16),
                                  
                                  // Bottom info row
                                  Row(
                                    children: [
                                      if (trip.availableSeats != null && trip.totalSeats != null)
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.event_seat, size: 16, color: Colors.grey[600]),
                                                SizedBox(width: 8),
                                                Text(
                                                  '${trip.availableSeats}/${trip.totalSeats} chỗ',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (trip.pricePerSeat != null) ...[
                                        if (trip.availableSeats != null && trip.totalSeats != null)
                                          SizedBox(width: 12),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.green[400]!, Colors.green[600]!],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${_formatPrice(trip.pricePerSeat!)} VNĐ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Bottom action button
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: selectedTripId != null
                    ? LinearGradient(
                        colors: [Color.fromARGB(255, 27, 170, 72), Color.fromARGB(255, 27, 170, 72)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                  color: selectedTripId == null ? Colors.grey[300] : null,
                  boxShadow: selectedTripId != null ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ] : null,
                ),
                child: ElevatedButton.icon(
                  onPressed: selectedTripId != null
                      ? () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => 
                                main_qr.QrScannerScreen(selectedTripId!),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.ease;

                                var tween = Tween(begin: begin, end: end).chain(
                                  CurveTween(curve: curve),
                                );

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                              transitionDuration: Duration(milliseconds: 300),
                            ),
                          );
                        }
                      : null,
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: selectedTripId != null ? Colors.white : Colors.grey[600],
                  ),
                  label: Text(
                    selectedTripId != null ? 'Quét QR Vé' : 'Chọn chuyến đi để tiếp tục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selectedTripId != null ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Error message
          if (errorMessage.isNotEmpty) 
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}