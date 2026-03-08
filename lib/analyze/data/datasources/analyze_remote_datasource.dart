import 'package:dio/dio.dart';
import '../../domain/entities/repo_result_entity.dart';
import '../models/repo_result_model.dart';

/// Datasource responsible for fetching analysis results from the remote API.
class AnalyzeRemoteDatasource {
  final Dio _dio;

  const AnalyzeRemoteDatasource(this._dio);

  Future<List<RepoResultEntity>> analyzeQuery(String query) async {
    final response = await _dio.post<List<dynamic>>(
      '/analyze',
      data: {'query': query},
    );
    return _parseResponse(response.data!);
  }

  Future<List<RepoResultEntity>> analyzeRepos(List<String> repoUrls) async {
    final response = await _dio.post<List<dynamic>>(
      '/analyze',
      data: {'repos': repoUrls},
    );
    return _parseResponse(response.data!);
  }

  List<RepoResultEntity> _parseResponse(List<dynamic> data) {
    return data
        .map((e) => RepoResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
