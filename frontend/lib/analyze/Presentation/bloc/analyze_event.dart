import 'package:equatable/equatable.dart';

abstract class AnalyzeEvent extends Equatable {
  const AnalyzeEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzeByQuery extends AnalyzeEvent {
  final String query;
  const AnalyzeByQuery(this.query);

  @override
  List<Object?> get props => [query];
}

class AnalyzeByUrls extends AnalyzeEvent {
  final List<String> repoUrls;
  const AnalyzeByUrls(this.repoUrls);

  @override
  List<Object?> get props => [repoUrls];
}

class AnalyzeReset extends AnalyzeEvent {
  const AnalyzeReset();
}
