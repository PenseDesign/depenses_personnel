import 'package:flutter/material.dart';
import 'package:gestion_depenses/models/transaction.dart'; // Modèle pour les transactions.
import 'package:intl/intl.dart'; // Pour formater les dates.
import 'package:fl_chart/fl_chart.dart'; // Bibliothèque pour les graphiques.

void main() {
  runApp(const MyApp()); // Point d'entrée de l'application.
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Expenses', // Titre de l'application.
      theme: ThemeData(
        primarySwatch: Colors.purple, // Couleur principale de l'application.
      ),
      home: const MyHomePage(), // Page principale de l'application.
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Liste des transactions.
  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      titre: 'Achat téléphone',
      montant: 100,
      date: DateTime.now(), // Date actuelle.
    ),
    Transaction(
      id: '2',
      titre: 'Achat TV',
      montant: 200,
      date: DateTime.now().subtract(const Duration(days: 1)), // Hier.
    ),
    Transaction(
      id: '3',
      titre: 'Courses',
      montant: 50,
      date: DateTime.now().subtract(const Duration(days: 3)), // Il y a 3 jours.
    ),
  ];

  // Contrôleurs pour les champs de texte.
  final _titreController = TextEditingController();
  final _montantController = TextEditingController();
  DateTime? _selectedDate; // Date sélectionnée.

  @override
  void dispose() {
    _titreController.dispose(); // Libération des ressources.
    _montantController.dispose();
    super.dispose();
  }

  // Ajout d'une nouvelle transaction.
  void _addTransaction() {
    final enteredTitre = _titreController.text;
    final enteredMontant = double.tryParse(_montantController.text) ?? 0.0;

    // Validation des champs.
    if (enteredTitre.isEmpty || enteredMontant <= 0 || _selectedDate == null) {
      return;
    }

    setState(() {
      _transactions.add(Transaction(
        id: DateTime.now().toString(), // ID unique.
        titre: enteredTitre,
        montant: enteredMontant,
        date: _selectedDate!,
      ));
    });

    Navigator.of(context).pop(); // Fermer la modale.
  }

  // Ouvrir une modale pour ajouter une transaction.
  void _startAddNewTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return GestureDetector(
          onTap: () {}, // Empêche la fermeture lors d'un clic.
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _titreController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                TextField(
                  controller: _montantController,
                  decoration: const InputDecoration(labelText: 'Montant'),
                  keyboardType: TextInputType.number, // Saisie numérique.
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'No Date chosen!'
                            : 'Date choisie: ${DateFormat.yMMMd().format(_selectedDate!)}',
                      ),
                    ),
                    TextButton(
                      onPressed: _presentDatePicker,
                      child: const Text(
                        'Choose Date',
                        style: TextStyle(fontWeight: FontWeight.bold,color: Colors.purple),
                        
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _addTransaction,
                  child: const Text('Add Transaction'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Afficher le sélecteur de date.
  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Date initiale.
      firstDate: DateTime(2020), // Date minimale.
      lastDate: DateTime.now(), // Date maximale.
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate; // Mettre à jour la date sélectionnée.
      });
    });
  }

  // Calcul des transactions groupées par jour de la semaine.
  List<Map<String, Object>> get groupedTransactions {
    return List.generate(7, (index) {
      final weekDay = DateTime.now().subtract(Duration(days: index));
      double totalSum = 0;

      for (var tx in _transactions) {
        if (tx.date.day == weekDay.day &&
            tx.date.month == weekDay.month &&
            tx.date.year == weekDay.year) {
          totalSum += tx.montant;
        }
      }

      return {
        'day': DateFormat.E().format(weekDay).substring(0, 1), // Jour abrégé.
        'amount': totalSum, // Somme totale.
      };
    }).reversed.toList(); // Inverser l'ordre.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Expenses",
        selectionColor: Color.fromRGBO(255, 255, 255, 1)),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 30),
            onPressed: () => _startAddNewTransaction(context),
            padding: EdgeInsets.all(20),
          ),
        ],
      ),
      body: Column(
        children: [
          // Section pour le graphique
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.purple, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              height: 250, // Hauteur du graphique.
              child: BarChart(
                BarChartData(
                  barGroups: groupedTransactions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (data['amount'] as double),
                          color: Colors.purple,
                          width: 20,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Pas de titres à gauche.
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Pas de titres en haut.
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Pas de titres à droite.
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index >= 0 && index < groupedTransactions.length) {
                            return Text(
                              groupedTransactions[index]['day'] as String,
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false), // Pas de bordures.
                  gridData: FlGridData(show: false), // Pas de grille.
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(2)}', // Montant affiché.
                          const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Section pour les transactions
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (ctx, index) {
                final tx = _transactions[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.purple,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FittedBox(
                          child: Text(
                            '${tx.montant.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      tx.titre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().format(tx.date),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _transactions.removeAt(index); // Supprime la transaction.
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellow,
        onPressed: () => _startAddNewTransaction(context),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
