class Exercise {
  final String name;
  //final int reps;
  //final int sets;
  final String? notes; // Opcional: notas adicionales
  final String? pdfUrl; // Nuevo campo para la URL del PDF

  Exercise({
    required this.name,
    //required this.reps,
    //required this.sets,
    this.notes,
    this.pdfUrl,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      //'reps': reps,
      //'sets': sets,
      'notes': notes ?? '',
      'pdfUrl': pdfUrl ?? '', // Añadido el campo pdfUrl
    };
  }

  // Crear desde un Map (de Firestore)
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      //reps: map['reps']?.toInt() ?? 0,
      //sets: map['sets']?.toInt() ?? 0,
      notes: map['notes'],
      pdfUrl: map['pdfUrl'], // Añadido el campo pdfUrl
    );
  }
}