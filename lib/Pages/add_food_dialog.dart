import 'package:flutter/material.dart';
import 'package:nutri_viking_app/Pages/food_model.dart';

class AddFoodDialog extends StatefulWidget {
  final Function(FoodItem) onAdd;
  final FoodItem? initialFood;

  const AddFoodDialog({
    Key? key, 
    required this.onAdd,
    this.initialFood,
  }) : super(key: key);

  @override
  _AddFoodDialogState createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _caloriesController;
  late TextEditingController _carbsController;
  late TextEditingController _proteinController;
  late TextEditingController _fatsController;
  late TextEditingController _sodiumController; // Nuevo controlador para sodio
  late TextEditingController _potassiumController; // Nuevo controlador para potasio
  late TextEditingController _brandController; // Nuevo controlador para la marca

  // Valores base por 100g
  double _baseCalories = 0;
  double _baseCarbs = 0;
  double _baseProtein = 0;
  double _baseFats = 0;
  bool _initialValuesSet = false;
  String _lastQuantity = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFood?.name ?? '');
    _quantityController = TextEditingController(text: widget.initialFood?.quantity ?? '100g');
    _brandController = TextEditingController(text: widget.initialFood?.brand ?? ''); // Inicializar controlador de marca
    
    // Inicializar valores base si estamos editando
    if (widget.initialFood != null) {
      _updateBaseValuesFromQuantity(widget.initialFood!);
      _initialValuesSet = true;
    }
    
    _caloriesController = TextEditingController(
      text: widget.initialFood?.calories.toStringAsFixed(0) ?? ''
    );
    _carbsController = TextEditingController(
      text: widget.initialFood?.carbs.toStringAsFixed(1) ?? ''
    );
    _proteinController = TextEditingController(
      text: widget.initialFood?.protein.toStringAsFixed(1) ?? ''
    );
    _fatsController = TextEditingController(
      text: widget.initialFood?.fats.toStringAsFixed(1) ?? ''
    );
    // Nuevos controladores con valores iniciales
    _sodiumController = TextEditingController(
      text: widget.initialFood?.sodium?.toStringAsFixed(1) ?? ''
    );
    _potassiumController = TextEditingController(
      text: widget.initialFood?.potassium?.toStringAsFixed(1) ?? ''
    );

    // Agregar listeners
    _quantityController.addListener(_calculateNutrients);
    
    // Para nuevos alimentos
    if (widget.initialFood == null) {
      _caloriesController.addListener(_updateBaseValuesFromInput);
      _carbsController.addListener(_updateBaseValuesFromInput);
      _proteinController.addListener(_updateBaseValuesFromInput);
      _fatsController.addListener(_updateBaseValuesFromInput);
    }
  }

  void _updateBaseValuesFromQuantity(FoodItem food) {
    // Extraer la cantidad numérica (ej. "200g" -> 200)
    final quantity = double.tryParse(food.quantity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100;
    final factor = 100 / quantity; // Factor inverso para obtener valores por 100g
    
    _baseCalories = food.calories * factor;
    _baseCarbs = food.carbs * factor;
    _baseProtein = food.protein * factor;
    _baseFats = food.fats * factor;
  }

  void _updateBaseValuesFromInput() {
    if (_quantityController.text.isEmpty) return;
    
    final quantity = double.tryParse(_quantityController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100;
    final factor = 100 / quantity;
    
    if (_caloriesController.text.isNotEmpty &&
        _carbsController.text.isNotEmpty &&
        _proteinController.text.isNotEmpty &&
        _fatsController.text.isNotEmpty) {
      
      setState(() {
        _baseCalories = (double.tryParse(_caloriesController.text) ?? 0) * factor;
        _baseCarbs = (double.tryParse(_carbsController.text) ?? 0) * factor;
        _baseProtein = (double.tryParse(_proteinController.text) ?? 0) * factor;
        _baseFats = (double.tryParse(_fatsController.text) ?? 0) * factor;
        _initialValuesSet = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatsController.dispose();
    _sodiumController.dispose(); // Dispose del nuevo controlador
    _potassiumController.dispose(); // Dispose del nuevo controlador
    _brandController.dispose(); // Dispose del controlador de marca
    super.dispose();
  }

  void _calculateNutrients() {
    if (!_initialValuesSet || _quantityController.text == _lastQuantity) return;
    _lastQuantity = _quantityController.text;

    final quantity = double.tryParse(_quantityController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100;
    final factor = quantity / 100;

    setState(() {
      _caloriesController.text = (_baseCalories * factor).toStringAsFixed(0);
      _carbsController.text = (_baseCarbs * factor).toStringAsFixed(1);
      _proteinController.text = (_baseProtein * factor).toStringAsFixed(1);
      _fatsController.text = (_baseFats * factor).toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialFood == null ? 'Agregar Alimento' : 'Editar Alimento'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre del alimento'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _brandController, // Campo para la marca
                decoration: InputDecoration(labelText: 'Marca (opcional)'),
              ),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Cantidad (ej. 100g)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una cantidad';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (_initialValuesSet) {
                    _calculateNutrients();
                  }
                },
              ),
              TextFormField(
                controller: _caloriesController,
                decoration: InputDecoration(labelText: 'Calorías (kcal)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa las calorías';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (widget.initialFood != null) {
                    _updateBaseValuesFromInput();
                  }
                },
              ),
              TextFormField(
                controller: _carbsController,
                decoration: InputDecoration(labelText: 'Carbohidratos (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa los carbohidratos';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (widget.initialFood != null) {
                    _updateBaseValuesFromInput();
                  }
                },
              ),
              TextFormField(
                controller: _proteinController,
                decoration: InputDecoration(labelText: 'Proteínas (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa las proteínas';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (widget.initialFood != null) {
                    _updateBaseValuesFromInput();
                  }
                },
              ),
              TextFormField(
                controller: _fatsController,
                decoration: InputDecoration(labelText: 'Grasas (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa las grasas';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (widget.initialFood != null) {
                    _updateBaseValuesFromInput();
                  }
                },
              ),
              // Nuevos campos para sodio y potasio
              TextFormField(
                controller: _sodiumController,
                decoration: InputDecoration(labelText: 'Sodio (mg) (opcional)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _potassiumController,
                decoration: InputDecoration(labelText: 'Potasio (mg) (opcional)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text(widget.initialFood == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newFood = FoodItem(
        id: widget.initialFood?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        quantity: _quantityController.text,
        calories: double.parse(_caloriesController.text),
        carbs: double.parse(_carbsController.text),
        protein: double.parse(_proteinController.text),
        fats: double.parse(_fatsController.text),
        sodium: _sodiumController.text.isNotEmpty ? double.tryParse(_sodiumController.text) : null,
        potassium: _potassiumController.text.isNotEmpty ? double.tryParse(_potassiumController.text) : null,
        brand: _brandController.text.isNotEmpty ? _brandController.text : null, // Añadir la marca
      );
      widget.onAdd(newFood);
    }
  }
}