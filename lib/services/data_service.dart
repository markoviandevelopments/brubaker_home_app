class DataService {
  final Map<String, double> _ratings = {}; // In-memory; replace with backend

  double getUserRating(String itemName) {
    return _ratings[itemName] ?? 0.0;
  }

  void setUserRating(String itemName, double rating) {
    _ratings[itemName] = rating;
    // TODO: Sync to backend, e.g., via API POST
  }
}
