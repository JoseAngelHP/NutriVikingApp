import 'package:flutter/material.dart';
import 'package:nutri_viking_app/Pages/Exercise.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late TextEditingController _pdfUrlController;

  @override
  void initState() {
    super.initState();
    _pdfUrlController = TextEditingController(
      text: widget.initialExercise?.pdfUrl ?? '',
    );
  }

  @override
  void dispose() {
    _pdfUrlController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la URL: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar PDF'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _pdfUrlController,
                decoration: InputDecoration(
                  labelText: 'URL del PDF',
                  hintText: 'https://ejemplo.com/ejercicio.pdf',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la URL del PDF';
                  }
                  if (!value.startsWith('http://') && !value.startsWith('https://')) {
                    return 'La URL debe comenzar con http:// o https://';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              if (_pdfUrlController.text.isNotEmpty)
                InkWell(
                  onTap: () => _launchURL(_pdfUrlController.text),
                  child: Text(
                    'Previsualizar PDF',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
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
                pdfUrl: _pdfUrlController.text,
                // Mantenemos los otros campos vacíos o con valores por defecto
                name: '',
                //reps: 0,
                //sets: 0,
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