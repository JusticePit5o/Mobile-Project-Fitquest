import 'package:flutter/material.dart';

/*
  goals_screen.dart
  Screen for creating and listing user goals. In the scaffolded app this
  screen currently stores goals in-memory and provides a dialog to add
  new goals. Can be extended to persist goals to local DB or Firestore.
*/

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Map<String, dynamic>> _goals = [];

  Future<void> _addGoalDialog() async {
    final titleCtl = TextEditingController();
    final targetCtl = TextEditingController();
    final descCtl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleCtl,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: descCtl,
                decoration: const InputDecoration(labelText: 'Description')),
            TextField(
                controller: targetCtl,
                decoration:
                    const InputDecoration(labelText: 'Target (e.g., km)'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtl.text.trim().isEmpty) return;
              final target = int.tryParse(targetCtl.text.trim()) ?? 0;
              setState(() {
                _goals.insert(0, {
                  'title': titleCtl.text.trim(),
                  'description': descCtl.text.trim(),
                  'target': target,
                  'created_at': DateTime.now().toIso8601String()
                });
              });
              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Goal added')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _goals.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag, size: 100, color: Colors.green[300]),
                    const SizedBox(height: 20),
                    const Text('Goals Dashboard',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text('Set and track your fitness goals here',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                        onPressed: _addGoalDialog,
                        child: const Text('Set New Goal')),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _goals.length,
                      itemBuilder: (context, i) {
                        final g = _goals[i];
                        return Card(
                          child: ListTile(
                            title: Text(g['title'] ?? ''),
                            subtitle: Text(g['description'] ?? ''),
                            trailing: Text('Target: ${g['target']}'),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton.icon(
                        onPressed: _addGoalDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('New Goal')),
                  )
                ],
              ),
      ),
    );
  }
}
