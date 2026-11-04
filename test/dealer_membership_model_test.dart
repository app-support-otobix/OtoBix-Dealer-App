import 'package:flutter_test/flutter_test.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';

// The free Promo trial runs only on dates OtoBix sets from the CRM; until it
// starts the dealer is queued with 0 points.
void main() {
  DealerMembershipModel membership(Map<String, dynamic> extra) =>
      DealerMembershipModel.fromJson({
        'dealerCode': 'DLR-10001',
        'status': 'NONE',
        'availablePoints': 0,
        ...extra,
      });

  test('no dates yet: queued, nothing scheduled', () {
    final m = membership({
      'promoTrial': {'status': 'NOT_SET', 'startDate': '', 'endDate': ''},
    });
    expect(m.trialQueued, isTrue);
    expect(m.trialScheduled, isFalse);
    expect(m.isActive, isFalse);
    expect(m.availablePoints, 0);
  });

  test('dates set, not begun: queued with the dates', () {
    final m = membership({
      'promoTrial': {
        'status': 'SCHEDULED',
        'startDate': '2026-11-01',
        'endDate': '2026-11-30',
      },
    });
    expect(m.trialQueued, isTrue);
    expect(m.trialScheduled, isTrue);
    expect(m.trialStartDate, DateTime(2026, 11, 1));
    expect(m.trialEndDate, DateTime(2026, 11, 30));
  });

  test('running: active, not queued', () {
    final m = membership({
      'status': 'ACTIVE',
      'availablePoints': 5000,
      'promoTrial': {'status': 'RUNNING'},
    });
    expect(m.isActive, isTrue);
    expect(m.trialQueued, isFalse);
  });

  test('missed or ended, and brokers: not queued', () {
    for (final status in ['MISSED', 'ENDED']) {
      expect(
        membership({
          'promoTrial': {'status': status},
        }).trialQueued,
        isFalse,
      );
    }
    expect(membership({'promoTrial': null}).trialQueued, isFalse);
  });
}
