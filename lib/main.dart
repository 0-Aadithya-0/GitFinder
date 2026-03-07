import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'analyze/data/datasources/analyze_remote_datasource.dart';
import 'analyze/data/repositories/analyze_repository_impl.dart';
import 'analyze/domain/usecases/analyze_repos_usecase.dart';
import 'analyze/presentation/bloc/analyze_bloc.dart';
import 'app_config.dart';
import 'app_theme.dart';
import 'router/app_router.dart';

void main() {
  runApp(const GitFinderApp());
}

class GitFinderApp extends StatefulWidget {
  const GitFinderApp({super.key});

  @override
  State<GitFinderApp> createState() => _GitFinderAppState();
}

class _GitFinderAppState extends State<GitFinderApp> {
  late final AnalyzeBloc _bloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.backendUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    final datasource = AnalyzeRemoteDatasource(dio);
    final repository = AnalyzeRepositoryImpl(datasource);
    final usecase = AnalyzeReposUsecase(repository);
    _bloc = AnalyzeBloc(usecase);
    _router = createRouter();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: MaterialApp.router(
        title: 'GitHub Vibe Analyzer',
        theme: AppTheme.dark,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
