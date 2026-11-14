import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/models/admin.dart';
import 'package:meu_preco_frontend/core/models/product.dart';
import 'package:meu_preco_frontend/features/admin/review_decision.dart';

const _pendingItem = ReviewItem(
  priceLogId: 10,
  description: 'APRESUNTADO SOFT PIG KG',
  suggestedStem: 'apresuntado',
  unit: 'kg',
  proposedProduct: ReviewProductView(
    id: 8,
    name: 'Apresuntado',
    brand: 'Pig',
    unit: 'kg',
  ),
);

const _rejectedItem = ReviewItem(
  priceLogId: 10,
  description: 'APRESUNTADO SOFT PIG KG',
  suggestedStem: 'apresuntado',
  unit: 'kg',
  proposedProduct: ReviewProductView(
    id: 8,
    name: 'tijolo',
    brand: 'de barro',
    unit: 'un',
  ),
  proposalStatus: ProposalStatus.rejected,
);

void main() {
  group('ReviewDecision.createFromItem', () {
    test('rows without a proposal default to create from the suggestion', () {
      const item = ReviewItem(
        priceLogId: 7,
        description: 'Leite Integral',
        suggestedStem: 'leite integral',
        unit: 'L',
      );

      final decision = ReviewDecision.createFromItem(item);

      expect(decision.priceLogId, 7);
      expect(decision.reviewItem, item);
      expect(decision.target, ReviewTargetKind.create);
      expect(decision.isCreate, isTrue);
      expect(decision.proposal, isNull);
      expect(decision.targetProduct, isNull);
      expect(decision.targetProductId, isNull);
      expect(decision.name, 'leite integral');
      expect(decision.brand, isNull);
      expect(decision.unit, 'L');
    });

    test('pending proposals default to the proposed product', () {
      final decision = ReviewDecision.createFromItem(_pendingItem);

      expect(decision.target, ReviewTargetKind.proposed);
      expect(decision.isCreate, isFalse);
      expect(decision.proposal, _pendingItem.proposedProduct);
      expect(decision.targetProduct?.id, 8);
      expect(decision.targetProduct?.name, 'Apresuntado');
      expect(decision.targetProductId, 8);
    });

    test('rejected proposals default to create from the suggestion', () {
      final decision = ReviewDecision.createFromItem(_rejectedItem);

      expect(decision.target, ReviewTargetKind.create);
      expect(decision.isCreate, isTrue);
      expect(decision.proposal, _rejectedItem.proposedProduct);
      expect(decision.targetProduct, isNull);
      expect(decision.targetProductId, isNull);
      expect(decision.name, 'apresuntado');
      expect(decision.brand, isNull);
      expect(decision.unit, 'kg');
    });

    test('a rejected proposal never seeds the create draft', () {
      final decision = ReviewDecision.createFromItem(_rejectedItem);

      expect(decision.name, isNot('tijolo'));
      expect(decision.brand, isNot('de barro'));
      expect(decision.unit, isNot('un'));
    });

    test('proposals without an id fall back to create', () {
      const item = ReviewItem(
        priceLogId: 11,
        description: 'SAC 58X70 BIO VERDE',
        suggestedStem: 'saco 58x70',
        unit: 'un',
        proposedProduct: ReviewProductView(name: 'Saco'),
      );

      final decision = ReviewDecision.createFromItem(item);

      expect(decision.target, ReviewTargetKind.create);
      expect(decision.proposal, item.proposedProduct);
      expect(decision.targetProduct, isNull);
      expect(decision.name, 'saco 58x70');
      expect(decision.unit, 'un');
    });

    test('falls back to the description when there is no suggested stem', () {
      const item = ReviewItem(
        priceLogId: 12,
        description: 'Produto sem sugestão',
        unit: 'un',
      );

      final decision = ReviewDecision.createFromItem(item);

      expect(decision.target, ReviewTargetKind.create);
      expect(decision.name, 'Produto sem sugestão');
    });
  });

  group('target transitions', () {
    const product = ProductView(id: 2, name: 'Saco', brand: 'Bio', unit: 'un');

    test('proposed -> existing replaces the target and keeps the proposal', () {
      final decision = ReviewDecision.createFromItem(_pendingItem)
          .useExisting(product);

      expect(decision.target, ReviewTargetKind.existing);
      expect(decision.isCreate, isFalse);
      expect(decision.proposal, _pendingItem.proposedProduct);
      expect(decision.targetProduct, product);
      expect(decision.targetProductId, 2);
    });

    test('existing -> create clears the target product', () {
      final decision = ReviewDecision.createFromItem(_pendingItem)
          .useExisting(product)
          .createNew(name: 'Novo', brand: 'Marca', unit: 'kg');

      expect(decision.target, ReviewTargetKind.create);
      expect(decision.isCreate, isTrue);
      expect(decision.targetProduct, isNull);
      expect(decision.targetProductId, isNull);
      expect(decision.name, 'Novo');
      expect(decision.brand, 'Marca');
      expect(decision.unit, 'kg');
      expect(decision.proposal, _pendingItem.proposedProduct);
    });

    test('create -> proposed restores the proposal target', () {
      final decision = ReviewDecision.createFromItem(_pendingItem)
          .createNew(name: 'Novo', brand: 'Marca', unit: 'kg')
          .useProposal();

      expect(decision.target, ReviewTargetKind.proposed);
      expect(decision.targetProduct?.id, 8);
      expect(decision.proposal, _pendingItem.proposedProduct);
      // The create draft is unrelated state and is preserved.
      expect(decision.name, 'Novo');
      expect(decision.brand, 'Marca');
      expect(decision.unit, 'kg');
    });

    test('useProposal is a no-op without a proposal id', () {
      const item = ReviewItem(
        priceLogId: 11,
        description: 'SAC 58X70 BIO VERDE',
        suggestedStem: 'saco 58x70',
        unit: 'un',
        proposedProduct: ReviewProductView(name: 'Saco'),
      );
      final decision = ReviewDecision.createFromItem(item);
      final restored = decision.useProposal();

      expect(restored.target, ReviewTargetKind.create);
      expect(restored.targetProduct, isNull);
      expect(restored.name, decision.name);
    });

    test('a rejected proposal can only be targeted explicitly', () {
      final decision = ReviewDecision.createFromItem(_rejectedItem);
      expect(decision.target, ReviewTargetKind.create);

      final explicit = decision.useProposal();

      expect(explicit.target, ReviewTargetKind.proposed);
      expect(explicit.targetProductId, 8);
    });

    test('createNew without arguments keeps the current draft', () {
      final decision = ReviewDecision.createFromItem(_pendingItem).createNew();

      expect(decision.target, ReviewTargetKind.create);
      expect(decision.targetProduct, isNull);
      expect(decision.name, 'Apresuntado');
      expect(decision.brand, 'Pig');
      expect(decision.unit, 'kg');
    });

    test('copyWith updates the draft without changing the target', () {
      final decision = ReviewDecision.createFromItem(_pendingItem)
          .copyWith(name: '  Arroz  ', brand: 'Marca', unit: 'un');

      expect(decision.target, ReviewTargetKind.proposed);
      expect(decision.targetProduct?.id, 8);
      expect(decision.name, '  Arroz  ');
      expect(decision.brand, 'Marca');
      expect(decision.unit, 'un');
    });
  });
}
