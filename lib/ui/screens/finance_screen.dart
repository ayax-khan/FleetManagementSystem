// lib/ui/screens/finance_screen.dart
import 'package:fleet_management/models/allowance.dart';
import 'package:fleet_management/models/expense.dart';
import 'package:fleet_management/services/hive_service.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:intl/intl.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  _FinanceScreenState createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<Allowance> _allowances = [];
  bool _isLoading = false;
  Allowance? _editingAllowance;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _date;
  String _type = 'conveyance';
  String _status = 'pending';
  String? _selectedDriver;

  @override
  void initState() {
    super.initState();
    _loadAllowances();
  }

  Future<void> _loadAllowances() async {
    setState(() => _isLoading = true);
    _allowances = await HiveService().getAll<Allowance>('allowances');
    setState(() => _isLoading = false);
  }

  void _showAddEditDialog({Allowance? allowance}) {
    _editingAllowance = allowance;
    if (allowance != null) {
      _amountController.text = allowance.amount.toString();
      _descriptionController.text = allowance.description ?? '';
      _date = allowance.date;
      _type = allowance.type;
      _status = allowance.status;
      _selectedDriver = allowance.driverId;
    } else {
      // Clear
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            _editingAllowance == null ? 'Add Allowance' : 'Edit Allowance',
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedDriver,
                  items: [], // From drivers
                  onChanged: (value) => _selectedDriver = value,
                  decoration: const InputDecoration(labelText: 'Driver'),
                ),
                DropdownButtonFormField<String>(
                  value: _type,
                  items:
                      [
                            'conveyance',
                            'overtime',
                            'reimbursement',
                            'private_use',
                            'other',
                          ]
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                  onChanged: (value) => _type = value!,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                ListTile(
                  title: Text(
                    _date == null
                        ? 'Date'
                        : DateFormat('yyyy-MM-dd').format(_date!),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                DropdownButtonFormField<String>(
                  value: _status,
                  items: ['pending', 'approved', 'rejected', 'paid']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => _status = value!,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _saveAllowance,
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAllowance() async {
    final allowance = Allowance(
      driverId: _selectedDriver ?? '',
      type: _type,
      amount: double.parse(_amountController.text),
      date: _date ?? DateTime.now(),
      description: _descriptionController.text,
      status: _status,
    );
    if (_editingAllowance == null) {
      await HiveService().add<Allowance>('allowances', allowance);
    } else {
      await HiveService().update<Allowance>(
        'allowances',
        _editingAllowance!.id!,
        allowance,
      );
    }
    Navigator.pop(context);
    _loadAllowances();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Allowances / Finance')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _allowances.length,
              itemBuilder: (context, index) {
                final a = _allowances[index];
                return ListTile(
                  title: Text('${a.type} - Rs ${a.amount}'),
                  subtitle: Text('Date: ${a.date} - Status: ${a.status}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddEditDialog(allowance: a),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await HiveService().delete<Allowance>(
                            'allowances',
                            a.id!,
                          );
                          _loadAllowances();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Extend: Budget views, POL reports integration
}
