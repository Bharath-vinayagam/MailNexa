import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/email_model.dart';

class EmailRepository {
  final ApiClient _client;
  EmailRepository(this._client);

  Future<Map<String, dynamic>> getEmails({
    String? category,
    String? priority,
    bool? isRead,
    bool? isShortlisted,
    int page = 1,
    int limit = 20,
    String sortBy = 'receivedAt',
  }) async {
    final response = await _client.get(ApiEndpoints.emails, queryParameters: {
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (isRead != null) 'isRead': isRead.toString(),
      if (isShortlisted == true) 'isShortlisted': 'true',
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<EmailModel> getEmailById(String id) async {
    final response = await _client.get(ApiEndpoints.emailById(id));
    return EmailModel.fromJson(response.data['data']['email'] as Map<String, dynamic>);
  }

  Future<EmailModel> changeCategory(String id, {String? category, String? priority}) async {
    final response = await _client.patch(
      ApiEndpoints.emailChangeCategory(id),
      data: {
        if (category != null) 'category': category,
        if (priority != null) 'priority': priority,
      },
    );
    return EmailModel.fromJson(response.data['data']['email'] as Map<String, dynamic>);
  }

  Future<EmailModel> markApplied(String id) async {
    final response = await _client.post(ApiEndpoints.emailMarkApplied(id));
    return EmailModel.fromJson(response.data['data']['email'] as Map<String, dynamic>);
  }

  Future<void> triggerSync() async {
    await _client.post(ApiEndpoints.emailsSync);
  }

  Future<Map<String, dynamic>> searchEmails(String query, {String? category, String? priority, int page = 1}) async {
    final response = await _client.get(ApiEndpoints.emailsSearch, queryParameters: {
      'q': query,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      'page': page.toString(),
    });
    return response.data as Map<String, dynamic>;
  }

  Future<String> summarizeEmail(String id, {String? customPrompt}) async {
    final response = await _client.post(
      ApiEndpoints.emailSummarize(id),
      data: {
        if (customPrompt != null && customPrompt.isNotEmpty) 'customPrompt': customPrompt,
      },
    );
    return response.data['data']['summary'] as String? ?? 'No summary available.';
  }
}

final emailRepositoryProvider = Provider<EmailRepository>((ref) {
  return EmailRepository(ref.watch(apiClientProvider));
});
