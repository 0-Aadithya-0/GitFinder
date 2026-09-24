import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/repo_result_entity.dart';

class DeepDiveRadar extends StatelessWidget {
  final RepoResultEntity repo;
  final List<RepoResultEntity> allRepos;

  const DeepDiveRadar({
    super.key,
    required this.repo,
    required this.allRepos,
  });

  /// Min-max normalize [value] across [allValues]. Returns 0.5 if all equal.
  static double _minMax(double value, List<double> allValues) {
    final mn = allValues.reduce(min);
    final mx = allValues.reduce(max);
    if (mx == mn) return 0.5;
    return (value - mn) / (mx - mn);
  }

  @override
  Widget build(BuildContext context) {
    // Collect raw values across all repos for normalization.
    final allStars = allRepos.map((r) => r.stars.toDouble()).toList();
    final allActivity =
        allRepos.map((r) => (r.forks + r.issues).toDouble()).toList();
    final allDocLen = allRepos.map((r) => r.docLength.toDouble()).toList();

    final starsNorm = _minMax(repo.stars.toDouble(), allStars);
    final activityNorm =
        _minMax((repo.forks + repo.issues).toDouble(), allActivity);
    final docNorm = _minMax(repo.docLength.toDouble(), allDocLen);

    final color = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              repo.repository,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (repo.language != null)
              Text(
                repo.language!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8B949E),
                    ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 260,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  tickCount: 4,
                  ticksTextStyle: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 0,
                  ),
                  gridBorderData: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  radarBorderData: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  titleTextStyle: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                  getTitle: (index, _) {
                    const titles = ['Stars', 'Activity', 'Docs'];
                    return RadarChartTitle(text: titles[index]);
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: color.withOpacity(0.2),
                      borderColor: color,
                      borderWidth: 2,
                      entryRadius: 4,
                      dataEntries: [
                        RadarEntry(value: starsNorm),
                        RadarEntry(value: activityNorm),
                        RadarEntry(value: docNorm),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StatRow('Stars', repo.stars),
            _StatRow('Activity (forks + issues)', repo.forks + repo.issues),
            _StatRow('Doc length', repo.docLength),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
          ),
          Text(
            _formatNumber(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
