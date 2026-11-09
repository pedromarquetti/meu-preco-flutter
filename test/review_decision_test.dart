import 'package:flutter_test/flutter_test.dart';
import 'package:meu_preco_frontend/core/models/admin.dart';
import 'package:meu_preco_frontend/features/admin/review_decision.dart';

void main() {
  group('ReviewDecision', () {
    test('createFromItem seeds editable fields from the review item', () {
      const item = ReviewItem(
        priceLogId: 7,
        description: 'Leite Integral',
        suggestedStem: 'leite integral',
        unit: 'L',
      );

      final decision = ReviewDecision.createFromItem(item);

      expect(decision.priceLogId, 7);
      expect(decision.reviewItem, item);
      expect(decision.name, 'leite integral');
      expect(decision.unit, 'L');
      expect(decision.action, InternalAssignmentAction.create);
    });

    test(
      'normalizedName trims and lowercases without mutating display text',
      () {
        const decision = ReviewDecision(
          action: InternalAssignmentAction.create,
          name: '  Café  ',
        );

        expect(decision.normalizedName, 'café');
        expect(decision.name, '  Café  ');
      },
    );

    test('isSameProductAs compares normalized names', () {
      const a = ReviewDecision(
        action: InternalAssignmentAction.create,
        name: 'Arroz',
      );
      const b = ReviewDecision(
        action: InternalAssignmentAction.create,
        name: '  arroz ',
      );
      const c = ReviewDecision(
        action: InternalAssignmentAction.create,
        name: 'Feijão',
      );

      expect(a.isSameProductAs(b), isTrue);
      expect(a.isSameProductAs(c), isFalse);
      expect(a.isSameProductAs(null), isFalse);
    });

    test('toApiAction maps only supported API actions', () {
      expect(
        InternalAssignmentAction.create.toApiAction(),
        AssignmentAction.create,
      );
      expect(
        InternalAssignmentAction.updateExisting.toApiAction(),
        AssignmentAction.existing,
      );
      expect(InternalAssignmentAction.merge.toApiAction(), isNull);
    });
  });
}
