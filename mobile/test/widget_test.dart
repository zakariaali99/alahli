import 'package:flutter_test/flutter_test.dart';

import 'package:al_ahly_sports_center/core/models/membership_model.dart';

void main() {
  group('MembershipModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'athlete_name': 'أحمد علي',
        'membership_number': 'MEM-001',
        'department_name': 'اللياقة البدنية',
        'package_name': 'الباقة الذهبية',
        'amount': 500.0,
        'start_date': '2026-01-01',
        'end_date': '2026-12-31',
        'status': 'active',
      };

      final model = MembershipModel.fromJson(json);

      expect(model.id, 1);
      expect(model.athleteName, 'أحمد علي');
      expect(model.membershipNumber, 'MEM-001');
      expect(model.departmentName, 'اللياقة البدنية');
      expect(model.packageName, 'الباقة الذهبية');
      expect(model.amount, 500.0);
      expect(model.startDate, '2026-01-01');
      expect(model.endDate, '2026-12-31');
      expect(model.isActive, true);
      expect(model.status, 'active');
    });

    test('fromJson handles null amount', () {
      final json = {
        'id': 2,
        'athlete_name': '',
        'membership_number': '',
        'department_name': '',
        'package_name': '',
        'amount': null,
        'start_date': null,
        'end_date': null,
        'status': 'expired',
      };

      final model = MembershipModel.fromJson(json);

      expect(model.id, 2);
      expect(model.amount, 0.0);
      expect(model.isActive, false);
    });

    test('toJson produces correct map', () {
      final model = MembershipModel(
        id: 3,
        athleteName: 'محمد',
        membershipNumber: 'MEM-003',
        departmentName: 'السباحة',
        packageName: 'الباقة الفضية',
        amount: 300.0,
        startDate: '2026-06-01',
        endDate: '2026-09-01',
        isActive: true,
        status: 'active',
      );

      final json = model.toJson();

      expect(json['id'], 3);
      expect(json['athlete_name'], 'محمد');
      expect(json['amount'], 300.0);
    });
  });
}
