import '../helpers/safe_json.dart';

class RenewalModel {
  final int id;
  final int subscriptionId;
  final double amount;
  final int months;
  final String renewalDate;
  final int? createdBy;

  RenewalModel({
    required this.id,
    required this.subscriptionId,
    required this.amount,
    required this.months,
    required this.renewalDate,
    this.createdBy,
  });

  factory RenewalModel.fromJson(Map<String, dynamic> json) {
    return RenewalModel(
      id: asInt(json['id']) ?? 0,
      subscriptionId: asInt(json['subscription']) ?? 0,
      amount: asDouble(json['amount']) ?? 0.0,
      months: asInt(json['months']) ?? 1,
      renewalDate: asString(json['renewal_date']) ?? '',
      createdBy: asInt(json['created_by']),
    );
  }
}

class SubscriptionModel {
  final int id;
  final int athleteId;
  final String athleteName;
  final String membershipNumber;
  final String departmentName;
  final int? groupId;
  final String groupName;
  final String packageName;
  final String startDate;
  final String endDate;
  final double amount;
  final String paymentMethod;
  final String? invoicePdf;
  final String? invoicePdfUrl;
  final String status;
  final int? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;
  final String? createdAt;
  final String? updatedAt;
  final List<RenewalModel> renewals;

  SubscriptionModel({
    required this.id,
    required this.athleteId,
    required this.athleteName,
    required this.membershipNumber,
    required this.departmentName,
    this.groupId,
    required this.groupName,
    required this.packageName,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.paymentMethod,
    this.invoicePdf,
    this.invoicePdfUrl,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    required this.renewals,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: asInt(json['id']) ?? 0,
      athleteId: asInt(json['athlete']) ?? 0,
      athleteName: asString(json['athlete_name']) ?? '',
      membershipNumber: asString(json['membership_number']) ?? '',
      departmentName: asString(json['department_name']) ?? '',
      groupId: asInt(json['group']),
      groupName: asString(json['group_name']) ?? '',
      packageName: asString(json['package_name']) ?? '',
      startDate: asString(json['start_date']) ?? '',
      endDate: asString(json['end_date']) ?? '',
      amount: asDouble(json['amount']) ?? 0.0,
      paymentMethod: asString(json['payment_method']) ?? 'cash',
      invoicePdf: asString(json['invoice_pdf']),
      invoicePdfUrl: asString(json['invoice_pdf_url']),
      status: asString(json['status']) ?? 'pending',
      approvedBy: asInt(json['approved_by']),
      approvedAt: asString(json['approved_at']),
      rejectionReason: asString(json['rejection_reason']),
      createdAt: asString(json['created_at']),
      updatedAt: asString(json['updated_at']),
      renewals: asList(json['renewals'], (e) => RenewalModel.fromJson(asMap(e) ?? {})) ?? [],
    );
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isExpired => status == 'expired';
  bool get isRejected => status == 'rejected';
}
