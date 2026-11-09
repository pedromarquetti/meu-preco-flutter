import '../../core/models/admin.dart';
import '../../core/models/product.dart';

/// Actions that can be taken for a review item during the batch assignment flow.
enum InternalAssignmentAction {
  create,
  updateExisting,
  merge;

  /// Maps to [AssignmentAction] when preparing API requests (Phase 17).
  /// Note: Merge and Update will have specific repository methods in Phase 17.
  AssignmentAction? toApiAction() => switch (this) {
    InternalAssignmentAction.create => AssignmentAction.create,
    InternalAssignmentAction.updateExisting => AssignmentAction.existing,
    InternalAssignmentAction.merge =>
      null, // Merge uses a different endpoint/method
  };
}

/// Internal model representing a decision for each review item in the batch assignment flow.
/// This is used to track UI state and user decisions before submitting them as API requests.
class ReviewDecision {
  final int? priceLogId; // The original log ID from [ReviewItem]
  final ReviewItem? reviewItem; // Reference to the source review item (for compatibility during transition)

  /// Optional product details fetched during Step 2 of the flow.
  final ProductView? loadedProduct;

  /// User-entered display values for name, brand, and unit.
  /// These are retained as provided by the user to be used in API updates/creates.
  final String? name;
  final String? brand;
  final String? unit;

  /// The action intended for this item: create a new product, update an existing one, or merge with another.
  final InternalAssignmentAction action;

  /// Optional target product ID used when the action is 'merge' (the source is absorbed into this target).
  final int? targetProductId;

  const ReviewDecision({
    this.priceLogId,
    this.reviewItem,
    this.loadedProduct,
    this.name,
    this.brand,
    this.unit,
    required this.action,
    this.targetProductId,
  });

  /// Creates a default decision for a review item with the [InternalAssignmentAction.create] action.
  factory ReviewDecision.createFromItem(ReviewItem item) {
    return ReviewDecision(
      priceLogId: item.priceLogId,
      reviewItem: item,
      action: InternalAssignmentAction.create,
      name: item.suggestedStem ?? item.description ?? '',
      unit: item.unit,
    );
  }

  /// Returns the normalized name for comparison purposes (trimmed and lowercase).
  /// Used to determine if two products have effectively the same name regardless of casing or extra whitespace.
  String get normalizedName {
    final raw = name ?? '';
    return raw.trim().toLowerCase();
  }

  /// Checks if this decision represents a product with the same name as another [ReviewDecision].
  bool isSameProductAs(ReviewDecision? other) {
    if (other == null || normalizedName.isEmpty) return false;
    return normalizedName == other.normalizedName;
  }

  ReviewDecision copyWith({
    int? priceLogId,
    ReviewItem? reviewItem,
    ProductView? loadedProduct,
    String? name,
    String? brand,
    String? unit,
    InternalAssignmentAction? action,
    int? targetProductId,
  }) {
    return ReviewDecision(
      priceLogId: priceLogId ?? this.priceLogId,
      reviewItem: reviewItem ?? this.reviewItem,
      loadedProduct: loadedProduct ?? this.loadedProduct,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      action: action ?? this.action,
      targetProductId: targetProductId ?? this.targetProductId,
    );
  }

  /// Documentation for Merge Direction:
  /// When merging two products, the selected target product [targetProductId] is retained
  /// and its identity/data persists in the system. The source product (the one being reviewed)
  /// is absorbed into this target. This direction is deterministic across all UI components.
}
