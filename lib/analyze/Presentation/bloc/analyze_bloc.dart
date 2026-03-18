import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/exceptions.dart';
import '../../domain/usecases/analyze_repos_usecase.dart';
import 'analyze_event.dart';
import 'analyze_state.dart';

class AnalyzeBloc extends Bloc<AnalyzeEvent, AnalyzeState> {
  final AnalyzeReposUsecase _usecase;

  AnalyzeBloc(this._usecase) : super(const AnalyzeInitial()) {
    on<AnalyzeByQuery>(_onAnalyzeByQuery);
    on<AnalyzeByUrls>(_onAnalyzeByUrls);
    on<AnalyzeReset>(_onReset);
  }

  Future<void> _onAnalyzeByQuery(
    AnalyzeByQuery event,
    Emitter<AnalyzeState> emit,
  ) async {
    emit(const AnalyzeLoading());
    try {
      final results = await _usecase.byQuery(event.query);
      emit(AnalyzeSuccess(results));
    } on AnalyzeException catch (e) {
      emit(AnalyzeFailure(e.message));
    } catch (e) {
      emit(AnalyzeFailure(e.toString()));
    }
  }

  Future<void> _onAnalyzeByUrls(
    AnalyzeByUrls event,
    Emitter<AnalyzeState> emit,
  ) async {
    emit(const AnalyzeLoading());
    try {
      final results = await _usecase.byUrls(event.repoUrls);
      emit(AnalyzeSuccess(results));
    } on AnalyzeException catch (e) {
      emit(AnalyzeFailure(e.message));
    } catch (e) {
      emit(AnalyzeFailure(e.toString()));
    }
  }

  void _onReset(AnalyzeReset event, Emitter<AnalyzeState> emit) {
    emit(const AnalyzeInitial());
  }
}
