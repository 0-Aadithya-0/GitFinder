import '../entities/repo_result_entity.dart';

abstract class AnalyzeRepository {
  Future<List<RepoResultEntity>> analyzeQuery(String query);
  Future<List<RepoResultEntity>> analyzeRepos(List<String> repoUrls);
}
