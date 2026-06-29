import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/paginated_providers.dart';
import '../../../core/providers/paginated_list_notifier.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/helpers/numeral_converter.dart';
import '../../../core/models/athlete_model.dart';

class AthletesListScreen extends ConsumerStatefulWidget {
  const AthletesListScreen({super.key});

  @override
  ConsumerState<AthletesListScreen> createState() => _AthletesListScreenState();
}

class _AthletesListScreenState extends ConsumerState<AthletesListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  int? _selectedDepartmentId;
  bool? _selectedActiveStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(athletesPaginatedProvider(_currentFilter()).notifier);
      notifier.loadMore();
    }
  }

  AthleteFilter _currentFilter() {
    final user = ref.read(authProvider);
    return AthleteFilter(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      departmentId: user?.role == 'academy_manager' ? user?.academy : _selectedDepartmentId,
      isActive: _selectedActiveStatus,
    );
  }

  Future<void> _toggleAthleteStatus(AthleteModel athlete) async {
    final newStatus = !athlete.isActive;
    try {
      final repo = ref.read(athleteRepositoryProvider);
      final data = FormData.fromMap({'is_active': newStatus});
      await repo.updateAthlete(athlete.id, data);
      ref.read(athletesPaginatedProvider(_currentFilter()).notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newStatus ? 'تم تنشيط الحساب بنجاح' : 'تم إلغاء تنشيط الحساب بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteAthlete(AthleteModel athlete) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: AppStrings.confirmDelete,
        content: 'هل أنت متأكد من حذف اللاعب ${athlete.fullName} نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
        confirmLabel: 'حذف',
        confirmColor: AppColors.destructive,
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(athleteRepositoryProvider).deleteAthlete(athlete.id);
        ref.read(athletesPaginatedProvider(_currentFilter()).notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف اللاعب بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final filter = _currentFilter();
    final athletesState = ref.watch(athletesPaginatedProvider(filter));
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اللاعبين المشتركين', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_selectedDepartmentId != null || _selectedActiveStatus != null || _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedDepartmentId = null;
                  _selectedActiveStatus = null;
                });
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/athletes/add'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: AppStrings.search,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onSubmitted: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('نشط'),
                        selected: _selectedActiveStatus == true,
                        onSelected: (val) {
                          setState(() {
                            _selectedActiveStatus = val ? true : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('غير نشط'),
                        selected: _selectedActiveStatus == false,
                        onSelected: (val) {
                          setState(() {
                            _selectedActiveStatus = val ? false : null;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      if (user?.role != 'academy_manager') ...[
                        departmentsAsync.when(
                          data: (depts) {
                            return Wrap(
                              spacing: 8,
                              children: depts.map((dept) {
                                return ChoiceChip(
                                  label: Text(dept.nameAr),
                                  selected: _selectedDepartmentId == dept.id,
                                  onSelected: (val) {
                                    setState(() {
                                      _selectedDepartmentId = val ? dept.id : null;
                                    });
                                  },
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(athletesPaginatedProvider(filter).notifier).refresh(),
              child: _buildBody(athletesState, isDark, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PaginatedListState<AthleteModel> state, bool isDark, ThemeData theme) {
    if (state.state == PaginatedState.loading) {
      return const ShimmerList();
    }

    if (state.state == PaginatedState.error) {
      return AppErrorWidget(
        errorMessage: state.error ?? 'خطأ غير معروف',
        onRetry: () => ref.read(athletesPaginatedProvider(_currentFilter()).notifier).refresh(),
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          EmptyState(message: 'لا يوجد لاعبين يطابقون خيارات البحث'),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: state.items.length + (state.hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final athlete = state.items[index];
        return AppCard(
          onTap: () => context.push('/athletes/${athlete.id}'),
          child: Row(
            children: [
              Hero(
                tag: 'athlete_avatar_${athlete.id}',
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: athlete.photo != null ? NetworkImage(athlete.photo!) : null,
                  child: athlete.photo == null
                      ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.fullName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'رقم العضوية: ${athlete.membershipNumber.toWesternDigits()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (athlete.departmentName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              athlete.departmentName!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        StatusBadge(status: athlete.isActive ? 'active' : 'rejected'),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                color: isDark ? AppColors.darkCard : Colors.white,
                onSelected: (val) {
                  if (val == 'view') {
                    context.push('/athletes/${athlete.id}');
                  } else if (val == 'toggle') {
                    _toggleAthleteStatus(athlete);
                  } else if (val == 'delete') {
                    _deleteAthlete(athlete);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(AppStrings.showProfile),
                        SizedBox(width: 8),
                        Icon(Icons.person_outline, size: 18),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(athlete.isActive ? 'إلغاء التنشيط' : 'تنشيط الحساب'),
                        const SizedBox(width: 8),
                        Icon(athlete.isActive ? Icons.block : Icons.check_circle_outline, size: 18),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('حذف الحساب', style: TextStyle(color: AppColors.destructive)),
                        SizedBox(width: 8),
                        Icon(Icons.delete_forever, color: AppColors.destructive, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
