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
      // Để trống để người dùng tự nhập, không có IP mặc định cố định
      for (int i = 0; i < 4; i++) {
        _controllers[i].text = '';
      }
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
          throw Exception('Địa chỉ IP không hợp lệ (mỗi phần từ 0-255)');
        }
      }

      // Tạo IP string và kiểm tra format
      final ip = _controllers.map((c) => c.text.trim()).join('.');
      
      // Validate IP format bằng RegExp
      if (!_isValidIpFormat(ip)) {
        throw Exception('Định dạng địa chỉ IP không hợp lệ');
      }
      
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

  bool _isValidIpFormat(String ip) {
    // RegExp để validate IPv4 address - hỗ trợ tất cả dạng IP hợp lệ
    final ipv4Pattern = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );
    
    if (!ipv4Pattern.hasMatch(ip)) {
      return false;
    }
    
    // Kiểm tra thêm: không cho phép IP reserved hoặc không hợp lệ
    final parts = ip.split('.').map(int.parse).toList();
    
    // 0.0.0.0 không hợp lệ
    if (parts.every((part) => part == 0)) {
      return false;
    }
    
    // 255.255.255.255 là broadcast
    if (parts.every((part) => part == 255)) {
      return false;
    }
    
    // Các IP khác đều hợp lệ (bao gồm private, public, loopback, etc.)
    return true;
  }

  Widget _buildPresetButton(String label, String ip) {
    return GestureDetector(
      onTap: () => _setPresetIp(ip),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              ip,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setPresetIp(String ip) {
    final parts = ip.split('.');
    if (parts.length == 4) {
      for (int i = 0; i < 4; i++) {
        _controllers[i].text = parts[i];
      }
      setState(() {
        _errorMessage = '';
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
    // Logic thông minh để tự động chuyển focus dựa trên giá trị nhập
    if (value.isNotEmpty) {
      final num = int.tryParse(value);
      if (num != null && num >= 0 && num <= 255) {
        // Tự động chuyển focus dựa trên context thông minh
        bool shouldMoveNext = false;
        
        if (value.length == 3) {
          // Đã nhập đủ 3 chữ số, luôn chuyển
          shouldMoveNext = true;
        } else if (value.length == 2) {
          // Nếu nhập 2 chữ số và số >= 26, có thể chuyển
          // Vì người dùng có thể muốn nhập 192, 168, 221, v.v.
          if (num >= 26) {
            shouldMoveNext = true;
          }
        } else if (value.length == 1) {
          // Chỉ chuyển nếu số >= 4 (vì hiếm khi có IP bắt đầu bằng 4xx, 5xx, ...)
          // Trừ khi là các số đặc biệt như 1, 2, 3 trong context phù hợp
          if (num >= 4) {
            shouldMoveNext = true;
          }
        }
        
        if (shouldMoveNext && index < 3) {
          // Delay nhỏ để người dùng có thể tiếp tục nhập nếu muốn
          Future.delayed(Duration(milliseconds: 500), () {
            if (_controllers[index].text == value && value.isNotEmpty) {
              _focusNodes[index + 1].requestFocus();
            }
          });
        }
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
                                        contentPadding: EdgeInsets.symmetric(vertical: 18),
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
                          
                          // Quick preset buttons
                          Text(
                            'IP phổ biến:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          
                          SizedBox(height: 8),
                          
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPresetButton('Localhost', '127.0.0.1'),
                              _buildPresetButton('Router', '192.168.1.1'),
                              _buildPresetButton('Private A', '10.0.0.1'),
                              _buildPresetButton('Private B', '172.16.0.1'),
                              _buildPresetButton('Custom', '10.221.36.86'),
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
                                    'Ví dụ: 10.221.36.86, 192.168.1.9, 172.16.0.1, 203.113.1.100',
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
