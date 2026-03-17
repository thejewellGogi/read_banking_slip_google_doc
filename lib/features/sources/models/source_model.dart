enum SourceStatusType { done, scanning, starting, none }

class SourceModel {
  final String name;
  final int? slipCount;
  final SourceStatusType statusType;
  final int? progress;

  const SourceModel({
    required this.name,
    this.slipCount,
    required this.statusType,
    this.progress,
  });

  SourceModel copyWith({
    String? name,
    int? slipCount,
    SourceStatusType? statusType,
    int? progress,
  }) {
    return SourceModel(
      name: name ?? this.name,
      slipCount: slipCount ?? this.slipCount,
      statusType: statusType ?? this.statusType,
      progress: progress ?? this.progress,
    );
  }
}