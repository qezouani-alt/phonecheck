import 'test_item.dart';

class TestResult {
  TestResult({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.status = TestStatus.pending,
    Map<String, Object?> measured = const {},
    this.note,
    this.testedAt,
    this.canRetest = true,
    this.simulated = false,
  }) : measured = Map.unmodifiable(measured);
  final String id, category, title, description;
  final TestStatus status;
  final Map<String, Object?> measured;
  final String? note;
  final DateTime? testedAt;
  final bool canRetest, simulated;
  Map<String, Object?> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'description': description,
    'status': status.name,
    'measured': measured,
    'note': note,
    'testedAt': testedAt?.toIso8601String(),
    'canRetest': canRetest,
    'simulated': simulated,
  };
  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
    id: json['id'] as String,
    category: json['category'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    status: TestStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => TestStatus.pending,
    ),
    measured: Map<String, Object?>.from(json['measured'] as Map? ?? {}),
    note: json['note'] as String?,
    testedAt: DateTime.tryParse(json['testedAt'] as String? ?? ''),
    canRetest: json['canRetest'] as bool? ?? true,
    simulated: json['simulated'] == true,
  );
}
