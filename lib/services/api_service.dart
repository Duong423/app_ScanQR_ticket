import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/models/trip_model.dart';
import '/models/passenger_model.dart';

class ApiService {
  static String baseUrl = 'http://192.168.1.9:8080/api'; // URL mặc định
  
  // Cập nhật baseUrl
  static void updateBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;
  }
  
  //test ip kết nối server
  Future<void> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));
      
      // Nếu server phản hồi (bất kể status code) thì coi như kết nối thành công
      print('Server responded with status: ${response.statusCode}');
    } catch (e) {
      // Ném lại exception để caller xử lý
      rethrow;
    }
  }

  // Đăng nhập và lưu token
  Future<String> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // API trả về token trong result.accessToken
        final token = data['result']?['accessToken'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', token); // Lưu token
          return token;
        } else {
          throw Exception('Token không hợp lệ - không tìm thấy accessToken trong response');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Lấy danh sách chuyến đi của tài xế
  Future<List<Trip>> getDriverTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) throw Exception('Chưa đăng nhập');

      final response = await http.get(
        Uri.parse('$baseUrl/trips/driver/my-trips'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response data: $data'); 
        
        // Kiểm tra nếu data là Map và có key 'result' hoặc tương tự
        if (data is Map<String, dynamic>) {
          // Nếu API trả về format như {result: [...]} hoặc {data: [...]}
          List<dynamic> trips;
          if (data.containsKey('result')) {
            trips = data['result'] as List<dynamic>;
          } else if (data.containsKey('data')) {
            trips = data['data'] as List<dynamic>;
          } else if (data.containsKey('trips')) {
            trips = data['trips'] as List<dynamic>;
          } else {
            throw Exception('Không tìm thấy danh sách chuyến đi trong response: ${data.keys}');
          }
          return trips.map((json) => Trip.fromJson(json)).toList();
        } else if (data is List<dynamic>) {
          return data.map((json) => Trip.fromJson(json)).toList();
        } else {
          throw Exception('Format response không đúng: ${data.runtimeType}');
        }
      } else if (response.statusCode == 401) {
        await prefs.remove('accessToken');
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể lấy danh sách chuyến đi');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<Map<String, dynamic>> validateBookingTrip(int tripId, String bookingCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) throw Exception('Chưa đăng nhập');

      print('Calling API: $baseUrl/tickets/validate-booking-trip');
      print('Request body: {tripId: $tripId, bookingCode: $bookingCode}');

      final response = await http.post(
        Uri.parse('$baseUrl/tickets/validate-booking-trip'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'tripId': tripId, 'bookingCode': bookingCode}),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await prefs.remove('accessToken');
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Vé này không thuộc về chuyến đi hiện tại hoặc chuyến đi không tồn tại');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Cập nhật trạng thái vé
  Future<Map<String, dynamic>> updateTicketStatus(List<String> ticketCodes, String status, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) throw Exception('Chưa đăng nhập');

      print('Calling API: $baseUrl/tickets/update-status');
      print('Request body: {ticketCodes: $ticketCodes, status: $status, reason: $reason}');

      final response = await http.patch(
        Uri.parse('$baseUrl/tickets/update-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ticketCodes': ticketCodes,
          'status': status,
          'reason': reason,
        }),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await prefs.remove('accessToken');
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể cập nhật trạng thái vé');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Cập nhật trạng thái chuyến đi
  Future<Map<String, dynamic>> updateTripStatus(int tripId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) throw Exception('Chưa đăng nhập');

      print('Calling API: $baseUrl/trips/$tripId/status');
      print('Request body: {status: $status}');

      final response = await http.put(
        Uri.parse('$baseUrl/trips/$tripId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
        }),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await prefs.remove('accessToken');
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể cập nhật trạng thái chuyến đi');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Lấy danh sách khách hàng của chuyến đi
  Future<List<Passenger>> getTripPassengers(int tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) throw Exception('Chưa đăng nhập');

      print('Calling API: $baseUrl/tickets/trip/$tripId/passengers');

      final response = await http.get(
        Uri.parse('$baseUrl/tickets/trip/$tripId/passengers'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Kiểm tra nếu data là Map và có key 'result'
        if (data is Map<String, dynamic>) {
          if (data.containsKey('result') && data['result'] is Map<String, dynamic>) {
            final result = data['result'] as Map<String, dynamic>;
            if (result.containsKey('passengers') && result['passengers'] is List) {
              final passengers = result['passengers'] as List<dynamic>;
              return passengers.map((json) => Passenger.fromJson(json)).toList();
            } else {
              throw Exception('Không tìm thấy danh sách passengers trong result: ${result.keys}');
            }
          } else if (data.containsKey('data')) {
            final passengers = data['data'] as List<dynamic>;
            return passengers.map((json) => Passenger.fromJson(json)).toList();
          } else if (data.containsKey('passengers')) {
            final passengers = data['passengers'] as List<dynamic>;
            return passengers.map((json) => Passenger.fromJson(json)).toList();
          } else {
            throw Exception('Không tìm thấy danh sách khách hàng trong response: ${data.keys}');
          }
        } else if (data is List<dynamic>) {
          return data.map((json) => Passenger.fromJson(json)).toList();
        } else {
          throw Exception('Format response không đúng: ${data.runtimeType}');
        }
      } else if (response.statusCode == 401) {
        await prefs.remove('accessToken');
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể lấy danh sách khách hàng');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
  }

  // Kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken') != null;
  }
}