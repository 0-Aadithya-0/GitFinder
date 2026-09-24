import '../entities/repo_result_entity.dart';
import '../repositories/analyze_repository.dart';

class AnalyzeReposUsecase {
  final AnalyzeRepository _repository;

  const AnalyzeReposUsecase(this._repository);

  Future<List<RepoResultEntity>> byQuery(String query) =>
      _repository.analyzeQuery(query);

  Future<List<RepoResultEntity>> byUrls(List<String> repoUrls) =>
      _repository.analyzeRepos(repoUrls);
}
