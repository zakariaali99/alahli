import 'package:flutter_test/flutter_test.dart';
import 'package:al_ahly_sports_center/core/models/user_model.dart';
import 'package:al_ahly_sports_center/core/models/paginated_response.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 1,
        'phone': '0910000000',
        'first_name_ar': 'أحمد',
        'last_name_ar': 'علي',
        'full_name_ar': 'أحمد علي',
        'role': 'super_admin',
        'is_active': true,
        'photo': 'https://example.com/photo.jpg',
        'academy': 5,
        'academy_name': 'الأكاديمية الرئيسية',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.phone, '0910000000');
      expect(user.firstNameAr, 'أحمد');
      expect(user.lastNameAr, 'علي');
      expect(user.fullNameAr, 'أحمد علي');
      expect(user.role, 'super_admin');
      expect(user.isActive, true);
      expect(user.photo, 'https://example.com/photo.jpg');
      expect(user.academy, 5);
      expect(user.academyName, 'الأكاديمية الرئيسية');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 2,
        'phone': '0920000000',
        'first_name_ar': 'محمد',
        'last_name_ar': '',
        'full_name_ar': 'محمد',
        'role': 'reception',
        'is_active': false,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 2);
      expect(user.photo, isNull);
      expect(user.academy, isNull);
      expect(user.academyName, isNull);
      expect(user.isActive, false);
    });

    test('role getters work correctly', () {
      final admin = UserModel.fromJson({
        'id': 1,
        'phone': '091',
        'first_name_ar': 'A',
        'last_name_ar': 'B',
        'full_name_ar': 'AB',
        'role': 'super_admin',
        'is_active': true,
      });
      expect(admin.isSuperAdmin, true);
      expect(admin.isReception, false);
      expect(admin.isAcademyManager, false);

      final reception = UserModel.fromJson({
        'id': 2,
        'phone': '092',
        'first_name_ar': 'C',
        'last_name_ar': 'D',
        'full_name_ar': 'CD',
        'role': 'reception',
        'is_active': true,
      });
      expect(reception.isSuperAdmin, false);
      expect(reception.isReception, true);
    });
  });

  group('PaginatedResponse', () {
    test('hasNext is true when next URL exists', () {
      final res = PaginatedResponse<int>(
        results: [1, 2, 3],
        count: 10,
        next: 'http://example.com/api/?page=2',
        previous: null,
      );
      expect(res.hasNext, true);
      expect(res.results.length, 3);
      expect(res.count, 10);
    });

    test('hasNext is false when next URL is null', () {
      final res = PaginatedResponse<int>(
        results: [1, 2, 3],
        count: 3,
        next: null,
        previous: 'http://example.com/api/?page=1',
      );
      expect(res.hasNext, false);
    });
  });
}
