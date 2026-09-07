class GovernmentScheme {
  final String id;
  final String name;
  final String category;
  final String benefit;
  final String eligibility;
  final List<String> documents;
  final String applyUrl;

  const GovernmentScheme({
    required this.id,
    required this.name,
    required this.category,
    required this.benefit,
    required this.eligibility,
    required this.documents,
    required this.applyUrl,
  });
}
