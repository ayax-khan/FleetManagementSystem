// lib/ui/widgets/file_picker.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CustomFilePicker extends StatelessWidget {
  final Function(String?) onFilePicked;

  const CustomFilePicker({Key? key, required this.onFilePicked})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        onFilePicked(result?.files.single.path);
      },
      child: Text('Pick File'),
    );
  }
}
