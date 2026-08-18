import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/deadline_model.dart';

class DeadlineRepository {
  final ApiClient _client;
  DeadlineRepository(this._client);

  Future<List<DeadlineModel>> getDeadlines({bool? isCompleted, bool? isOverdue}) async {
    final response = await _client.get(ApiEndpoints.deadlines, queryParameters: {
      if (isCompleted != null) 'isCompleted': isCompleted.toString(),
      if (isOverdue != null) 'isOverdue': isOverdue.toString(),
      'limit': '100',
    });
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => DeadlineModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DeadlineModel>> getTodayDeadlines() async {
    final response = await _client.get(ApiEndpoints.deadlinesToday);
    final list = response.data['data']['deadlines'] as List? ?? [];
    return list.map((e) => DeadlineModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DeadlineModel>> getUpcomingDeadlines({int days = 7}) async {
    final response = await _client.get(ApiEndpoints.deadlinesUpcoming, queryParameters: {'days': days.toString()});
    final list = response.data['data']['deadlines'] as List? ?? [];
    return list.map((e) => DeadlineModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DeadlineModel> createDeadline(Map<String, dynamic> data) async {
    final response = await _client.post(ApiEndpoints.deadlines, data: data);
    return DeadlineModel.fromJson(response.data['data']['deadline'] as Map<String, dynamic>);
  }

  Future<DeadlineModel> completeDeadline(String id) async {
    final response = await _client.post(ApiEndpoints.deadlineComplete(id));
    return DeadlineModel.fromJson(response.data['data']['deadline'] as Map<String, dynamic>);
  }

  Future<void> deleteDeadline(String id) async {
    await _client.delete(ApiEndpoints.deadlineById(id));
  }
}

final deadlineRepositoryProvider = Provider<DeadlineRepository>((ref) {
  return DeadlineRepository(ref.watch(apiClientProvider));
});
