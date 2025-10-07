// lib/ui/widgets/data_table.dart
import 'package:flutter/material.dart';

class CustomDataTable extends StatelessWidget {
  final List<String> headers;
  final List<List<dynamic>> rows;
  final Function(dynamic)? onRowTap;

  const CustomDataTable({
    Key? key,
    required this.headers,
    required this.rows,
    this.onRowTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
        rows: rows.map((row) {
          return DataRow(
            cells: row.map((cell) => DataCell(Text(cell.toString()))).toList(),
            onSelectChanged: (selected) {
              if (selected == true && onRowTap != null) onRowTap!(row);
            },
          );
        }).toList(),
      ),
    );
  }
}
