import 'package:flutter/material.dart';

class MealsCustomizationPage extends StatefulWidget {
  final List<String> currentMeals;

  const MealsCustomizationPage({Key? key, required this.currentMeals}) : super(key: key);

  @override
  _MealsCustomizationPageState createState() => _MealsCustomizationPageState();
}

class _MealsCustomizationPageState extends State<MealsCustomizationPage> {
  late List<TextEditingController> _mealControllers;
  late int _numberOfMeals; // Cambiado para inicializarse en initState

  @override
  void initState() {
    super.initState();
    _numberOfMeals = widget.currentMeals.isNotEmpty 
        ? widget.currentMeals.length 
        : 3; // Valor por defecto solo si no hay comidas guardadas
    _initializeControllers();
  }

  void _initializeControllers() {
    _mealControllers = List.generate(
      10,
      (index) => TextEditingController(
        text: index < widget.currentMeals.length 
            ? widget.currentMeals[index]
            : 'Comida ${index + 1}',
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _mealControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar Comidas'),
        backgroundColor: const Color(0xFFb51837),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMealsNumberSelector(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _numberOfMeals,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: _mealControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Nombre Comida ${index + 1}',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _clearMeal(index),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveMeals,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 143, 231, 162),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'GUARDAR',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsNumberSelector() {
    return Row(
      children: [
        const Text('Número de comidas:', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        DropdownButton<int>(
          value: _numberOfMeals,
          items: List.generate(10, (index) => index + 1)
              .map((count) => DropdownMenuItem(
                    value: count,
                    child: Text('$count'),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _numberOfMeals = value!);
          },
        ),
      ],
    );
  }

  void _clearMeal(int index) {
    setState(() {
      _mealControllers[index].text = 'Comida ${index + 1}';
    });
  }

  Future<void> _saveMeals() async {
    // Validación de campos vacíos
    for (int i = 0; i < _numberOfMeals; i++) {
      if (_mealControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor ingrese nombre para Comida ${i + 1}'),
          ),
        );
        return;
      }
    }

    final meals =
        _mealControllers
            .sublist(0, _numberOfMeals)
            .map((controller) => controller.text.trim())
            .toList();

    Navigator.pop(context, meals);
  }
}