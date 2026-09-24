import 'package:equatable/equatable.dart';

/// A domain entity representing the result of analyzing a repository.

class RepoResultEntity extends Equatable {
  final String repository;
  final double x;
  final double y;
  final int stars;
  final int forks;
  final int issues;
  final String? language;
  final int docLength;

  const RepoResultEntity({
    required this.repository,
    required this.x,
    required this.y,
    required this.stars,
    required this.forks,
    required this.issues,
    this.language,
    required this.docLength,
  });

  @override
  List<Object?> get props =>
      [repository, x, y, stars, forks, issues, language, docLength];
}
