
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

      final ip = _controllers.map((c) => c.text.trim()).join('.');

      if (!_isValidIpFormat(ip)) {
        throw Exception('Định dạng địa chỉ IP không hợp lệ');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', ip);

      ApiService.updateBaseUrl('http://$ip:8080/api');

      await _testConnection();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  bool _isValidIpFormat(String ip) {
    final ipv4Pattern = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );

    if (!ipv4Pattern.hasMatch(ip)) {
      return false;
    }

    final parts = ip.split('.').map(int.parse).toList();

    if (parts.every((part) => part == 0)) {
      return false;
    }

    if (parts.every((part) => part == 255)) {
      return false;
    }

    return true;
  }

  Widget _buildPresetButton(String label, String ip) {
    return GestureDetector(
      onTap: () => _setPresetIp(ip),
      child: Container(
        width: 100, // Giới hạn chiều rộng
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              ip,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
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
      final apiService = ApiService();
      await apiService.testConnection();
      print('Kết nối thành công đến server');
    } catch (e) {
      String errorMessage = 'Không thể kết nối đến server';
      String errorDetails = e.toString().toLowerCase();

      if (errorDetails.contains('connection refused') ||
          errorDetails.contains('connection denied')) {
        errorMessage = 'Server từ chối kết nối. Kiểm tra IP và port.';
      } else if (errorDetails.contains('network is unreachable') ||
                 errorDetails.contains('no route to host')) {
        errorMessage = 'Không thể truy cập mạng. Kiểm tra kết nối internet và IP.';
      } else if (errorDetails.contains('connection timed out') ||
                 errorDetails.contains('timeout')) {
        errorMessage = 'Timeout kết nối. Server có thể không khả dụng.';
      } else if (errorDetails.contains('host lookup failed') ||
                 errorDetails.contains('socketexception')) {
        errorMessage = 'Địa chỉ IP không hợp lệ hoặc không tồn tại.';
      } else if (errorDetails.contains('format')) {
        errorMessage = 'Định dạng IP không đúng.';
      } else {
        errorMessage = 'Lỗi kết nối: ${e.toString().replaceAll('Exception: ', '')}';
      }

      throw Exception(errorMessage);
    }
  }

  void _onIpPartChanged(String value, int index) {
    if (value.isNotEmpty) {
      final num = int.tryParse(value);
      if (num != null && num >= 0 && num <= 255) {
        bool shouldMoveNext = false;

        if (value.length == 3) {
          shouldMoveNext = true;
        } else if (value.length == 2) {
          if (num >= 26) {
            shouldMoveNext = true;
          }
        } else if (value.length == 1) {
          if (num >= 4) {
            shouldMoveNext = true;
          }
        }

        if (shouldMoveNext && index < 3) {
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 27, 170, 72),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.settings_ethernet,
                    size: 48,
                    color: Color.fromARGB(255, 27, 170, 72),
                  ),
                ),
                
                SizedBox(height: 16),
                
                Text(
                  'Cấu hình Server',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                
                SizedBox(height: 8),
                
                Text(
                  'Nhập địa chỉ IP của server để kết nối',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 24),
                
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Địa chỉ IP Server',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      
                      SizedBox(height: 12),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < 4; i++) ...[
                            SizedBox(
                              width: 70,
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 16),
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
                            if (i < 3)
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '.',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                      
                      SizedBox(height: 12),
                      
                      Text(
                        'IP phổ biến:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      
                      SizedBox(height: 8),
                      
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
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
                      ),
                      
                      SizedBox(height: 12),
                      
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Color.fromARGB(255, 27, 170, 72), size: 14),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Ví dụ: 10.221.36.86, 192.168.1.9, 172.16.0.1, 203.113.1.100',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color.fromARGB(255, 27, 170, 72),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_errorMessage.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
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
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Đang kết nối...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Kết nối',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}