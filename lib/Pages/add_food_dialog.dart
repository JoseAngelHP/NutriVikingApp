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

  @override
  void initState() {
    super.initState();
    // Inicializar los controladores con los valores del alimento existente (si hay)
    _nameController = TextEditingController(text: widget.initialFood?.name ?? '');
    _quantityController = TextEditingController(text: widget.initialFood?.quantity ?? '');
    _caloriesController = TextEditingController(text: widget.initialFood?.calories.toStringAsFixed(0) ?? '');
    _carbsController = TextEditingController(text: widget.initialFood?.carbs.toStringAsFixed(0) ?? '');
    _proteinController = TextEditingController(text: widget.initialFood?.protein.toStringAsFixed(0) ?? '');
    _fatsController = TextEditingController(text: widget.initialFood?.fats.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatsController.dispose();
    super.dispose();
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
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Cantidad (ej. 100g)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una cantidad';
                  }
                  return null;
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
      );
      widget.onAdd(newFood);
    }
  }
}