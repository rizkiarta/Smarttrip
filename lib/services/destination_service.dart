import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class DestinationModel {
  final String id;
  final String name;
  final String location;
  final String category;
  final String description;
  final double rating;
  final int reviewsCount;
  final String? mainImage;
  final String priceRange;
  final String openHour;
  final String closeHour;
  final double latitude;
  final double longitude;
  final List<String> gallery;

  DestinationModel({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    required this.description,
    required this.rating,
    required this.reviewsCount,
    this.mainImage,
    required this.priceRange,
    required this.openHour,
    required this.closeHour,
    required this.latitude,
    required this.longitude,
    required this.gallery,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      reviewsCount: int.tryParse(json['reviews_count']?.toString() ?? '0') ?? 0,
      mainImage: json['main_image']?.toString(),
      priceRange: json['price_range']?.toString() ?? 'Gratis',
      openHour: json['open_hour']?.toString() ?? '08.00',
      closeHour: json['close_hour']?.toString() ?? '17.00',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      gallery: json['gallery'] != null
          ? (json['gallery'] as List).map((e) => e.toString()).toList()
          : <String>[],
    );
  }

  Map<String, String> toDisplayMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'category': category,
      'rating': rating.toStringAsFixed(1),
      'reviews': '$reviewsCount ulasan',
      'image': mainImage ?? 'assets/images/pulau_wayang.jpg',
      'description': description,
      'price': priceRange,
      'time': '$openHour - $closeHour',
    };
  }
}

class CrowdPredictionModel {
  final String destinationId;
  final String name;
  final String date;
  final String status;
  final String time;
  final String recommendation;
  final String? mainImage;
  final String location;

  CrowdPredictionModel({
    required this.destinationId,
    required this.name,
    required this.date,
    required this.status,
    required this.time,
    required this.recommendation,
    this.mainImage,
    required this.location,
  });

  factory CrowdPredictionModel.fromJson(Map<String, dynamic> json) {
    return CrowdPredictionModel(
      destinationId: json['destination_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Sepi',
      time: json['time']?.toString() ?? '09.00 - 15.00',
      recommendation: json['recommendation']?.toString() ?? '',
      mainImage: json['main_image']?.toString(),
      location: json['location']?.toString() ?? '',
    );
  }
}


class DestinationService {
  DestinationService._internal();
  static final DestinationService instance = DestinationService._internal();

  final ValueNotifier<List<DestinationModel>> destinations =
      ValueNotifier<List<DestinationModel>>([]);

  final ValueNotifier<List<String>> categories =
      ValueNotifier<List<String>>(['Semua']);

  final ValueNotifier<List<CrowdPredictionModel>> crowdPredictions =
      ValueNotifier<List<CrowdPredictionModel>>([]);

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  // Pencarian populer (dipakai di SearchScreen state kosong)
  final ValueNotifier<List<String>> popularSearches =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<bool> isLoadingPopular = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorPopular = ValueNotifier<String?>(null);

  /// Load complete dashboard data from server
  Future<void> fetchDashboardData({String? selectedCategory, String? searchQuery}) async {
    isLoading.value = true;
    error.value = null;

    try {
      final queryParams = <String, String>{
        'per_page': 'all',
      };
      if (selectedCategory != null && selectedCategory != 'Semua') {
        queryParams['category'] = selectedCategory;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }


      final results = await Future.wait([
        ApiService.instance.get('destinations', queryParams: queryParams),
        ApiService.instance.get('categories'),
        ApiService.instance.get('crowd-predictions'),
      ]);

      // Parse Destinations safely
      dynamic destData = results[0];
      if (destData is String) {
        destData = jsonDecode(destData);
      }
      if (destData is Map && destData['data'] is List) {
        final list = (destData['data'] as List)
            .map((item) => DestinationModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        destinations.value = list;
        debugPrint('✅ [DESTINATION SERVICE] Loaded ${list.length} destinations from server');
      }

      // Parse Categories safely
      dynamic catData = results[1];
      if (catData is String) {
        catData = jsonDecode(catData);
      }
      if (catData is Map && catData['data'] is List) {
        final catList = (catData['data'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
        categories.value = ['Semua', ...catList];
      }

      // Parse Crowd Predictions safely
      dynamic crowdData = results[2];
      if (crowdData is String) {
        crowdData = jsonDecode(crowdData);
      }
      if (crowdData is Map && crowdData['data'] is List) {
        final crowdList = (crowdData['data'] as List)
            .map((item) => CrowdPredictionModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        crowdPredictions.value = crowdList;
        debugPrint('✅ [DESTINATION SERVICE] Loaded ${crowdList.length} crowd predictions from server');
      }

    } catch (e) {
      debugPrint('❌ [DESTINATION SERVICE ERROR] $e');
      error.value = e is ApiException ? e.message : e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Single search/filter query
  Future<void> searchDestinations({String? category, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category != 'Semua') {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      dynamic res = await ApiService.instance.get('destinations', queryParams: queryParams);
      if (res is String) {
        res = jsonDecode(res);
      }
      if (res is Map && res['data'] is List) {
        destinations.value = (res['data'] as List)
            .map((item) => DestinationModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

    } catch (e) {
      debugPrint('❌ [SEARCH ERROR] $e');
    }
  }

  /// Ambil daftar kata kunci pencarian populer dari backend.
  /// NOTE: nama endpoint 'search/popular' masih tebakan sementara --
  /// gampang diganti kalau ternyata beda pas backend-nya jadi.
  Future<void> fetchPopularSearches() async {
    isLoadingPopular.value = true;
    errorPopular.value = null;

    try {
      dynamic res = await ApiService.instance.get('search/popular');
      if (res is String) {
        res = jsonDecode(res);
      }

      List<String> list = [];
      if (res is Map && res['data'] is List) {
        list = (res['data'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (res is List) {
        list = res.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }

      popularSearches.value = list;
      debugPrint('✅ [DESTINATION SERVICE] Loaded ${list.length} popular searches from server');
    } catch (e) {
      debugPrint('❌ [POPULAR SEARCH ERROR] $e');
      errorPopular.value = e is ApiException ? e.message : e.toString();
    } finally {
      isLoadingPopular.value = false;
    }
  }
}