import 'package:flutter/material.dart';

class DietType {
  final String name;
  final int carbs;
  final int proteins;
  final int fats;

  DietType({
    required this.name,
    required this.carbs,
    required this.proteins,
    required this.fats,
  });
}

class DietTypeSelector extends StatelessWidget {
  final Function(DietType) onDietSelected;
  final String currentDiet;

  const DietTypeSelector({
    Key? key,
    required this.onDietSelected,
    required this.currentDiet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dietOptions = [
      DietType(name: 'Estándar', carbs: 50, proteins: 20, fats: 30),
      DietType(name: 'Equilibrada', carbs: 50, proteins: 25, fats: 25),
      DietType(name: 'Baja en grasas', carbs: 60, proteins: 25, fats: 15),
      DietType(name: 'Alta en proteínas', carbs: 25, proteins: 40, fats: 35),
      DietType(name: 'Cetogénica', carbs: 5, proteins: 30, fats: 65),
    ];

    return InkWell(
      onTap: () => _showDietSelectionDialog(context, dietOptions),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tipo de dieta',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              currentDiet,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showDietSelectionDialog(BuildContext context, List<DietType> options) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar tipo de dieta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...options.map((diet) => ListTile(
                    title: Text(diet.name),
                    subtitle: Text(
                        'Carb: ${diet.carbs}% Prot: ${diet.proteins}% Grasas: ${diet.fats}%'),
                    onTap: () {
                      onDietSelected(diet);
                      Navigator.pop(context);
                    },
                  )),
              const Divider(),
              ListTile(
                title: const Text('Personalizada'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCustomDietDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomDietDialog(BuildContext context) {
    final carbsController = TextEditingController();
    final proteinsController = TextEditingController();
    final fatsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dieta personalizada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: carbsController,
                decoration: const InputDecoration(
                  labelText: 'Carbohidratos (%)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: proteinsController,
                decoration: const InputDecoration(
                  labelText: 'Proteínas (%)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: fatsController,
                decoration: const InputDecoration(
                  labelText: 'Grasas (%)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final carbs = int.tryParse(carbsController.text) ?? 0;
                final proteins = int.tryParse(proteinsController.text) ?? 0;
                final fats = int.tryParse(fatsController.text) ?? 0;

                if (carbs + proteins + fats == 100) {
                  onDietSelected(DietType(
                    name: 'Personalizada',
                    carbs: carbs,
                    proteins: proteins,
                    fats: fats,
                  ));
                  Navigator.pop(context);
                  Navigator.pop(context); // Cerrar ambos diálogos
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La suma debe ser 100%'),
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}