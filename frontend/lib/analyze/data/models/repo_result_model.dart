import '../../domain/entities/repo_result_entity.dart';

/// A model class that represents the result of analyzing a repository, extending the [RepoResultEntity] and providing a factory constructor for JSON deserialization.
class RepoResultModel extends RepoResultEntity {
  const RepoResultModel({
    required super.repository,
    required super.x,
    required super.y,
    required super.stars,
    required super.forks,
    required super.issues,
    super.language,
    required super.docLength,
  });

  factory RepoResultModel.fromJson(Map<String, dynamic> json) {
    return RepoResultModel(
      repository: json['repository'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      stars: (json['stars'] as num).toInt(),
      forks: (json['forks'] as num? ?? 0).toInt(),
      issues: (json['issues'] as num? ?? 0).toInt(),
      language: json['language'] as String?,
      docLength: (json['doc_length'] as num).toInt(),
    );
  }
}
