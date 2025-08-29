// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trip _$TripFromJson(Map<String, dynamic> json) => Trip(
      tripId: (json['trip_id'] as num?)?.toInt(),
      operatorName: json['operator_name'] as String?,
      departureTime: json['departure_time'] as String?,
      arrivalTime: json['arrival_time'] as String?,
      status: json['status'] as String?,
      pricePerSeat: (json['price_per_seat'] as num?)?.toDouble(),
      availableSeats: (json['available_seats'] as num?)?.toInt(),
      totalSeats: (json['total_seats'] as num?)?.toInt(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      route: json['route'] == null
          ? null
          : Route.fromJson(json['route'] as Map<String, dynamic>),
      amenities: json['amenities'] == null
          ? null
          : Amenities.fromJson(json['amenities'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TripToJson(Trip instance) => <String, dynamic>{
      'trip_id': instance.tripId,
      'operator_name': instance.operatorName,
      'departure_time': instance.departureTime,
      'arrival_time': instance.arrivalTime,
      'status': instance.status,
      'price_per_seat': instance.pricePerSeat,
      'available_seats': instance.availableSeats,
      'total_seats': instance.totalSeats,
      'average_rating': instance.averageRating,
      'route': instance.route,
      'amenities': instance.amenities,
    };

Route _$RouteFromJson(Map<String, dynamic> json) => Route(
      startLocation: json['start_location'] as String?,
      endLocation: json['end_location'] as String?,
    );

Map<String, dynamic> _$RouteToJson(Route instance) => <String, dynamic>{
      'start_location': instance.startLocation,
      'end_location': instance.endLocation,
    };

Amenities _$AmenitiesFromJson(Map<String, dynamic> json) => Amenities(
      tv: json['tv'] as bool?,
      wifi: json['wifi'] as bool?,
      toilet: json['toilet'] as bool?,
      charging: json['charging'] as bool?,
      airConditioner: json['air_conditioner'] as bool?,
    );

Map<String, dynamic> _$AmenitiesToJson(Amenities instance) => <String, dynamic>{
      'tv': instance.tv,
      'wifi': instance.wifi,
      'toilet': instance.toilet,
      'charging': instance.charging,
      'air_conditioner': instance.airConditioner,
    };
