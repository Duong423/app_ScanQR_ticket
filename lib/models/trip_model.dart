import 'package:json_annotation/json_annotation.dart';

part 'trip_model.g.dart';

@JsonSerializable()
class Trip {
  @JsonKey(name: 'trip_id')
  int? tripId;
  
  @JsonKey(name: 'operator_name')
  String? operatorName;
  
  @JsonKey(name: 'departure_time')
  String? departureTime;
  
  @JsonKey(name: 'arrival_time')
  String? arrivalTime;
  
  String? status;
  
  @JsonKey(name: 'price_per_seat')
  double? pricePerSeat;
  
  @JsonKey(name: 'available_seats')
  int? availableSeats;
  
  @JsonKey(name: 'total_seats')
  int? totalSeats;
  
  @JsonKey(name: 'average_rating')
  double? averageRating;
  
  Route? route;
  Amenities? amenities;

  Trip({
    this.tripId,
    this.operatorName,
    this.departureTime,
    this.arrivalTime,
    this.status,
    this.pricePerSeat,
    this.availableSeats,
    this.totalSeats,
    this.averageRating,
    this.route,
    this.amenities,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
  Map<String, dynamic> toJson() => _$TripToJson(this);
  
  // Getter cho bookingId để tương thích với code hiện tại
  String? get bookingId => tripId?.toString();
}

@JsonSerializable()
class Route {
  @JsonKey(name: 'start_location')
  String? startLocation;
  
  @JsonKey(name: 'end_location')
  String? endLocation;

  Route({this.startLocation, this.endLocation});

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  Map<String, dynamic> toJson() => _$RouteToJson(this);
}

@JsonSerializable()
class Amenities {
  bool? tv;
  bool? wifi;
  bool? toilet;
  bool? charging;
  
  @JsonKey(name: 'air_conditioner')
  bool? airConditioner;

  Amenities({
    this.tv,
    this.wifi,
    this.toilet,
    this.charging,
    this.airConditioner,
  });

  factory Amenities.fromJson(Map<String, dynamic> json) => _$AmenitiesFromJson(json);
  Map<String, dynamic> toJson() => _$AmenitiesToJson(this);
}