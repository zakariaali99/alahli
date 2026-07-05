import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/staggered_list_item.dart';
import '../../../core/models/trainer_model.dart';
import '../../../core/models/group_model.dart';
import '../../../core/helpers/permissions.dart';
import '../../../core/helpers/ui_helpers.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/helpers/api_error_parser.dart';

class CoachesScreen extends ConsumerStatefulWidget {
  const CoachesScreen({super.key});

  @override
  ConsumerState<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends ConsumerState<CoachesScreen> {
  TrainerModel? _selectedCoach;
  bool _showingDetails = false;
  List<GroupModel> _coachGroups = [];
  bool _loadingGroups = false;

  void _onCoachTap(TrainerModel coach) async {
    setState(() {
      _selectedCoach = coach;
      _showingDetails = true;
      _loadingGroups = true;
      _coachGroups = [];
    });
    try {
      final groups = await ref.read(trainerRepositoryProvider).fetchTrainerGroups(coach.id);
      if (mounted && _selectedCoach?.id == coach.id) {
        setState(() {
          _coachGroups = groups;
          _loadingGroups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingGroups = false;
        });
        final parsed = parseApiError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parsed.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trainersAsync = ref.watch(trainersProvider);
    final user = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: (Permissions.can(user?.role, AppAction.coachesCreate) && !_showingDetails)
          ? FloatingActionButton(
              onPressed: () async {
                final result = await context.push<bool>('/dashboard/coaches/add');
                if (result == true) ref.invalidate(trainersProvider);
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: PopScope(
        canPop: !_showingDetails,
        onPopInvokedWithResult: (didPop, result) {
          if (_showingDetails) {
            setState(() {
              _showingDetails = false;
              _selectedCoach = null;
            });
          }
        },
        child: _showingDetails ? _buildDetailsView(isDark) : _buildListView(trainersAsync, user?.role, isDark),
      ),
    );
  }

  Widget _buildListView(AsyncValue<List<TrainerModel>> trainersAsync, String? role, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المدربون',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (Permissions.can(role, AppAction.coachesCreate))
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await context.push<bool>('/dashboard/coaches/add');
                    if (result == true) ref.invalidate(trainersProvider);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('إضافة مدرب'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(trainersProvider),
            child: trainersAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(message: 'لا يوجد مدربون مسجلون حالياً');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length + 1,
                  itemBuilder: (context, index) {
                    if (index == list.length) {
                      return const SizedBox(height: 120); // bottom spacing
                    }
                    final coach = list[index];

                    return StaggeredListItem(
                      index: index,
                      child: AppCard(
                        onTap: () => _onCoachTap(coach),
                        border: Border.all(
                          color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              radius: 24,
                              backgroundImage: coach.profileImage != null && coach.profileImage!.isNotEmpty
                                  ? NetworkImage(coach.profileImage!)
                                  : null,
                              child: coach.profileImage == null || coach.profileImage!.isEmpty
                                  ? Text(
                                      safeInitials(coach.fullNameAr),
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    coach.fullNameAr,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    coach.phone.toWesternDigits(),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: coach.isActive
                                        ? AppColors.secondary.withValues(alpha: 0.15)
                                        : AppColors.destructive.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    coach.isActive ? 'نشط' : 'موقوف',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: coach.isActive ? AppColors.secondary : AppColors.destructive,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_left, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const ShimmerList(),
              error: (err, stack) => AppErrorWidget(
                errorMessage: err.toString(),
                onRetry: () => ref.refresh(trainersProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsView(bool isDark) {
    final coach = _selectedCoach!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation / Breadcrumb Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    _showingDetails = false;
                    _selectedCoach = null;
                  });
                },
              ),
              const Text(
                'المدربون',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const Icon(Icons.chevron_left, size: 16, color: Colors.grey),
              Text(
                coach.fullNameAr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Profile Card
          AppCard(
            border: Border.all(
              color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: coach.profileImage != null && coach.profileImage!.isNotEmpty
                          ? NetworkImage(coach.profileImage!)
                          : null,
                      child: coach.profileImage == null || coach.profileImage!.isEmpty
                          ? Text(
                              safeInitials(coach.fullNameAr),
                              style: const TextStyle(fontSize: 20, color: AppColors.primary, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coach.fullNameAr,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coach.phone.toWesternDigits(),
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: coach.isActive
                                  ? AppColors.secondary.withValues(alpha: 0.15)
                                  : AppColors.destructive.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              coach.isActive ? 'حساب نشط' : 'حساب موقوف',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: coach.isActive ? AppColors.secondary : AppColors.destructive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الصلاحية في النظام:', style: TextStyle(color: Colors.grey)),
                    Text(coach.role == 'trainer' ? 'مدرب رياضي' : coach.role, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: Permissions.can(ref.read(authProvider)?.role, AppAction.coachesUpdate)
                          ? () async {
                              final result = await context.push<bool>('/dashboard/coaches/${coach.id}/edit');
                              if (result == true) {
                                ref.invalidate(trainersProvider);
                                setState(() {
                                  _showingDetails = false;
                                  _selectedCoach = null;
                                });
                              }
                            }
                          : null,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('تعديل الحساب'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Assigned Groups Section
          const Text(
            'المجموعات الرياضية المسندة إليه',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _loadingGroups
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              : _coachGroups.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: const Center(
                        child: Text(
                          'لا توجد مجموعات مسندة لهذا المدرب حالياً.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _coachGroups.length,
                      itemBuilder: (ctx, idx) {
                        final g = _coachGroups[idx];
                        return AppCard(
                          border: Border.all(
                            color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.nameAr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'الرياضة: ${g.sportName}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                'الأيام: ${g.days.join("، ")}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                'التوقيت: ${g.startTime.toWesternDigits()} - ${g.endTime.toWesternDigits()}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          const SizedBox(height: 120), // bottom spacing
        ],
      ),
    );
  }
}
