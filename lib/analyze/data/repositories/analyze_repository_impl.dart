import 'package:dio/dio.dart';

import '../../domain/entities/repo_result_entity.dart';
import '../../domain/exceptions.dart';
import '../../domain/repositories/analyze_repository.dart';
import '../datasources/analyze_remote_datasource.dart';

class AnalyzeRepositoryImpl implements AnalyzeRepository {
  final AnalyzeRemoteDatasource _datasource;

  const AnalyzeRepositoryImpl(this._datasource);

  @override
  Future<List<RepoResultEntity>> analyzeQuery(String query) async {
    try {
      return await _datasource.analyzeQuery(query);
    } on DioException catch (e) {
      throw AnalyzeException(e.message ?? 'Network error');
    }
  }

  @override
  Future<List<RepoResultEntity>> analyzeRepos(List<String> repoUrls) async {
    try {
      return await _datasource.analyzeRepos(repoUrls);
    } on DioException catch (e) {
      throw AnalyzeException(e.message ?? 'Network error');
    }
  }
}
