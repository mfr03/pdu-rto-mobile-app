import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import '../../../../data/services/pdu_api/model/well_active.dart';
import '../../model/parameter_item.dart';
import 'add_parameter_dialog.dart';


class HomeScreen extends StatefulWidget {
  final WellActive wellActive;
  const HomeScreen({Key? key, required this.wellActive}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Box<ParameterItem> box = Hive.box<ParameterItem>('user_parameters');

  @override
  Widget build(BuildContext context) {
    final params = box.values.toList();
    if (params.isEmpty) return const Center(child: Text('No parameters selected.'));
    return SafeArea(
      child: ListView(
        children: params
            .map((p) => ListTile(
          leading: CircleAvatar(backgroundColor: p.color),
          title: Text(p.name),
          trailing: Text(p.value),
        ))
            .toList(),
      ),
    );
  }
}
