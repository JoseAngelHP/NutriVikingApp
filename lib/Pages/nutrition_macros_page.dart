import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'food_model.dart';
import 'add_food_dialog.dart';

class NutritionMacrosPage extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String coachId;

  const NutritionMacrosPage({
    Key? key,
    required this.clientId,
    required this.clientName,
    required this.coachId,
  }) : super(key: key);

  @override
  _NutritionMacrosPageState createState() => _NutritionMacrosPageState();
}

class _NutritionMacrosPageState extends State<NutritionMacrosPage> {
  // ignore: unused_field
  Future<Map<String, dynamic>>? _nutritionData;
  DateTime _selectedDate = DateTime.now();
  final String _selectedPeriod = 'Día';
  List<String> _mealTypes = [];

  @override
  void initState() {
    super.initState();
    _nutritionData = _loadNutritionDataForDate(_selectedDate);
    _loadCustomMeals(); // Cargar comidas personalizadas primero
  }

  Future<void> _loadCustomMeals() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientId)
              .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('customMeals')) {
          setState(() {
            _mealTypes = List<String>.from(data['customMeals']);
          });
        } else {
          // Si el campo no existe, usa valores por defecto
          setState(() {
            _mealTypes = ['Desayuno', 'Almuerzo', 'Cena'];
          });
          // Opcional: crea el campo en Firestore
          await _initializeCustomMeals();
        }
      } else {
        // Si el documento no existe
        setState(() {
          _mealTypes = ['Desayuno', 'Almuerzo', 'Cena'];
        });
        // Opcional: crea el documento con valores por defecto
        await _initializeCustomMeals();
      }
    } catch (e) {
      print('Error cargando comidas personalizadas: $e');
      setState(() {
        _mealTypes = ['Desayuno', 'Almuerzo', 'Cena'];
      });
    }
  }

  Future<void> _initializeCustomMeals() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.clientId)
        .set({
          'customMeals': ['Desayuno', 'Almuerzo', 'Cena'],
        }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> _loadNutritionDataForDate(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .collection('nutrition')
          .doc(dateStr);

      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        final existingMeals = List<String>.from(
          (data['meals'] as List).map((m) => m['name']),
        );

        if (!listEquals(existingMeals, _mealTypes)) {
          final newData = await _getDefaultNutritionData(); // Ahora es async
          await docRef.set(newData, SetOptions(merge: true));
          return newData;
        }
        return data;
      } else {
        final defaultData = await _getDefaultNutritionData(); // Ahora es async
        await docRef.set(defaultData);
        return defaultData;
      }
    } catch (e) {
      print('Error loading nutrition data: $e');
      return await _getDefaultNutritionData(); // Ahora es async
    }
  }

  Future<Map<String, dynamic>> _getDefaultNutritionData() async {
    try {
      // 1. Obtener los datos del cliente desde Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientId)
              .get();

      if (!userDoc.exists) throw Exception('El cliente no existe');

      final userData = userDoc.data()!;

      // 2. Calcular los macros (usando la misma lógica que en ModernMacrosPage)
      final totalCalories =
          userData['dailyCalories']?.toDouble() ?? 2078; // Valor por defecto
      final macroPercentages =
          userData['macroPercentages'] ??
          {'carbs': 50, 'protein': 20, 'fats': 30};

      // 3. Calcular gramos totales
      final carbsG = (totalCalories * (macroPercentages['carbs'] / 100) / 4);
      final proteinG =
          (totalCalories * (macroPercentages['protein'] / 100) / 4);
      final fatsG = (totalCalories * (macroPercentages['fats'] / 100) / 9);

      // 4. Retornar la estructura con los valores dinámicos
      return {
        'clientName': widget.clientName,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'carbs': {'consumed': 0, 'total': carbsG.round()},
        'protein': {'consumed': 0, 'total': proteinG.round()},
        'fats': {'consumed': 0, 'total': fatsG.round()},
        'calories': {'consumed': 0, 'total': totalCalories.round()},
        'meals':
            _mealTypes
                .map(
                  (type) => {
                    'name': type,
                    'items': [],
                    'carbsConsumed': 0,
                    'carbsTotal': (carbsG / _mealTypes.length).round(),
                    'proteinConsumed': 0,
                    'proteinTotal': (proteinG / _mealTypes.length).round(),
                    'fatsConsumed': 0,
                    'fatsTotal': (fatsG / _mealTypes.length).round(),
                    'caloriesConsumed': 0,
                    'caloriesTotal':
                        (totalCalories / _mealTypes.length).round(),
                  },
                )
                .toList(),
      };
    } catch (e) {
      print('Error al cargar datos del cliente: $e');
      // Retornar valores por defecto en caso de error
      return {
        'clientName': widget.clientName,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'carbs': {'consumed': 0, 'total': 260},
        'protein': {'consumed': 0, 'total': 104},
        'fats': {'consumed': 0, 'total': 69},
        'calories': {'consumed': 0, 'total': 2078},
        'meals':
            _mealTypes
                .map(
                  (type) => {
                    'name': type,
                    'items': [],
                    'carbsConsumed': 0,
                    'carbsTotal': (260 / _mealTypes.length).round(),
                    'proteinConsumed': 0,
                    'proteinTotal': (104 / _mealTypes.length).round(),
                    'fatsConsumed': 0,
                    'fatsTotal': (69 / _mealTypes.length).round(),
                    'caloriesConsumed': 0,
                    'caloriesTotal': (2078 / _mealTypes.length).round(),
                  },
                )
                .toList(),
      };
    }
  }

  Future<void> _addFoodToMeal(String mealName, FoodItem food) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Obtener el documento actual
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .collection('nutrition')
          .doc(dateStr);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await docRef.get();
        final defaultData = await _getDefaultNutritionData(); // Ahora con await
        final data =
            doc.exists ? doc.data()! : defaultData; // Usamos el resultado

        // Actualizar los datos
        final meals = List<Map<String, dynamic>>.from(data['meals'] ?? []);
        final mealIndex = meals.indexWhere((m) => m['name'] == mealName);

        if (mealIndex != -1) {
          final meal = Map<String, dynamic>.from(meals[mealIndex]);
          final items = List<Map<String, dynamic>>.from(meal['items'] ?? []);
          items.add(food.toMap());

          // Actualizar totales de la comida
          meal['items'] = items;
          meal['carbsConsumed'] = (meal['carbsConsumed'] ?? 0) + food.carbs;
          meal['proteinConsumed'] =
              (meal['proteinConsumed'] ?? 0) + food.protein;
          meal['fatsConsumed'] = (meal['fatsConsumed'] ?? 0) + food.fats;
          meal['caloriesConsumed'] =
              (meal['caloriesConsumed'] ?? 0) + food.calories;

          meals[mealIndex] = meal;
        }

        // Actualizar totales generales
        data['carbs']['consumed'] =
            (data['carbs']['consumed'] ?? 0) + food.carbs;
        data['protein']['consumed'] =
            (data['protein']['consumed'] ?? 0) + food.protein;
        data['fats']['consumed'] = (data['fats']['consumed'] ?? 0) + food.fats;
        data['calories']['consumed'] =
            (data['calories']['consumed'] ?? 0) + food.calories;
        data['meals'] = meals;

        // Guardar en Firestore
        await docRef.set(data);

        transaction.set(docRef, data);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Alimento agregado exitosamente')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al agregar alimento: $e')));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _nutritionData = _loadNutritionDataForDate(picked);
      });
    }
  }

  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFFb51837),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween),
    );
  }

  Stream<DocumentSnapshot> get nutritionStream {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.clientId)
        .collection('nutrition')
        .doc(dateStr)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(widget.clientId)
                .snapshots(),
        builder: (context, userSnapshot) {
          // Actualizar comidas personalizadas si cambian
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final data =
                userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final customMeals =
                data.containsKey('customMeals')
                    ? List<String>.from(data['customMeals'])
                    : ['Desayuno', 'Almuerzo', 'Cena'];
            if (!listEquals(customMeals, _mealTypes)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _mealTypes = customMeals);
              });
            }
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: nutritionStream,
            builder: (context, nutritionSnapshot) {
              if (nutritionSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              // Datos existen: mostrar contenido
              if (nutritionSnapshot.hasData && nutritionSnapshot.data!.exists) {
                return _buildNutritionContent(
                  nutritionSnapshot.data!.data()! as Map<String, dynamic>,
                );
              }

              // Datos no existen: cargar valores por defecto (actualizados)
              return FutureBuilder<Map<String, dynamic>>(
                future: _getDefaultNutritionData(),
                builder: (context, futureSnapshot) {
                  if (futureSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return _buildNutritionContent(futureSnapshot.data!);
                },
              );
            },
          );
        },
      ),
    );
  }

  // Método auxiliar para construir el contenido de nutrición
  Widget _buildNutritionContent(Map<String, dynamic> data) {
    final meals = data['meals'] as List<dynamic>? ?? [];

    return Column(
      children: [
        _buildTopBar(),
        _buildDateSelector(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildMacrosSummary(data),
                ..._buildMealSections(meals),
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Selector de fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () {
                  final duration =
                      _selectedPeriod == 'Día'
                          ? Duration(days: 1)
                          : _selectedPeriod == 'Semana'
                          ? Duration(days: 7)
                          : _selectedPeriod == 'Mes'
                          ? Duration(days: 30)
                          : Duration(days: 365);
                  setState(() {
                    _selectedDate = _selectedDate.subtract(duration);
                    _nutritionData = _loadNutritionDataForDate(_selectedDate);
                  });
                },
              ),
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  DateFormat('EEEE, d MMMM y').format(_selectedDate),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: () {
                  final duration =
                      _selectedPeriod == 'Día'
                          ? Duration(days: 1)
                          : _selectedPeriod == 'Semana'
                          ? Duration(days: 7)
                          : _selectedPeriod == 'Mes'
                          ? Duration(days: 30)
                          : Duration(days: 365);
                  setState(() {
                    _selectedDate = _selectedDate.add(duration);
                    _nutritionData = _loadNutritionDataForDate(_selectedDate);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosSummary(Map<String, dynamic> data) {
    final carbs = data['carbs'] ?? {'consumed': 0, 'total': 0};
    final protein = data['protein'] ?? {'consumed': 0, 'total': 0};
    final fats = data['fats'] ?? {'consumed': 0, 'total': 0};
    final calories = data['calories'] ?? {'consumed': 0, 'total': 0};

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Gráficos de barras para macros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroProgress('Carbohidratos', carbs, Colors.amber),
              SizedBox(width: 8),
              _buildMacroProgress('Proteínas', protein, Colors.blue),
              SizedBox(width: 8),
              _buildMacroProgress('Grasas', fats, Colors.purple),
            ],
          ),
          SizedBox(height: 16),
          // Barra de progreso de calorías
          Column(
            children: [
              LinearProgressIndicator(
                value:
                    calories['consumed'] /
                    (calories['total'] > 0 ? calories['total'] : 1),
                minHeight: 10,
                backgroundColor: Colors.blue[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 4),
              Text(
                '${calories['consumed'].toStringAsFixed(0)} / ${calories['total'].toStringAsFixed(0)} kcal',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgress(
    String name,
    Map<String, dynamic> macro,
    Color color,
  ) {
    final consumed = (macro['consumed'] ?? 0).toDouble();
    final total = (macro['total'] ?? 1).toDouble();
    final percentage = (consumed / total * 100).toStringAsFixed(0);

    return Expanded(
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: consumed / total,
                  strokeWidth: 8,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                children: [
                  Text(
                    consumed.toStringAsFixed(0),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '${total.toStringAsFixed(0)}g',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMealSections(List<dynamic> meals) {
    return meals.map((meal) {
      // Manejo seguro del mapa de comidas
      final safeMeal = meal is Map<String, dynamic> ? meal : {};
      final items = safeMeal['items'] is List ? safeMeal['items'] : [];

      // Preparamos los datos para el resumen con valores por defecto
      final mealSummaryData = {
        'carbsConsumed': safeMeal['carbsConsumed'] ?? 0,
        'carbsTotal': safeMeal['carbsTotal'] ?? 0,
        'proteinConsumed': safeMeal['proteinConsumed'] ?? 0,
        'proteinTotal': safeMeal['proteinTotal'] ?? 0,
        'fatsConsumed': safeMeal['fatsConsumed'] ?? 0,
        'fatsTotal': safeMeal['fatsTotal'] ?? 0,
        'caloriesConsumed': safeMeal['caloriesConsumed'] ?? 0,
        'caloriesTotal': safeMeal['caloriesTotal'] ?? 0,
      };

      return Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Encabezado de la comida
            ListTile(
              title: Text(
                safeMeal['name']?.toString() ?? 'Comida',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              /*trailing: IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () {},
              ),*/
            ),

            // Divisor con colores de macros
            Row(
              children: [
                Expanded(child: Divider(color: Colors.amber, thickness: 2)),
                Expanded(child: Divider(color: Colors.blue, thickness: 2)),
                Expanded(child: Divider(color: Colors.purple, thickness: 2)),
              ],
            ),

            // Lista de alimentos
            ..._buildFoodItems(items, safeMeal['name']?.toString() ?? 'Comida'),

            // Botón para agregar alimento
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: TextButton(
                onPressed:
                    () => _showAddFoodDialog(
                      safeMeal['name']?.toString() ?? 'Comida',
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.teal, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Añadir alimento',
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Resumen de la comida con datos seguros
            _buildMealSummary(mealSummaryData),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildFoodItems(List<dynamic> items, String mealName) {
    if (items.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No hay alimentos registrados',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ];
    }

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final safeItem = item is Map<String, dynamic> ? item : {};

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safeItem['name'] ?? 'Alimento',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        safeItem['quantity'] ?? 'Cantidad',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${safeItem['calories']?.toStringAsFixed(0) ?? '0'} kcal',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'C:',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          ' ${safeItem['carbs']?.toStringAsFixed(0) ?? '0'}g',
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'P:',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          ' ${safeItem['protein']?.toStringAsFixed(0) ?? '0'}g',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'G:',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          ' ${safeItem['fats']?.toStringAsFixed(0) ?? '0'}g',
                          style: TextStyle(color: Colors.purple, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    final foodMap =
                        item as Map<String, dynamic>; // Conversión aquí
                    if (value == 'delete') {
                      _confirmDeleteFood(mealName, index, foodMap);
                    } else if (value == 'edit') {
                      _editFoodItem(mealName, index, foodMap);
                    }
                  },
                  itemBuilder:
                      (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Modificar'),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                      ],
                ),
              ],
            ),
            Divider(height: 16, thickness: 1),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _confirmDeleteFood(
    String mealName,
    int index,
    Map<String, dynamic> foodItem,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Eliminar alimento'),
            content: Text('¿Estás seguro de eliminar ${foodItem['name']}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _deleteFoodItem(mealName, index, foodItem);
    }
  }

  Future<void> _deleteFoodItem(
    String mealName,
    int index,
    Map<String, dynamic> foodItem,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .collection('nutrition')
          .doc(dateStr);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;

        final data = doc.data()!;
        final meals = List<Map<String, dynamic>>.from(data['meals'] ?? []);
        final mealIndex = meals.indexWhere((m) => m['name'] == mealName);

        if (mealIndex != -1) {
          final meal = Map<String, dynamic>.from(meals[mealIndex]);
          final items = List<Map<String, dynamic>>.from(meal['items'] ?? []);

          if (index < items.length) {
            // Restar los valores nutricionales
            meal['carbsConsumed'] =
                (meal['carbsConsumed'] ?? 0) - (foodItem['carbs'] ?? 0);
            meal['proteinConsumed'] =
                (meal['proteinConsumed'] ?? 0) - (foodItem['protein'] ?? 0);
            meal['fatsConsumed'] =
                (meal['fatsConsumed'] ?? 0) - (foodItem['fats'] ?? 0);
            meal['caloriesConsumed'] =
                (meal['caloriesConsumed'] ?? 0) - (foodItem['calories'] ?? 0);

            // Eliminar el alimento
            items.removeAt(index);
            meal['items'] = items;
            meals[mealIndex] = meal;

            // Actualizar totales generales
            data['carbs']['consumed'] =
                (data['carbs']['consumed'] ?? 0) - (foodItem['carbs'] ?? 0);
            data['protein']['consumed'] =
                (data['protein']['consumed'] ?? 0) - (foodItem['protein'] ?? 0);
            data['fats']['consumed'] =
                (data['fats']['consumed'] ?? 0) - (foodItem['fats'] ?? 0);
            data['calories']['consumed'] =
                (data['calories']['consumed'] ?? 0) -
                (foodItem['calories'] ?? 0);
            data['meals'] = meals;

            transaction.update(docRef, data);
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alimento eliminado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar alimento: $e')),
        );
      }
    }
  }

  Future<void> _editFoodItem(
    String mealName,
    int index,
    Map<String, dynamic> foodItem,
  ) async {
    // Verificar que el widget esté montado antes de mostrar el diálogo
    if (!mounted) return;

    final editedFood = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AddFoodDialog(
            onAdd: (food) => Navigator.of(context).pop(food.toMap()),
            initialFood: FoodItem.fromMap(foodItem),
          ),
    );

    // Verificar nuevamente que el widget esté montado
    if (editedFood != null && mounted) {
      await _updateFoodItem(mealName, index, foodItem, editedFood);
    }
  }

  Future<void> _updateFoodItem(
    String mealName,
    int index,
    Map<String, dynamic> oldFood,
    Map<String, dynamic> newFood,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .collection('nutrition')
          .doc(dateStr);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;

        final data = doc.data()!;
        final meals = List<Map<String, dynamic>>.from(data['meals'] ?? []);
        final mealIndex = meals.indexWhere((m) => m['name'] == mealName);

        if (mealIndex != -1) {
          final meal = Map<String, dynamic>.from(meals[mealIndex]);
          final items = List<Map<String, dynamic>>.from(meal['items'] ?? []);

          if (index < items.length) {
            // Restar valores antiguos y sumar nuevos
            meal['carbsConsumed'] =
                (meal['carbsConsumed'] ?? 0) -
                (oldFood['carbs'] ?? 0) +
                (newFood['carbs'] ?? 0);
            meal['proteinConsumed'] =
                (meal['proteinConsumed'] ?? 0) -
                (oldFood['protein'] ?? 0) +
                (newFood['protein'] ?? 0);
            meal['fatsConsumed'] =
                (meal['fatsConsumed'] ?? 0) -
                (oldFood['fats'] ?? 0) +
                (newFood['fats'] ?? 0);
            meal['caloriesConsumed'] =
                (meal['caloriesConsumed'] ?? 0) -
                (oldFood['calories'] ?? 0) +
                (newFood['calories'] ?? 0);

            // Actualizar el alimento
            items[index] = newFood;
            meal['items'] = items;
            meals[mealIndex] = meal;

            // Actualizar totales generales
            data['carbs']['consumed'] =
                (data['carbs']['consumed'] ?? 0) -
                (oldFood['carbs'] ?? 0) +
                (newFood['carbs'] ?? 0);
            data['protein']['consumed'] =
                (data['protein']['consumed'] ?? 0) -
                (oldFood['protein'] ?? 0) +
                (newFood['protein'] ?? 0);
            data['fats']['consumed'] =
                (data['fats']['consumed'] ?? 0) -
                (oldFood['fats'] ?? 0) +
                (newFood['fats'] ?? 0);
            data['calories']['consumed'] =
                (data['calories']['consumed'] ?? 0) -
                (oldFood['calories'] ?? 0) +
                (newFood['calories'] ?? 0);
            data['meals'] = meals;

            transaction.update(docRef, data);
          }
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alimento actualizado exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar alimento: $e')),
      );
    }
  }

  // Asegurar que el método _buildMealSummary maneje valores nulos
  Widget _buildMealSummary(Map<String, dynamic> meal) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            '${(meal['carbsConsumed'] ?? 0).toStringAsFixed(0)} / ${(meal['carbsTotal'] ?? 0).toStringAsFixed(0)}',
            'Carbs',
            Colors.amber,
          ),
          _buildSummaryItem(
            '${(meal['proteinConsumed'] ?? 0).toStringAsFixed(0)} / ${(meal['proteinTotal'] ?? 0).toStringAsFixed(0)}',
            'Prot',
            Colors.blue,
          ),
          _buildSummaryItem(
            '${(meal['fatsConsumed'] ?? 0).toStringAsFixed(0)} / ${(meal['fatsTotal'] ?? 0).toStringAsFixed(0)}',
            'Grasas',
            Colors.purple,
          ),
          _buildSummaryItem(
            '${(meal['caloriesConsumed'] ?? 0).toStringAsFixed(0)} / ${(meal['caloriesTotal'] ?? 0).toStringAsFixed(0)}',
            'Kcal',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Future<void> _showAddFoodDialog(String mealName) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AddFoodDialog(onAdd: (food) => _addFoodToMeal(mealName, food));
      },
    );
  }
}
