class Passenger {
  final int? ticketId;
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final String? seatNumber;
  final String? ticketCode;
  final String? status;
  final DateTime? bookingDate;
  final double? ticketPrice;

  Passenger({
    this.ticketId,
    this.fullName,
    this.phoneNumber,
    this.email,
    this.seatNumber,
    this.ticketCode,
    this.status,
    this.bookingDate,
    this.ticketPrice,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      ticketId: json['ticketId'],
      fullName: json['passengerName'], 
      phoneNumber: json['passengerPhone'], 
      seatNumber: json['seatNumber'],
      ticketCode: json['ticketCode'],
      status: json['status'],
      bookingDate: json['bookingDate'] != null 
        ? DateTime.parse(json['bookingDate']) 
        : null,
      ticketPrice: json['ticketPrice']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'passengerName': fullName,
      'passengerPhone': phoneNumber,
      'email': email,
      'seatNumber': seatNumber,
      'ticketCode': ticketCode,
      'status': status,
      'bookingDate': bookingDate?.toIso8601String(),
      'ticketPrice': ticketPrice,
    };
  }
}
