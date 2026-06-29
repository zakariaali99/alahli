import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paginated_response.dart';

enum PaginatedState { idle, loading, loadingMore, error }

class PaginatedListState<T> {
  final List<T> items;
  final PaginatedState state;
  final String? error;
  final bool hasNext;

  PaginatedListState({
    this.items = const [],
    this.state = PaginatedState.idle,
    this.error,
    this.hasNext = false,
  });

  PaginatedListState<T> copyWith({
    List<T>? items,
    PaginatedState? state,
    String? error,
    bool? hasNext,
  }) {
    return PaginatedListState<T>(
      items: items ?? this.items,
      state: state ?? this.state,
      error: error,
      hasNext: hasNext ?? this.hasNext,
    );
  }
}

class PaginatedListNotifier<T, P> extends StateNotifier<PaginatedListState<T>> {
  final Future<PaginatedResponse<T>> Function(P params, int page) fetchFn;
  final P params;

  int _currentPage = 1;

  PaginatedListNotifier({
    required this.fetchFn,
    required this.params,
  }) : super(PaginatedListState<T>()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(state: PaginatedState.loading, error: null);
    _currentPage = 1;
    try {
      final res = await fetchFn(params, 1);
      state = PaginatedListState<T>(
        items: res.results,
        state: PaginatedState.idle,
        hasNext: res.hasNext,
      );
    } catch (e) {
      state = state.copyWith(
        state: PaginatedState.error,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.state == PaginatedState.loadingMore || !state.hasNext) return;

    state = state.copyWith(state: PaginatedState.loadingMore);
    _currentPage++;

    try {
      final res = await fetchFn(params, _currentPage);
      state = PaginatedListState<T>(
        items: [...state.items, ...res.results],
        state: PaginatedState.idle,
        hasNext: res.hasNext,
      );
    } catch (e) {
      _currentPage--;
      state = state.copyWith(
        state: PaginatedState.idle,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  void updateParams(P newParams) {
    loadInitial();
  }
}
