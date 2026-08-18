import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/application_model.dart';

class ApplicationRepository {
  final ApiClient _client;
  ApplicationRepository(this._client);

  Future<List<ApplicationModel>> getApplications({String? status, String? companyName}) async {
    final response = await _client.get(ApiEndpoints.applications, queryParameters: {
      if (status != null) 'status': status,
      if (companyName != null) 'companyName': companyName,
      'limit': '100',
    });
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getGroupedApplications() async {
    final response = await _client.get(ApiEndpoints.applicationsGrouped);
    final groups = response.data['data']['groups'] as List? ?? [];
    return groups.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<ApplicationModel> getApplicationById(String id) async {
    final response = await _client.get(ApiEndpoints.applicationById(id));
    return ApplicationModel.fromJson(response.data['data']['application'] as Map<String, dynamic>);
  }

  Future<ApplicationModel> createApplication(Map<String, dynamic> data) async {
    final response = await _client.post(ApiEndpoints.applications, data: data);
    return ApplicationModel.fromJson(response.data['data']['application'] as Map<String, dynamic>);
  }

  Future<ApplicationModel> updateApplication(String id, Map<String, dynamic> data) async {
    final response = await _client.put(ApiEndpoints.applicationById(id), data: data);
    return ApplicationModel.fromJson(response.data['data']['application'] as Map<String, dynamic>);
  }

  Future<ApplicationModel> updateStatus(String id, String status, {String? note}) async {
    final response = await _client.patch(
      ApiEndpoints.applicationStatus(id),
      data: {
        'status': status,
        if (note != null) 'note': note,
      },
    );
    return ApplicationModel.fromJson(response.data['data']['application'] as Map<String, dynamic>);
  }

  Future<void> deleteApplication(String id) async {
    await _client.delete(ApiEndpoints.applicationById(id));
  }
}

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepository(ref.watch(apiClientProvider));
});
