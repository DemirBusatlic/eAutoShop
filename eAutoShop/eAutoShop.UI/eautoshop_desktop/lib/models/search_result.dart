class SearchResult<T> {
  const SearchResult({required this.count, required this.result});

  final int count;
  final List<T> result;
}
