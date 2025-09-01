import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nutri_viking_app/Pages/Exercise.dart';
import 'package:nutri_viking_app/Pages/add_exercise_dialog.dart';
import 'food_model.dart';
import 'add_food_dialog.dart';
import 'dart:math';

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
  // 1. Primero, añade estas variables al estado de tu clase
  List<String> _savedMenus = []; // Lista de nombres de menús guardados
  String? _selectedMenu; // Menú seleccionado actualmente

  @override
  void initState() {
    super.initState();
    _nutritionData = _loadNutritionDataForDate(_selectedDate);
    _loadCustomMeals(); // Cargar comidas personalizadas primero
    _loadSavedMenus(); // Cargar menús guardados
  }

  // 2. Añade este método para cargar los menús guardados
  Future<void> _loadSavedMenus() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientId)
              .get();

      if (doc.exists && doc.data()?.containsKey('savedMenus') == true) {
        setState(() {
          _savedMenus = List<String>.from(doc.data()!['savedMenus']);
        });
      }
    } catch (e) {
      print('Error cargando menús guardados: $e');
    }
  }

  // 3. Método para guardar el menú actual como un nuevo menú
  Future<void> _saveCurrentMenuAs(String menuName) async {
    if (menuName.isEmpty) return;

    try {
      // Obtener los datos de nutrición actuales
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientId)
              .collection('nutrition')
              .doc(dateStr)
              .get();

      if (doc.exists) {
        final data = doc.data()!;

        // Guardar el menú en la colección de menús
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.clientId)
            .collection('saved_menus')
            .doc(menuName)
            .set(data);

        // Actualizar la lista de menús guardados
        if (!_savedMenus.contains(menuName)) {
          setState(() {
            _savedMenus.add(menuName);
          });

          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientId)
              .set({
                'savedMenus': FieldValue.arrayUnion([menuName]),
              }, SetOptions(merge: true));
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Menú "$menuName" guardado exitosamente')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar menú: $e')));
      }
    }
  }

  // 4. Método para cargar un menú guardado a la fecha seleccionada
  Future<void> _loadMenuToDate(String menuName, DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // Obtener el menú guardado
      final menuDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientId)
              .collection('saved_menus')
              .doc(menuName)
              .get();

      if (menuDoc.exists) {
        // Copiar el menú a la fecha seleccionada
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.clientId)
            .collection('nutrition')
            .doc(dateStr)
            .set(menuDoc.data()!);

        setState(() {
          _selectedMenu = menuName;
          _nutritionData = _loadNutritionDataForDate(date);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Menú "$menuName" cargado para $dateStr')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar menú: $e')));
      }
    }
  }

  // Método para eliminar un menú guardado
  Future<void> _deleteMenu(String menuName) async {
    try {
      // Mostrar confirmación antes de eliminar
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Eliminar menú'),
              content: Text('¿Estás seguro de eliminar el menú "$menuName"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
      );

      if (confirm == true) {
        // Eliminar de Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.clientId)
            .collection('saved_menus')
            .doc(menuName)
            .delete();

        // Actualizar la lista local
        setState(() {
          _savedMenus.remove(menuName);
          if (_selectedMenu == menuName) {
            _selectedMenu = null;
          }
        });

        // Actualizar el array en el documento principal
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.clientId)
            .update({
              'savedMenus': FieldValue.arrayRemove([menuName]),
            });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Menú "$menuName" eliminado')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar menú: $e')));
      }
    }
  }

  // Método para renombrar un menú
  Future<void> _renameMenu(String oldName) async {
    final newNameController = TextEditingController(text: oldName);

    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Renombrar menú'),
            content: TextField(
              controller: newNameController,
              decoration: InputDecoration(
                labelText: 'Nuevo nombre',
                hintText: 'Ej: Menú Vegetariano Semanal',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(context, newNameController.text.trim()),
                child: Text('Guardar'),
              ),
            ],
          ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      try {
        // Obtener los datos del menú antiguo
        final menuDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.clientId)
                .collection('saved_menus')
                .doc(oldName)
                .get();

        if (menuDoc.exists) {
          // Crear nuevo menú con el nuevo nombre
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientId)
              .collection('saved_menus')
              .doc(newName)
              .set(menuDoc.data()!);

          // Eliminar el menú antiguo
          await _deleteMenu(oldName);

          // Actualizar la lista local
          setState(() {
            _savedMenus.remove(oldName);
            _savedMenus.add(newName);
            if (_selectedMenu == oldName) {
              _selectedMenu = newName;
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Menú renombrado a "$newName"')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al renombrar menú: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadCustomMeals() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientId)
              .get();

      if (doc.exists) {
        final data = doc.data()!;

        // Cargar nombres de visualización
        if (data.containsKey('customMeals')) {
          setState(() {
            _mealTypes = List<String>.from(data['customMeals']);
          });
        }

        // Si no existe mealIds, crearlos basados en los nombres actuales
        if (!data.containsKey('mealIds')) {
          await _initializeMealIds();
        }
      } else {
        setState(() {
          _mealTypes = ['Desayuno', 'Almuerzo', 'Cena'];
        });
        await _initializeCustomMeals();
        await _initializeMealIds();
      }
    } catch (e) {
      print('Error cargando comidas personalizadas: $e');
      setState(() {
        _mealTypes = ['Desayuno', 'Almuerzo', 'Cena'];
      });
    }
  }

  // Nueva función para inicializar IDs fijos
  Future<void> _initializeMealIds() async {
    final mealIds = _mealTypes.map((meal) => _generateMealId(meal)).toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.clientId)
        .set({'mealIds': mealIds}, SetOptions(merge: true));
  }

  String _generateMealId(String mealName) {
    // Convierte a minúsculas y reemplaza espacios
    return mealName.toLowerCase().replaceAll(' ', '_');
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
        return data; // ¡No verificar coincidencias! Los IDs se mantienen
      } else {
        final defaultData = await _getDefaultNutritionData();
        await docRef.set(defaultData);
        return defaultData;
      }
    } catch (e) {
      print('Error loading nutrition data: $e');
      return await _getDefaultNutritionData();
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

      List<String> mealIds = [];
      if (userDoc.exists && userDoc.data()!.containsKey('mealIds')) {
        mealIds = List<String>.from(userDoc.data()!['mealIds']);
      } else {
        // Si no hay IDs, generarlos desde los nombres actuales
        mealIds = _mealTypes.map((meal) => _generateMealId(meal)).toList();
      }

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

  // Método para obtener alimentos guardados
  Future<List<FoodItem>> _getSavedFoods() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('saved_foods') // Colección global
              .get();

      // Elimina duplicados por nombre (opcional)
      final uniqueFoods = <String, FoodItem>{};
      for (var doc in querySnapshot.docs) {
        final food = FoodItem.fromMap(doc.data());
        uniqueFoods[food.name] = food;
      }

      return uniqueFoods.values.toList();
    } catch (e) {
      print('Error obteniendo alimentos guardados: $e');
      return [];
    }
  }

  // Método para mostrar el diálogo de búsqueda
  Future<void> _showSearchFoodDialog(String mealName) async {
    final savedFoods = await _getSavedFoods();

    if (savedFoods.isEmpty) {
      // Si no hay alimentos guardados, mostrar directamente el diálogo para crear uno nuevo
      _showAddFoodDialog(mealName);
      return;
    }

    final selectedFood = await showDialog<FoodItem>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Selecciona un alimento'),
          children: [
            ...savedFoods
                .map(
                  (food) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, food),
                    child: ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.calories.toStringAsFixed(0)} kcal | '
                        'C:${food.carbs.toStringAsFixed(0)}g '
                        'P:${food.protein.toStringAsFixed(0)}g '
                        'G:${food.fats.toStringAsFixed(0)}g',
                      ),
                    ),
                  ),
                )
                .toList(),
            Divider(),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showAddFoodDialog(mealName);
              },
              child: ListTile(
                leading: Icon(Icons.add),
                title: Text('Crear nuevo alimento'),
              ),
            ),
          ],
        );
      },
    );

    if (selectedFood != null) {
      _addFoodToMeal(mealName, selectedFood);
    }
  }

  Future<void> _addFoodToMeal(String mealName, FoodItem food) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .collection('nutrition')
          .doc(dateStr);

      // Primero verifica si el alimento ya existe en saved_foods
      final existingFoodQuery =
          await FirebaseFirestore.instance
              .collection('saved_foods') // Colección global
              .where('name', isEqualTo: food.name)
              .limit(1)
              .get();

      // Si no existe, lo guardamos en saved_foods
      if (existingFoodQuery.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection('saved_foods') // Colección global
            .add(food.toMap());
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final defaultData = await _getDefaultNutritionData();
        final data = doc.exists ? doc.data()! : defaultData;

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

        transaction.set(docRef, data);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alimento agregado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar alimento: $e')),
        );
      }
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Puedes dejar espacio para otros elementos si los necesitas
          SizedBox(width: 40), // Espacio equilibrado
        ],
      ),
    );
  }

  Future<void> copyMealsSimple(String mealName) async {
    // 1. Obtener todos los clientes (sin filtro de coach)
    final query = await FirebaseFirestore.instance.collection('users').get();

    // 2. Mostrar diálogo simple de selección
    final selectedClient = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text('Seleccionar cliente origen'),
            children:
                query.docs.map((doc) {
                  final data = doc.data();
                  return SimpleDialogOption(
                    onPressed:
                        () => Navigator.pop(context, {
                          'id': doc.id,
                          'name': data['name'] ?? 'Sin nombre',
                        }),
                    child: Text(data['name'] ?? doc.id),
                  );
                }).toList(),
          ),
    );

    if (selectedClient != null) {
      // 3. Copiar directamente
      await _copyMealsFromClient(
        selectedClient['id'],
        selectedClient['name'],
        _selectedDate, // Usa la fecha actual seleccionada
        mealName,
      );
    }
  }

  Future<void> _copyMealsFromClient(
    String sourceClientId,
    String sourceClientName,
    DateTime sourceDate,
    String mealName,
  ) async {
    try {
      final sourceDateStr = DateFormat('yyyy-MM-dd').format(sourceDate);
      final currentDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Obtener datos de origen
      final sourceDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(sourceClientId)
              .collection('nutrition')
              .doc(sourceDateStr)
              .get();

      if (!sourceDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('No hay datos para copiar')));
        }
        return;
      }

      final sourceData = sourceDoc.data()!;
      final sourceMeals = List<Map<String, dynamic>>.from(
        sourceData['meals'] ?? [],
      );
      final sourceMeal = sourceMeals.firstWhere(
        (m) => m['name'] == mealName,
        orElse: () => {},
      );

      if (sourceMeal.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se encontró la comida $mealName')),
          );
        }
        return;
      }

      // Obtener referencia al documento destino
      final currentDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .collection('nutrition')
          .doc(currentDateStr);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final currentDoc = await transaction.get(currentDocRef);
        final currentData =
            currentDoc.exists
                ? Map<String, dynamic>.from(currentDoc.data()!)
                : await _getDefaultNutritionData();

        // Actualizar comidas
        final currentMeals = List<Map<String, dynamic>>.from(
          currentData['meals'] ?? [],
        );
        final targetMealIndex = currentMeals.indexWhere(
          (m) => m['name'] == mealName,
        );

        // Calcular diferencias para actualizar los totales
        double carbsToAdd = 0;
        double proteinToAdd = 0;
        double fatsToAdd = 0;
        double caloriesToAdd = 0;

        if (targetMealIndex != -1) {
          // Si la comida existe, combinar items
          final targetMeal = Map<String, dynamic>.from(
            currentMeals[targetMealIndex],
          );
          final targetItems = List<Map<String, dynamic>>.from(
            targetMeal['items'] ?? [],
          );
          final sourceItems = List<Map<String, dynamic>>.from(
            sourceMeal['items'] ?? [],
          );

          // Calcular los valores a agregar
          for (final item in sourceItems) {
            carbsToAdd += (item['carbs'] ?? 0).toDouble();
            proteinToAdd += (item['protein'] ?? 0).toDouble();
            fatsToAdd += (item['fats'] ?? 0).toDouble();
            caloriesToAdd += (item['calories'] ?? 0).toDouble();
          }

          targetItems.addAll(sourceItems);

          // Actualizar la comida
          targetMeal['items'] = targetItems;
          targetMeal['carbsConsumed'] =
              (targetMeal['carbsConsumed'] ?? 0) + carbsToAdd;
          targetMeal['proteinConsumed'] =
              (targetMeal['proteinConsumed'] ?? 0) + proteinToAdd;
          targetMeal['fatsConsumed'] =
              (targetMeal['fatsConsumed'] ?? 0) + fatsToAdd;
          targetMeal['caloriesConsumed'] =
              (targetMeal['caloriesConsumed'] ?? 0) + caloriesToAdd;

          currentMeals[targetMealIndex] = targetMeal;
        } else {
          // Si la comida no existe, agregarla completa
          currentMeals.add(sourceMeal);

          // Sumar todos los valores de la comida nueva
          final items = List<Map<String, dynamic>>.from(
            sourceMeal['items'] ?? [],
          );
          for (final item in items) {
            carbsToAdd += (item['carbs'] ?? 0).toDouble();
            proteinToAdd += (item['protein'] ?? 0).toDouble();
            fatsToAdd += (item['fats'] ?? 0).toDouble();
            caloriesToAdd += (item['calories'] ?? 0).toDouble();
          }
        }

        // Actualizar los totales generales
        currentData['carbs'] = {
          'consumed': (currentData['carbs']['consumed'] ?? 0) + carbsToAdd,
          'total': currentData['carbs']['total'] ?? 0,
        };

        currentData['protein'] = {
          'consumed': (currentData['protein']['consumed'] ?? 0) + proteinToAdd,
          'total': currentData['protein']['total'] ?? 0,
        };

        currentData['fats'] = {
          'consumed': (currentData['fats']['consumed'] ?? 0) + fatsToAdd,
          'total': currentData['fats']['total'] ?? 0,
        };

        currentData['calories'] = {
          'consumed':
              (currentData['calories']['consumed'] ?? 0) + caloriesToAdd,
          'total': currentData['calories']['total'] ?? 0,
        };

        currentData['meals'] = currentMeals;

        transaction.set(currentDocRef, currentData);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Comida copiada exitosamente')));
        setState(() {}); // Refrescar la vista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al copiar: $e')));
      }
    }
  }

  Future<void> _showMyFoodsDialog(String mealName) async {
    final savedFoods = await _getSavedFoods();
    String searchQuery = '';
    List<FoodItem> filteredFoods = savedFoods;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Mis Alimentos'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Buscar...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                          filteredFoods =
                              savedFoods
                                  .where(
                                    (food) => food.name.toLowerCase().contains(
                                      searchQuery,
                                    ),
                                  )
                                  .toList();
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    if (filteredFoods.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          searchQuery.isEmpty
                              ? 'No hay alimentos guardados'
                              : 'No se encontraron resultados',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Column(
                        children:
                            filteredFoods
                                .map(
                                  (food) => ListTile(
                                    title: Text(food.name),
                                    subtitle: Text(
                                      '${food.calories.toStringAsFixed(0)} kcal | '
                                      'C:${food.carbs.toStringAsFixed(0)}g '
                                      'P:${food.protein.toStringAsFixed(0)}g '
                                      'G:${food.fats.toStringAsFixed(0)}g',
                                    ),
                                    onTap: () {
                                      Navigator.pop(
                                        context,
                                        food,
                                      ); // Devuelve el alimento seleccionado
                                    },
                                    trailing: PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert),
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          _deleteSavedFood(food);
                                          setState(() {
                                            filteredFoods.remove(food);
                                          });
                                        }
                                      },
                                      itemBuilder:
                                          (BuildContext context) => [
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Text('Eliminar'),
                                            ),
                                          ],
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    ).then((selectedFood) {
      if (selectedFood != null && selectedFood is FoodItem) {
        _addFoodToMeal(mealName, selectedFood);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedFood.name} añadido a $mealName')),
        );
      }
    });
  }

  Future<void> _deleteSavedFood(FoodItem food) async {
    try {
      // Buscar el documento que contiene este alimento
      final query =
          await FirebaseFirestore.instance
              .collection('saved_foods') // Colección global
              .where('name', isEqualTo: food.name)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('saved_foods') // Colección global
            .doc(query.docs.first.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Alimento eliminado de la base compartida')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar alimento: $e')),
        );
      }
    }
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
                // Nueva sección de ejercicios
                Divider(thickness: 1),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ejercicios del día',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(
                            255,
                            10,
                            10,
                            10,
                          ), // Color de tu app
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add,
                          color: Color.fromARGB(255, 0, 115, 119),
                        ),
                        onPressed: _showAddExerciseDialog,
                      ),
                    ],
                  ),
                ),
                _buildExerciseList(), // Widget que mostrará la lista
                SizedBox(height: 24),
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
                  /*final duration =
                      _selectedPeriod == 'Día'
                          ? Duration(days: 1)
                          : _selectedPeriod == 'Semana'
                          ? Duration(days: 7)
                          : _selectedPeriod == 'Mes'
                          ? Duration(days: 30)
                          : Duration(days: 365);*/
                  setState(() {
                    _selectedDate = _selectedDate.subtract(Duration(days: 1));
                    _nutritionData = _loadNutritionDataForDate(_selectedDate);
                    _selectedMenu = null;
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
                  /*final duration =
                      _selectedPeriod == 'Día'
                          ? Duration(days: 1)
                          : _selectedPeriod == 'Semana'
                          ? Duration(days: 7)
                          : _selectedPeriod == 'Mes'
                          ? Duration(days: 30)
                          : Duration(days: 365);*/
                  setState(() {
                    _selectedDate = _selectedDate.add(Duration(days: 1));
                    _nutritionData = _loadNutritionDataForDate(_selectedDate);
                    _selectedMenu = null;
                  });
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.restaurant_menu),
                onSelected: (value) {
                  if (value == 'save') {
                    _showSaveMenuDialog();
                  } else {
                    _loadMenuToDate(value, _selectedDate);
                  }
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'save',
                      child: Text('Guardar menú actual'),
                    ),
                    PopupMenuDivider(),
                    if (_savedMenus.isNotEmpty)
                      ..._savedMenus
                          .map(
                            (menu) => PopupMenuItem(
                              value: menu,
                              child: Row(
                                children: [
                                  Expanded(child: Text(menu)),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, size: 16),
                                    itemBuilder:
                                        (context) => [
                                          PopupMenuItem(
                                            value: 'rename',
                                            child: Text('Renombrar'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                              'Eliminar',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                    onSelected: (action) {
                                      Navigator.pop(
                                        context,
                                      ); // Cerrar el menú principal primero
                                      if (action == 'rename') {
                                        _renameMenu(menu);
                                      } else if (action == 'delete') {
                                        _deleteMenu(menu);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    if (_savedMenus.isEmpty)
                      PopupMenuItem(
                        enabled: false,
                        child: Text('No hay menús guardados'),
                      ),
                  ];
                },
              ),
            ],
          ),
          if (_selectedMenu != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Menú: $_selectedMenu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 6. Diálogo para guardar el menú actual
  Future<void> _showSaveMenuDialog() async {
    final menuNameController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Guardar menú'),
            content: TextField(
              controller: menuNameController,
              decoration: InputDecoration(
                labelText: 'Nombre del menú',
                hintText: 'Ej: Menú Vegetariano',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveCurrentMenuAs(menuNameController.text.trim());
                },
                child: Text('Guardar'),
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
              trailing: PopupMenuButton<String>(
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'copy',
                        child: Text('Copiar comida de otro usuario'),
                      ),
                    ],
                onSelected: (_) => copyMealsSimple(safeMeal['name']),
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
            Padding(
              padding: EdgeInsets.only(
                bottom: 8,
              ), // Padding solo abajo para separar del resumen
              child: TextButton(
                onPressed:
                    () => _showMyFoodsDialog(
                      safeMeal['name']?.toString() ?? 'Comida',
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fastfood, color: Colors.black, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Mis Alimentos',
                      style: TextStyle(
                        color: Colors.black,
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
      final List<String>? suggestions =
          safeItem['suggestions'] != null
              ? List<String>.from(safeItem['suggestions'])
              : null;

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
                        [
                          if (safeItem['brand'] != null &&
                              safeItem['brand'].isNotEmpty)
                            safeItem['brand'],
                          safeItem['quantity'] ?? 'Cantidad',
                        ].join(', '),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      // Sección de sugerencias añadida aquí
                      if (suggestions != null && suggestions.isNotEmpty) ...[
                        SizedBox(height: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sugerencias:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children:
                                  suggestions
                                      .map(
                                        (suggestion) => Chip(
                                          label: Text(
                                            suggestion,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          backgroundColor: Color(
                                            0xFFFE7900,
                                          ).withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            side: BorderSide(
                                              color: Color(
                                                0xFFFE7900,
                                              ).withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ),
                      ],
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
            final food = items[index];

            // Obtener valores nutricionales (asegurando que no sean nulos)
            final carbs = (food['carbs'] ?? 0).toDouble();
            final protein = (food['protein'] ?? 0).toDouble();
            final fats = (food['fats'] ?? 0).toDouble();
            final calories = (food['calories'] ?? 0).toDouble();

            // Actualizar la comida (con prevención de valores negativos)
            meal['carbsConsumed'] = max(
              0,
              (meal['carbsConsumed'] ?? 0) - carbs,
            );
            meal['proteinConsumed'] = max(
              0,
              (meal['proteinConsumed'] ?? 0) - protein,
            );
            meal['fatsConsumed'] = max(0, (meal['fatsConsumed'] ?? 0) - fats);
            meal['caloriesConsumed'] = max(
              0,
              (meal['caloriesConsumed'] ?? 0) - calories,
            );

            // Eliminar el alimento
            items.removeAt(index);
            meal['items'] = items;
            meals[mealIndex] = meal;

            // Actualizar totales generales (con prevención de valores negativos)
            data['carbs']['consumed'] = max(
              0,
              (data['carbs']['consumed'] ?? 0) - carbs,
            );
            data['protein']['consumed'] = max(
              0,
              (data['protein']['consumed'] ?? 0) - protein,
            );
            data['fats']['consumed'] = max(
              0,
              (data['fats']['consumed'] ?? 0) - fats,
            );
            data['calories']['consumed'] = max(
              0,
              (data['calories']['consumed'] ?? 0) - calories,
            );
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

  // Método para agregar un ejercicio a Firestore
  Future<void> _addExercise(Exercise exercise) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .collection('workouts')
          .doc(dateStr);

      await docRef.set({
        'exercises': FieldValue.arrayUnion([exercise.toMap()]),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ejercicio agregado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar ejercicio: $e')),
        );
      }
    }
  }

  // Método para mostrar el diálogo
  Future<void> _showAddExerciseDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) =>
              AddExerciseDialog(onAdd: (exercise) => _addExercise(exercise)),
    );
  }

  Widget _buildExerciseList() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientId)
              .collection('workouts')
              .doc(dateStr)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('No hay ejercicios registrados hoy'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final exercises =
            (data['exercises'] as List<dynamic>?)
                ?.map((e) => Exercise.fromMap(e))
                .toList() ??
            [];

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return ListTile(
              title: Text(
                'Ejercicios Guardados',
                style: TextStyle(
                  color: Colors.black, // Opcional: color personalizado
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteExercise(dateStr, exercise),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteExercise(String dateStr, Exercise exercise) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .collection('workouts')
          .doc(dateStr)
          .update({
            'exercises': FieldValue.arrayRemove([exercise.toMap()]),
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ejercicio eliminado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
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
      builder:
          (context) => AddFoodDialog(
            onAdd: (food) async {
              // Primero guardar el alimento en la colección de alimentos guardados
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.clientId)
                  .collection('saved_foods')
                  .add(food.toMap());
              // Luego añadirlo a la comida actual
              _addFoodToMeal(mealName, food);
            },
          ),
    );
  }
}
