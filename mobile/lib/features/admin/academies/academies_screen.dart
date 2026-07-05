import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/ui_helpers.dart';
import '../../../core/helpers/permissions.dart';
import '../../../core/helpers/api_error_parser.dart';
import '../../../core/models/department_model.dart';
import '../../../core/models/sport_model.dart';
import '../../../core/models/group_model.dart';

enum AcademyStage { academies, sports, groups }

class AcademiesScreen extends ConsumerStatefulWidget {
  const AcademiesScreen({super.key});

  @override
  ConsumerState<AcademiesScreen> createState() => _AcademiesScreenState();
}

class _AcademiesScreenState extends ConsumerState<AcademiesScreen> {
  AcademyStage _stage = AcademyStage.academies;
  DepartmentModel? _selectedAcademy;
  SportModel? _selectedSport;

  List<SportModel> _sports = [];
  List<GroupModel> _groups = [];
  bool _loadingDetails = false;
  String? _detailsError;

  final List<Map<String, String>> _weekDays = [
    {'value': 'saturday', 'label': 'السبت'},
    {'value': 'sunday', 'label': 'الأحد'},
    {'value': 'monday', 'label': 'الإثنين'},
    {'value': 'tuesday', 'label': 'الثلاثاء'},
    {'value': 'wednesday', 'label': 'الأربعاء'},
    {'value': 'thursday', 'label': 'الخميس'},
    {'value': 'friday', 'label': 'الجمعة'},
  ];

  Future<void> _fetchSports(int academyId) async {
    setState(() {
      _loadingDetails = true;
      _detailsError = null;
    });
    try {
      final list = await ref.read(departmentRepositoryProvider).fetchSportsByDepartment(academyId);
      setState(() {
        _sports = list;
        _loadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _detailsError = e.toString();
        _loadingDetails = false;
      });
    }
  }

  Future<void> _fetchGroups(int sportId) async {
    setState(() {
      _loadingDetails = true;
      _detailsError = null;
    });
    try {
      final list = await ref.read(departmentRepositoryProvider).fetchGroupsBySport(sportId);
      setState(() {
        _groups = list;
        _loadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _detailsError = e.toString();
        _loadingDetails = false;
      });
    }
  }

  // --- NAVIGATION HELPERS ---
  Future<void> _navigateToAddEditAcademy([DepartmentModel? academy]) async {
    final result = await context.push<bool>(
      academy == null
          ? '/dashboard/academies/add'
          : '/dashboard/academies/${academy.id}/edit',
    );
    if (result == true) ref.invalidate(departmentsProvider);
  }

  Future<void> _navigateToAddEditSport([SportModel? sport]) async {
    final academyId = _selectedAcademy!.id;
    final result = await context.push<bool>(
      sport == null
          ? '/dashboard/academies/$academyId/sports/add'
          : '/dashboard/academies/$academyId/sports/${sport.id}/edit',
    );
    if (result == true) _fetchSports(academyId);
  }

  Future<void> _navigateToAddEditGroup([GroupModel? group]) async {
    final academyId = _selectedAcademy!.id;
    final sportId = _selectedSport!.id;
    final result = await context.push<bool>(
      group == null
          ? '/dashboard/academies/$academyId/sports/$sportId/groups/add'
          : '/dashboard/academies/$academyId/sports/$sportId/groups/${group.id}/edit',
    );
    if (result == true) _fetchGroups(sportId);
  }

