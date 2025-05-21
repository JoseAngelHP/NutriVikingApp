// calorie_requirement_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CalorieRequirementPage extends StatefulWidget {
  final double currentCalories;
  final String clientId;

  const CalorieRequirementPage({
    Key? key,
    required this.currentCalories,
    required this.clientId,
  }) : super(key: key);

  @override
  _CalorieRequirementPageState createState() => _CalorieRequirementPageState();
}

class _CalorieRequirementPageState extends State<CalorieRequirementPage> {
  late TextEditingController _calorieController;

  @override
  void initState() {
    super.initState();
    _calorieController = TextEditingController(
      text: widget.currentCalories.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _calorieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requerimiento Calórico'),
        backgroundColor: const Color(0xFFb51837),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _calorieController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calorías diarias (kcal)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveCalories,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFb51837),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCalories() async {
    if (_calorieController.text.isEmpty) return;

    try {
      final calories = double.tryParse(_calorieController.text) ?? 0;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .update({
            'calorieRequirement': calories,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Navigator.pop(context, calories);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }
}