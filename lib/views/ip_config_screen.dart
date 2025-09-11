// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readhoadon/services/api_service.dart';
import 'login_screen.dart';

class IpConfigScreen extends StatefulWidget {
  @override
  _IpConfigScreenState createState() => _IpConfigScreenState();
}

class _IpConfigScreenState extends State<IpConfigScreen> {
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  
  final List<FocusNode> _focusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip');
    if (savedIp != null) {
      final parts = savedIp.split('.');
      if (parts.length == 4) {
        for (int i = 0; i < 4; i++) {
          _controllers[i].text = parts[i];
        }
      }
    } else {
      // IP mặc định
      _controllers[0].text = '192';
      _controllers[1].text = '168';
      _controllers[2].text = '1';
      _controllers[3].text = '9';
    }
  }

  Future<void> _saveAndTestIp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Kiểm tra tính hợp lệ của IP
      for (int i = 0; i < 4; i++) {
        final text = _controllers[i].text.trim();
        if (text.isEmpty) {
          throw Exception('Vui lòng nhập đầy đủ địa chỉ IP');
        }
        final num = int.tryParse(text);
        if (num == null || num < 0 || num > 255) {
          throw Exception('Địa chỉ IP không hợp lệ (0-255)');
        }
      }

      // Tạo IP string
      final ip = _controllers.map((c) => c.text.trim()).join('.');
      
      // Lưu IP vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', ip);
      
      // Cập nhật baseUrl trong ApiService
      ApiService.updateBaseUrl('http://$ip:8080/api');
      
      // Test kết nối bằng cách gọi một API đơn giản
      await _testConnection();
      
      // Nếu thành công, chuyển sang màn hình đăng nhập
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    try {
      
      await ApiService().testConnection();
    } catch (e) {
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('No route to host') ||
          e.toString().contains('Connection timed out')) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra địa chỉ IP.');
      }
     
    }
  }

  void _onIpPartChanged(String value, int index) {
    if (value.length >= 3 || (value.isNotEmpty && int.tryParse(value) != null && int.parse(value) > 25)) {
      // Tự động chuyển sang ô tiếp theo
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      }
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon và title
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.settings_ethernet,
                        size: 64,
                        color: Color.fromARGB(255, 27, 170, 72),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    Text(
                      'Cấu hình Server',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    Text(
                      'Nhập địa chỉ IP của server để kết nối',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 48),
                    
                    // IP Input
                    Container(
                      padding: EdgeInsets.all(24),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Địa chỉ IP Server',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // IP Input Fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < 4; i++) ...[
                                Expanded(
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _focusNodes[i].hasFocus 
                                          ? Color.fromARGB(255, 27, 170, 72) 
                                          : Colors.grey[300]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _controllers[i],
                                      focusNode: _focusNodes[i],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '0',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                      onChanged: (value) => _onIpPartChanged(value, i),
                                      onTap: () {
                                        setState(() {});
                                      },
                                      onEditingComplete: () {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ),
                                if (i < 3)
                                  Container(
                                    margin: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '.',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Example
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Color.fromARGB(255, 27, 170, 72), size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ví dụ: 192.168.1.9 hoặc 10.0.0.1',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color.fromARGB(255, 27, 170, 72),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Error message
                    if (_errorMessage.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
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
                                _errorMessage,
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
                  ],
                ),
              ),
              
              // Connect button
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndTestIp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 27, 170, 72),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Đang kết nối...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Kết nối',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
