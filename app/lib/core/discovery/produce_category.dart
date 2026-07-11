/// Coarse produce categories for the market's browse tabs. Matched by keyword
/// against the vegetable name (the backend stores free-text names).
enum ProduceCategory {
  all('All', null),
  leafy('Leafy Greens', 'leaf'),
  roots('Roots & Tubers', 'root'),
  fruiting('Fruiting', 'fruit'),
  gourds('Gourds', 'gourd'),
  herbs('Herbs', 'herb');

  const ProduceCategory(this.label, this._tag);
  final String label;
  final String? _tag;
}

const Map<String, List<String>> _keywords = {
  'leaf': [
    'spinach', 'cabbage', 'lettuce', 'cauliflower', 'greens', 'amaranth',
    'kale', 'fenugreek', 'methi', 'broccoli',
  ],
  'root': [
    'potato', 'onion', 'carrot', 'radish', 'beet', 'ginger', 'garlic',
    'turnip', 'yam', 'tapioca',
  ],
  'gourd': [
    'gourd', 'pumpkin', 'cucumber', 'squash', 'drumstick',
  ],
  'herb': ['coriander', 'mint', 'curry', 'basil', 'parsley', 'dill'],
  'fruit': [
    'tomato', 'pepper', 'capsicum', 'brinjal', 'eggplant', 'okra',
    'bean', 'chilli', 'chili', 'peas', 'corn',
  ],
};

/// Best-effort category for a vegetable name. Falls back to [ProduceCategory.fruiting]
/// (the largest bucket) when nothing matches, so items never vanish from tabs.
ProduceCategory categorize(String vegetable) {
  final v = vegetable.toLowerCase();
  for (final entry in _keywords.entries) {
    if (entry.value.any(v.contains)) {
      return ProduceCategory.values.firstWhere((c) => c._tag == entry.key);
    }
  }
  return ProduceCategory.fruiting;
}

/// Whether an offer with [vegetable] belongs under [category].
bool matchesCategory(ProduceCategory category, String vegetable) =>
    category == ProduceCategory.all || categorize(vegetable) == category;
