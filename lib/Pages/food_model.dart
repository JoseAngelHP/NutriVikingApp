// food_model.dart
class FoodItem {
  final String id;
  final String name;
  final String quantity;
  final double calories;
  final double carbs;
  final double protein;
  final double fats;

  FoodItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fats,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fats': fats,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? '',
      calories: (map['calories'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      protein: (map['protein'] ?? 0).toDouble(),
      fats: (map['fats'] ?? 0).toDouble(),
    );
  }
}

class Meal {
  final String id;
  final String name;
  final List<FoodItem> items;
  final DateTime date;

  Meal({
    required this.id,
    required this.name,
    required this.items,
    required this.date,
  });

  double get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
  double get totalCarbs => items.fold(0, (sum, item) => sum + item.carbs);
  double get totalProtein => items.fold(0, (sum, item) => sum + item.protein);
  double get totalFats => items.fold(0, (sum, item) => sum + item.fats);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
      'date': date.toIso8601String(),
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      items: List<FoodItem>.from(
          (map['items'] ?? []).map((item) => FoodItem.fromMap(item))),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}