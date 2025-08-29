// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'trip_list_screen.dart'; // Chuyển đến màn hình chuyến đi sau đăng nhập
import '/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng Nhập')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Tên đăng nhập'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                
                try {
                  final token = await ApiService().login(_usernameController.text, _passwordController.text);
                  print('Login successful, token: $token'); // Debug
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => TripListScreen()),
                  );
                } catch (e) {
                  print('Login error: $e'); // Debug
                  setState(() {
                    _errorMessage = 'Lỗi: $e';
                  });
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: _isLoading 
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Đăng Nhập'),
            ),
            if (_errorMessage.isNotEmpty) Text(_errorMessage, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}