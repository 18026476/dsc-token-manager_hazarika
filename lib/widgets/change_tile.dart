import 'package:flutter/material.dart';
import '../models/change_model.dart';

class ChangeTile extends StatelessWidget {
  final ChangeModel change;

  const ChangeTile({
    super.key,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    Color colour = Colors.blue;

    switch (change.severity) {
      case 'Critical':
        colour = Colors.red;
        break;
      case 'Warning':
        colour = Colors.orange;
        break;
      case 'Info':
        colour = Colors.blue;
        break;
    }

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.change_circle,
          color: colour,
        ),
        title: Text(change.title),
        subtitle: Text(change.description),
        trailing: Text(change.severity),
      ),
    );
  }
}
