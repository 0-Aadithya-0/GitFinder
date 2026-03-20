import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/analyze_bloc.dart';
import '../bloc/analyze_event.dart';
import '../bloc/analyze_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onInputChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _submit(value.trim());
    });
  }

  void _submit(String input) {
    // Master Prompt: users can input a "comma-separated list of specific
    // repository URLs". Also support newline-separated for multi-line paste.
    if (!input.contains('github.com')) {
      context.read<AnalyzeBloc>().add(AnalyzeByQuery(input));
      return;
    }

    final urls = input
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (urls.isNotEmpty) {
      context.read<AnalyzeBloc>().add(AnalyzeByUrls(urls));
    } else {
      context.read<AnalyzeBloc>().add(AnalyzeByQuery(input));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AnalyzeBloc, AnalyzeState>(
      listener: (context, state) {
        if (state is AnalyzeSuccess) {
          context.go('/vibe-map');
        } else if (state is AnalyzeFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'GitHub Vibe Analyzer',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover how repos cluster by vibe',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8B949E),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  BlocBuilder<AnalyzeBloc, AnalyzeState>(
                    builder: (context, state) {
                      final isLoading = state is AnalyzeLoading;
                      return TextField(
                        controller: _controller,
                        enabled: !isLoading,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText:
                              'Search topic (e.g. "flutter state management")\nor paste GitHub URLs, one per line',
                          suffixIcon: isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () {
                                    final text = _controller.text.trim();
                                    if (text.isNotEmpty) _submit(text);
                                  },
                                ),
                        ),
                        onChanged: _onInputChanged,
                        onSubmitted: (value) {
                          _debounce?.cancel();
                          if (value.trim().isNotEmpty) _submit(value.trim());
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
