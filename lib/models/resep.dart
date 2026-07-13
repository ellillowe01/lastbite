// lib/models/recipe.dart

class Recipe {
  final String id;
  final String name;
  final String emoji;
  final List<String> ingredients;
  final List<String> steps;
  final int cookTimeMinutes;
  final int calories;
  final int servings;
  final String difficulty; // Mudah, Sedang, Susah
  final List<String> tags;
  final String mealTime; // pagi, siang, malam, semua
  final List<String> moods; // mood yang cocok

  const Recipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.ingredients,
    required this.steps,
    required this.cookTimeMinutes,
    required this.calories,
    this.servings = 1,
    this.difficulty = 'Mudah',
    this.tags = const [],
    this.mealTime = 'semua',
    this.moods = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'emoji': emoji,
    'ingredients': ingredients, 'steps': steps,
    'cookTimeMinutes': cookTimeMinutes, 'calories': calories,
    'servings': servings, 'difficulty': difficulty,
    'tags': tags, 'mealTime': mealTime, 'moods': moods,
  };

  factory Recipe.fromMap(Map<String, dynamic> map) => Recipe(
    id: map['id'], name: map['name'], emoji: map['emoji'],
    ingredients: List<String>.from(map['ingredients']),
    steps: List<String>.from(map['steps']),
    cookTimeMinutes: map['cookTimeMinutes'], calories: map['calories'],
    servings: map['servings'] ?? 1,
    difficulty: map['difficulty'] ?? 'Mudah',
    tags: List<String>.from(map['tags'] ?? []),
    mealTime: map['mealTime'] ?? 'semua',
    moods: List<String>.from(map['moods'] ?? []),
  );

  // Cek apakah resep bisa dibuat dari bahan yang ada
  int matchCount(List<String> availableIngredients) {
    int count = 0;
    for (final ing in ingredients) {
      for (final avail in availableIngredients) {
        if (avail.toLowerCase().contains(ing.toLowerCase()) ||
            ing.toLowerCase().contains(avail.toLowerCase())) {
          count++;
          break;
        }
      }
    }
    return count;
  }
}