  // --- DELETE CONFIRMATION ---
  Future<void> _showDeleteConfirmDialog({
    required String title,
    required String name,
    required VoidCallback onDelete,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: Text('هل أنت متأكد من حذف "$name"؟ لا يمكن التراجع عن هذا الإجراء.', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onDelete();
    }
  }

  void _onAcademyTapped(DepartmentModel academy) async {
    setState(() {
      _selectedAcademy = academy;
      _selectedSport = null;
      _stage = AcademyStage.sports;
    });
    await _fetchSports(academy.id);
  }

  void _onSportTapped(SportModel sport) async {
    setState(() {
      _selectedSport = sport;
      _stage = AcademyStage.groups;
    });
    await _fetchGroups(sport.id);
  }

  // --- BREADCRUMBS ---
  Widget _buildBreadcrumbs() {
    if (_stage == AcademyStage.academies) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _stage = AcademyStage.academies;
                _selectedAcademy = null;
                _selectedSport = null;
              });
            },
            child: const Text(
              'الأكاديميات',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          if (_selectedAcademy != null) ...[
            const Icon(Icons.chevron_left, size: 16, color: Colors.grey),
            InkWell(
              onTap: () {
                if (_stage == AcademyStage.groups) {
                  setState(() {
                    _stage = AcademyStage.sports;
                    _selectedSport = null;
                  });
                  _fetchSports(_selectedAcademy!.id);
                }
              },
              child: Text(
                _selectedAcademy!.nameAr,
                style: TextStyle(
                  color: _stage == AcademyStage.sports ? Colors.grey : AppColors.primary,
                  fontWeight: _stage == AcademyStage.sports ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          if (_selectedSport != null && _stage == AcademyStage.groups) ...[
            const Icon(Icons.chevron_left, size: 16, color: Colors.grey),
            Text(
              _selectedSport!.nameAr,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final user = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: Permissions.can(user?.role, AppAction.departmentsCreate)
          ? FloatingActionButton(
              onPressed: () {
                if (_stage == AcademyStage.academies) {
                  _navigateToAddEditAcademy();
                } else if (_stage == AcademyStage.sports) {
                  _navigateToAddEditSport();
                } else {
                  _navigateToAddEditGroup();
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _stage == AcademyStage.academies
                      ? 'إدارة الأكاديميات'
                      : _stage == AcademyStage.sports
                          ? 'رياضات ${_selectedAcademy!.nameAr}'
                          : 'مجموعات ${_selectedSport!.nameAr}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildBreadcrumbs(),
          Expanded(
            child: _stage == AcademyStage.academies
                ? RefreshIndicator(
                    onRefresh: () async => ref.refresh(departmentsProvider),
                    child: departmentsAsync.when(
                      data: (list) {
                        if (list.isEmpty) {
                          return const EmptyState(message: 'لا توجد أكاديميات مسجلة');
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length + 1, // spacing
                          itemBuilder: (context, index) {
                            if (index == list.length) return const SizedBox(height: 100);
                            final dept = list[index];
                            final color = safeColor(dept.color);

                            return AppCard(
                              onTap: () => _onAcademyTapped(dept),
                              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color,
                                    radius: 24,
                                    backgroundImage: dept.logo != null ? NetworkImage(dept.logo!) : null,
                                    child: dept.logo == null
                                        ? Text(safeInitials(dept.nameAr), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dept.nameAr,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'رقم الحساب: ${dept.bankAccountNumber.isEmpty ? "غير محدد" : dept.bankAccountNumber.toWesternDigits()}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (Permissions.can(user?.role, AppAction.departmentsUpdate)) ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                                      onPressed: () => _navigateToAddEditAcademy(dept),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _showDeleteConfirmDialog(
                                        title: 'تأكيد حذف الأكاديمية',
                                        name: dept.nameAr,
                                        onDelete: () async {
                                          try {
                                            await ref.read(departmentRepositoryProvider).deleteDepartment(dept.id);
                                            ref.invalidate(departmentsProvider);
                                          } catch (e) {
                                            if (context.mounted) {
                                              final parsed = parseApiError(e);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(parsed.message)),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                  const Icon(Icons.chevron_left, color: Colors.grey),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const ShimmerList(),
                      error: (err, stack) => AppErrorWidget(
                        errorMessage: err.toString(),
                        onRetry: () => ref.refresh(departmentsProvider),
                      ),
                    ),
                  )
                : _loadingDetails
                    ? const ShimmerList()
                    : _detailsError != null
                        ? AppErrorWidget(
                            errorMessage: _detailsError!,
                            onRetry: () {
                              if (_stage == AcademyStage.sports) {
                                _fetchSports(_selectedAcademy!.id);
                              } else {
                                _fetchGroups(_selectedSport!.id);
                              }
                            },
                          )
                        : _stage == AcademyStage.sports
                            ? RefreshIndicator(
                                onRefresh: () => _fetchSports(_selectedAcademy!.id),
                                child: _sports.isEmpty
                                    ? ListView(
                                        children: const [
                                          SizedBox(height: 100),
                                          EmptyState(message: 'لا توجد رياضات في هذه الأكاديمية'),
                                        ],
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _sports.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index == _sports.length) return const SizedBox(height: 100);
                                          final sport = _sports[index];
                                          return AppCard(
                                            onTap: () => _onSportTapped(sport),
                                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.2),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                                  radius: 20,
                                                  child: Text(
                                                    safeInitials(sport.nameAr),
                                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        sport.nameAr,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                      ),
                                                      Text(
                                                        sport.name,
                                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (Permissions.can(user?.role, AppAction.departmentsUpdate)) ...[
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                                                    onPressed: () => _navigateToAddEditSport(sport),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                    onPressed: () => _showDeleteConfirmDialog(
                                                      title: 'تأكيد حذف الرياضة',
                                                      name: sport.nameAr,
                                                      onDelete: () async {
                                                        try {
                                                          await ref.read(departmentRepositoryProvider).deleteSport(sport.id);
                                                          _fetchSports(_selectedAcademy!.id);
                                                        } catch (e) {
                                                          if (context.mounted) {
                                                            final parsed = parseApiError(e);
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text(parsed.message)),
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                                const Icon(Icons.chevron_left, color: Colors.grey),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => _fetchGroups(_selectedSport!.id),
                                child: _groups.isEmpty
                                    ? ListView(
                                        children: const [
                                          SizedBox(height: 100),
                                          EmptyState(message: 'لا توجد مجموعات في هذه الرياضة'),
                                        ],
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _groups.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index == _groups.length) return const SizedBox(height: 100);
                                          final group = _groups[index];
                                          return AppCard(
                                            onTap: Permissions.can(user?.role, AppAction.departmentsUpdate) ? () => _navigateToAddEditGroup(group) : null,
                                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.2),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(group.nameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                    if (Permissions.can(user?.role, AppAction.departmentsUpdate))
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                                                            onPressed: () => _navigateToAddEditGroup(group),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                            onPressed: () => _showDeleteConfirmDialog(
                                                              title: 'تأكيد حذف المجموعة',
                                                              name: group.nameAr,
                                                              onDelete: () async {
                                                                try {
                                                                  await ref.read(departmentRepositoryProvider).deleteGroup(group.id);
                                                                  _fetchGroups(_selectedSport!.id);
                                                                } catch (e) {
                                                                  if (context.mounted) {
                                                                    final parsed = parseApiError(e);
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      SnackBar(content: Text(parsed.message)),
                                                                    );
                                                                  }
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                const SizedBox(height: 4),
                                                Text('المدرب: ${group.coachName.isEmpty ? "بدون مدرب" : group.coachName}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                                const SizedBox(height: 4),
                                                Text('التوقيت: ${group.startTime} - ${group.endTime}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: group.days.map((d) {
                                                    final dayLabel = _weekDays.firstWhere((w) => w['value'] == d, orElse: () => {'label': d})['label'];
                                                    return Chip(
                                                      label: Text(dayLabel!, style: const TextStyle(fontSize: 10)),
                                                      visualDensity: VisualDensity.compact,
                                                      padding: EdgeInsets.zero,
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
          ),
        ],
      ),
    );
  }
}
