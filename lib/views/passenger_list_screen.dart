// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:readhoadon/services/api_service.dart';
import 'package:readhoadon/models/passenger_model.dart';
import 'package:readhoadon/models/trip_model.dart';
import 'login_screen.dart';

class PassengerListScreen extends StatefulWidget {
  final Trip trip;

  const PassengerListScreen({super.key, required this.trip});

  @override
  _PassengerListScreenState createState() => _PassengerListScreenState();
}

class _PassengerListScreenState extends State<PassengerListScreen> {
  List<Passenger> passengers = [];
  String errorMessage = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPassengers();
  }

  Future<void> _fetchPassengers() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      final api = ApiService();
      final fetchedPassengers = await api.getTripPassengers(widget.trip.tripId!);
      setState(() {
        passengers = fetchedPassengers;
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

  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    try {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'valid':
        return 'Hợp lệ';
      case 'used':
        return 'Đã sử dụng';
      case 'cancelled':
        return 'Đã hủy';
      case 'checked_in':
        return 'Đã check-in';
      case 'pending':
        return 'Chờ xử lý';
      case 'confirmed':
        return 'Đã xác nhận';
      default:
        return status ?? 'Không xác định';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'valid':
        return Colors.green;
      case 'used':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      case 'checked_in':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'valid':
        return Icons.check_circle;
      case 'used':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel;
      case 'checked_in':
        return Icons.login;
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.verified;
      default:
        return Icons.help;
    }
  }

  String _formatPrice(double? price) {
    if (price == null) return 'N/A';
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
          'Danh Sách Khách Hàng',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        shadowColor: Colors.grey.withOpacity(0.1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
            onPressed: _fetchPassengers,
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Trip info header
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            widget.trip.operatorName ?? 'Nhà xe không xác định',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 27, 170, 72),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ID: ${widget.trip.tripId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.trip.route?.startLocation != null && widget.trip.route?.endLocation != null) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green[600], size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.trip.route!.startLocation} → ${widget.trip.route!.endLocation}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Loading indicator
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
                    'Đang tải danh sách khách hàng...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Passenger count info
          if (!isLoading && passengers.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.people, color: Colors.orange[600], size: 20),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng số khách hàng',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${passengers.length} hành khách',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 16),

          // Passenger list
          Expanded(
            child: passengers.isEmpty && !isLoading
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
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Không có khách hàng nào',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Chuyến đi này chưa có khách hàng đặt vé',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: passengers.length,
                    itemBuilder: (context, index) {
                      final passenger = passengers[index];
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
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
                                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.person,
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
                                          passenger.fullName ?? 'Không có tên',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.grey[800],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Ghế: ${passenger.seatNumber ?? 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                passenger.ticketCode ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue[600],
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    constraints: BoxConstraints(maxWidth: 120),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(passenger.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getStatusColor(passenger.status).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getStatusIcon(passenger.status),
                                          size: 14,
                                          color: _getStatusColor(passenger.status),
                                        ),
                                        SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _getStatusText(passenger.status),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _getStatusColor(passenger.status),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Contact info
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    if (passenger.phoneNumber != null)
                                      Row(
                                        children: [
                                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              passenger.phoneNumber!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (passenger.phoneNumber != null && passenger.email != null)
                                      SizedBox(height: 8),
                                    if (passenger.email != null)
                                      Row(
                                        children: [
                                          Icon(Icons.email, size: 16, color: Colors.grey[600]),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              passenger.email!,
                                              style: TextStyle(
                                                fontSize: 14,
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
                              
                              // Bottom info row
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  if (passenger.bookingDate != null)
                                    Container(
                                      constraints: BoxConstraints(
                                        minWidth: 150,
                                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                                      ),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.schedule, size: 16, color: Color.fromARGB(255, 27, 170, 72)),
                                          SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              _formatDateTime(passenger.bookingDate) ?? 'N/A',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (passenger.ticketPrice != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.green[400]!, Colors.green[600]!],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_formatPrice(passenger.ticketPrice)} VNĐ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
