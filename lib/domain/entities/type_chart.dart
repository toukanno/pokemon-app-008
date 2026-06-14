/// タイプ相性表。JSON からロードされる。
class TypeChart {
  final List<String> types;
  final Map<String, String> colors;

  /// chart[attacker][defender] = 倍率
  final Map<String, Map<String, double>> chart;

  const TypeChart({
    required this.types,
    required this.colors,
    required this.chart,
  });

  factory TypeChart.fromJson(Map<String, dynamic> json) {
    final rawChart = json['chart'] as Map<String, dynamic>;
    final parsed = <String, Map<String, double>>{};
    rawChart.forEach((atk, defenders) {
      final inner = <String, double>{};
      (defenders as Map<String, dynamic>).forEach((def, mult) {
        inner[def] = (mult as num).toDouble();
      });
      parsed[atk] = inner;
    });
    final colorMap = <String, String>{};
    (json['colors'] as Map<String, dynamic>).forEach((k, v) {
      colorMap[k] = v as String;
    });
    return TypeChart(
      types: (json['types'] as List).cast<String>(),
      colors: colorMap,
      chart: parsed,
    );
  }

  /// 単一の防御タイプに対する倍率
  double multiplier(String attackType, String defendType) {
    return chart[attackType]?[defendType] ?? 1.0;
  }

  /// 複数の防御タイプ(複合タイプ)に対する合計倍率
  double effectiveness(String attackType, List<String> defendTypes) {
    double m = 1.0;
    for (final t in defendTypes) {
      m *= multiplier(attackType, t);
    }
    return m;
  }
}
