import 'package:grahmitracus/core/services/api_endpoints.dart';
import 'package:grahmitracus/core/services/api_service.dart';
import 'package:grahmitracus/models/profile/referral_model.dart';

class ReferralRepo {
  final ApiService _apiService = ApiService();

  Future<ReferralModel> getReferralHistory() async {
    final response = await _apiService.get(ApiEndpoints.myReferrals);
    final data = response.data as Map<String, dynamic>;
    
    if (data['success'] == true || data['friends'] != null) {
      return ReferralModel.fromJson(data);
    }
    
    throw Exception('Failed to fetch referral history');
  }
}
