// lib/ui/screens/import_wizard_screen.dart
import 'package:flutter/material.dart';
import '../../services/import_service.dart';
import '../theme.dart';
import '../widgets/file_picker.dart';

class ImportWizardScreen extends StatefulWidget {
  const ImportWizardScreen({Key? key}) : super(key: key);

  @override
  _ImportWizardScreenState createState() => _ImportWizardScreenState();
}

class _ImportWizardScreenState extends State<ImportWizardScreen> {
  String? _filePath;
  bool _isImporting = false;
  String? _statusMessage;
  int _step = 0; // 0: Pick file, 1: Map sheets, 2: Validate, 3: Import

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wizard')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        steps: [
          Step(
            title: const Text('Pick File'),
            content: Column(
              children: [
                CustomFilePicker(
                  onFilePicked: (path) => setState(() => _filePath = path),
                ),
                if (_filePath != null) Text('Selected: $_filePath'),
              ],
            ),
          ),
          Step(
            title: const Text('Map Sheets'),
            content: const Text(
              'Configure mappings',
            ), // List sheets and entities
          ),
          Step(
            title: const Text('Validate'),
            content: const Text('Validation results'), // Show errors
          ),
          Step(
            title: const Text('Import'),
            content: ElevatedButton(
              onPressed: _isImporting ? null : _import,
              child: const Text('Start Import'),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_step < 3) setState(() => _step++);
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _import() async {
    setState(() => _isImporting = true);
    try {
      if (_filePath != null) {
        await ImportService().importFromExcel(_filePath!);
        setState(() => _statusMessage = 'Import successful');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Import failed: $e');
    }
    setState(() => _isImporting = false);
  }

  // Extend: Detailed wizard steps, previews, error reports
}
