import 'json.dart';

/// Administrative merge bodies: products (`from_id`/`to_id`) and
/// supermarkets (`from_cnpj`/`to_cnpj`).
class MergeProductsRequest {
  const MergeProductsRequest({required this.fromId, required this.toId});

  final int fromId;
  final int toId;

  JsonMap toJson() => {'from_id': fromId, 'to_id': toId};
}

class MergeSupermarketsRequest {
  const MergeSupermarketsRequest({
    required this.fromCnpj,
    required this.toCnpj,
  });

  final String fromCnpj;
  final String toCnpj;

  JsonMap toJson() => {'from_cnpj': fromCnpj, 'to_cnpj': toCnpj};
}

class MergeResult {
  const MergeResult({this.fromId, this.toId, this.logsMoved, this.dupRemoved});

  factory MergeResult.fromJson(JsonMap json) => MergeResult(
    fromId: json.intOrNull('from_id'),
    toId: json.intOrNull('to_id'),
    logsMoved: json.intOrNull('logs_moved'),
    dupRemoved: json.boolOrNull('dup_removed'),
  );

  final int? fromId;
  final int? toId;
  final int? logsMoved;
  final bool? dupRemoved;

  JsonMap toJson() => {
    'from_id': fromId,
    'to_id': toId,
    'logs_moved': logsMoved,
    'dup_removed': dupRemoved,
  };
}

class MergeSupermarketsResult {
  const MergeSupermarketsResult({
    this.fromId,
    this.toId,
    this.nfcesMoved,
    this.dupRemoved,
  });

  factory MergeSupermarketsResult.fromJson(JsonMap json) =>
      MergeSupermarketsResult(
        fromId: json.intOrNull('from_id'),
        toId: json.intOrNull('to_id'),
        nfcesMoved: json.intOrNull('nfces_moved'),
        dupRemoved: json.boolOrNull('dup_removed'),
      );

  final int? fromId;
  final int? toId;
  final int? nfcesMoved;
  final bool? dupRemoved;

  JsonMap toJson() => {
    'from_id': fromId,
    'to_id': toId,
    'nfces_moved': nfcesMoved,
    'dup_removed': dupRemoved,
  };
}

class DeleteProductResult {
  const DeleteProductResult({this.id, this.logsDeleted});

  factory DeleteProductResult.fromJson(JsonMap json) => DeleteProductResult(
    id: json.intOrNull('id'),
    logsDeleted: json.intOrNull('logs_deleted'),
  );

  final int? id;
  final int? logsDeleted;

  JsonMap toJson() => {'id': id, 'logs_deleted': logsDeleted};
}
