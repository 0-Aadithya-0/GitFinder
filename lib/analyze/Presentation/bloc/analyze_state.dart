import 'package:equatable/equatable.dart';
import '../../domain/entities/repo_result_entity.dart';

abstract class AnalyzeState extends Equatable {
  const AnalyzeState();

  @override
  List<Object?> get props => [];
}

class AnalyzeInitial extends AnalyzeState {
  const AnalyzeInitial();
}

class AnalyzeLoading extends AnalyzeState {
  const AnalyzeLoading();
}

class AnalyzeSuccess extends AnalyzeState {
  final List<RepoResultEntity> results;
  const AnalyzeSuccess(this.results);

  @override
  List<Object?> get props => [results];
}

class AnalyzeFailure extends AnalyzeState {
  final String message;
  const AnalyzeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
