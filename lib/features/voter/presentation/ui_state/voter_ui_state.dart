class VoterUiState {
  final bool loading;
  final bool loadingMore;
  final List voters;
  final String? error;
  final bool hasMore;
  final int totalCount;

  VoterUiState({
    this.loading = false,
    this.loadingMore = false,
    this.voters = const [],
    this.error,
    this.hasMore = true,
    this.totalCount = 0,
  });

  VoterUiState copyWith({
    bool? loading,
    bool? loadingMore,
    List? voters,
    String? error,
    bool? hasMore,
    int? totalCount,
  }) {
    return VoterUiState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      voters: voters ?? this.voters,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}
