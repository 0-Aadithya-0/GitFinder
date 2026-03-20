import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/repo_result_entity.dart';
import '../../../app_theme.dart';
import '../bloc/analyze_bloc.dart';
import '../bloc/analyze_event.dart';
import '../bloc/analyze_state.dart';
import '../widgets/deep_dive_radar.dart';

class VibeMapPage extends StatelessWidget {
  const VibeMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyzeBloc, AnalyzeState>(
      builder: (context, state) {
        if (state is! AnalyzeSuccess) {
          // Guard: redirect home if BLoC was reset (e.g. hot-reload).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Vibe Map — ${state.results.length} repos',
              style: const TextStyle(fontSize: 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.read<AnalyzeBloc>().add(const AnalyzeReset());
                context.go('/');
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Legend(results: state.results),
                const SizedBox(height: 12),
                Expanded(
                  child: _ScatterPlot(results: state.results),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Tap a dot for details',
                    style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScatterPlot extends StatelessWidget {
  final List<RepoResultEntity> results;

  const _ScatterPlot({required this.results});

  @override
  Widget build(BuildContext context) {
    // Pre-build index → name map. getTooltipItems only receives the ScatterSpot
    // object, so we resolve the name by looking up spots.indexOf(spot) here.
    // This avoids firstWhere which triggers a nullable-inference false positive.
    final nameByIndex = <int, String>{};
    for (var i = 0; i < results.length; i++) {
      nameByIndex[i] = results[i].repository;
    }

    final spots = <ScatterSpot>[];
    for (final r in results) {
      spots.add(
        ScatterSpot(
          r.x,
          r.y,
          dotPainter: FlDotCirclePainter(
            radius: 8,
            color: AppTheme.languageColor(r.language),
            strokeWidth: 1.5,
            strokeColor: Colors.white.withOpacity(0.3),
          ),
        ),
      );
    }

    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots,
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: const Color(0xFF21262D), strokeWidth: 1),
          getDrawingVerticalLine: (_) =>
              FlLine(color: const Color(0xFF21262D), strokeWidth: 1),
        ),
        titlesData: const FlTitlesData(show: false),
        scatterTouchData: ScatterTouchData(
          enabled: true,
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF161B22),
            getTooltipItems: (spot) {
              final index = spots.indexOf(spot);
              final name = nameByIndex[index] ?? '';
              return ScatterTooltipItem(
                name,
                textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                bottomMargin: 8,
              );
            },
          ),
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.touchedSpot != null) {
              final index = response!.touchedSpot!.spotIndex;
              final repo = results[index];
              showDialog<void>(
                context: context,
                builder: (_) => DeepDiveRadar(
                  repo: repo,
                  allRepos: results,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<RepoResultEntity> results;

  const _Legend({required this.results});

  @override
  Widget build(BuildContext context) {
    final languages = results
        .map((r) => r.language ?? 'Unknown')
        .toSet()
        .toList()
      ..sort();

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: languages.map((lang) {
        final color = AppTheme.languageColor(lang == 'Unknown' ? null : lang);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              lang,
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11),
            ),
          ],
        );
      }).toList(),
    );
  }
}
