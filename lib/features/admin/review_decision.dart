import '../../core/models/admin.dart';
import '../../core/models/product.dart';

/// What a review decision will point the price log at.
enum ReviewTargetKind { proposed, existing, create }

/// Internal model representing a decision for each review item in the batch
/// assignment flow.
///
/// The original proposal is kept separately from [targetProduct], so the UI can
/// still show what was proposed after the admin chooses a different target.
class ReviewDecision {
  const ReviewDecision({
    this.priceLogId,
    this.reviewItem,
    this.proposal,
    this.target = ReviewTargetKind.create,
    this.targetProduct,
    this.name,
    this.brand,
    this.unit,
  });

  /// The original log ID from [ReviewItem].
  final int? priceLogId;

  /// Reference to the source review item.
  final ReviewItem? reviewItem;

  /// The product proposed for this row, when one exists. It is kept even when
  /// [target] is not [ReviewTargetKind.proposed].
  final ReviewProductView? proposal;

  /// The explicit target of this decision.
  final ReviewTargetKind target;

  /// The product the row will be assigned to. Non-null for
  /// [ReviewTargetKind.proposed] and [ReviewTargetKind.existing].
  final ProductView? targetProduct;

  /// Draft display values for the create path.
  final String? name;
  final String? brand;
  final String? unit;

  /// Seeds a decision from a queue row.
  ///
  /// A pending proposal becomes the default target. Rejected proposals, rows
  /// without a proposal, and proposals without an id fall back to creating a
  /// new product seeded from the receipt suggestion, never from the rejected
  /// proposal's identity.
  factory ReviewDecision.createFromItem(ReviewItem item) {
    final proposal = item.proposedProduct;
    final suggestion = item.suggestedStem ?? item.description ?? '';
    final usableProposal =
        proposal != null &&
        proposal.id != null &&
        item.proposalStatus != ProposalStatus.rejected;

    if (usableProposal) {
      return ReviewDecision(
        priceLogId: item.priceLogId,
        reviewItem: item,
        proposal: proposal,
        target: ReviewTargetKind.proposed,
        targetProduct: proposal.toProductView(),
        name: proposal.name ?? suggestion,
        brand: proposal.brand,
        unit: proposal.unit ?? item.unit,
      );
    }

    return ReviewDecision(
      priceLogId: item.priceLogId,
      reviewItem: item,
      proposal: proposal,
      target: ReviewTargetKind.create,
      name: suggestion,
      unit: item.unit,
    );
  }

  bool get isCreate => target == ReviewTargetKind.create;

  bool get isExisting => target == ReviewTargetKind.existing;

  int? get targetProductId => targetProduct?.id;

  /// Whether the pending proposal can be approved as-is.
  bool get canApproveProposal =>
      target == ReviewTargetKind.proposed &&
      proposal?.id != null &&
      reviewItem?.isRejected != true;

  /// Targets the original proposal again, keeping the create draft untouched.
  ReviewDecision useProposal() {
    final proposal = this.proposal;
    if (proposal == null || proposal.id == null) return this;
    return ReviewDecision(
      priceLogId: priceLogId,
      reviewItem: reviewItem,
      proposal: proposal,
      target: ReviewTargetKind.proposed,
      targetProduct: proposal.toProductView(),
      name: name,
      brand: brand,
      unit: unit,
    );
  }

  /// Targets an existing catalog product without renaming it.
  ReviewDecision useExisting(ProductView product) => ReviewDecision(
    priceLogId: priceLogId,
    reviewItem: reviewItem,
    proposal: proposal,
    target: ReviewTargetKind.existing,
    targetProduct: product,
    name: name,
    brand: brand,
    unit: unit,
  );

  /// Switches to creating a new product, optionally replacing the draft fields.
  ReviewDecision createNew({String? name, String? brand, String? unit}) =>
      ReviewDecision(
        priceLogId: priceLogId,
        reviewItem: reviewItem,
        proposal: proposal,
        target: ReviewTargetKind.create,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        unit: unit ?? this.unit,
      );

  /// Returns the normalized name for comparison purposes (trimmed and
  /// lowercase).
  String get normalizedName {
    final raw = name ?? '';
    return raw.trim().toLowerCase();
  }

  /// Updates the draft values without changing the selected target.
  ReviewDecision copyWith({String? name, String? brand, String? unit}) =>
      ReviewDecision(
        priceLogId: priceLogId,
        reviewItem: reviewItem,
        proposal: proposal,
        target: target,
        targetProduct: targetProduct,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        unit: unit ?? this.unit,
      );
}
