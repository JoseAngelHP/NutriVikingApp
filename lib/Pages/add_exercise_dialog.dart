import 'package:flutter/material.dart';
import 'package:nutri_viking_app/Pages/Exercise.dart';

class AddExerciseDialog extends StatefulWidget {
  final Function(Exercise) onAdd;
  final Exercise? initialExercise;

  const AddExerciseDialog({
    Key? key,
    required this.onAdd,
    this.initialExercise,
  }) : super(key: key);

  @override
  _AddExerciseDialogState createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _repsController;
  late TextEditingController _setsController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialExercise?.name ?? '',
    );
    _repsController = TextEditingController(
      text: widget.initialExercise?.reps.toString() ?? '',
    );
    _setsController = TextEditingController(
      text: widget.initialExercise?.sets.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.initialExercise?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialExercise == null ? 'Añadir Ejercicio' : 'Editar Ejercicio'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre del ejercicio'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      decoration: InputDecoration(labelText: 'Repeticiones'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa repeticiones';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      decoration: InputDecoration(labelText: 'Series'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa series';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Notas (opcional)'),
                maxLines: 2,
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final exercise = Exercise(
                name: _nameController.text,
                reps: int.parse(_repsController.text),
                sets: int.parse(_setsController.text),
                notes: _notesController.text.isNotEmpty ? _notesController.text : null,
              );
              widget.onAdd(exercise);
              Navigator.pop(context);
            }
          },
          child: Text('Guardar'),
        ),
      ],
    );
  }
}