import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ImportScreen extends StatefulWidget {
  const ImportScreen({Key? key}) : super(key: key);

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  // File picker state
  File? selectedFile;
  String? fileName;
  bool isFileUploading = false;
  
  // Analysis results
  Map<String, dynamic>? analysisResult;
  bool isAnalyzing = false;
  String? analysisError;
  
  // Import state
  List<String> selectedSheets = [];
  Map<String, String> sheetEntityMappings = {};
  bool isImporting = false;
  bool clearExistingData = false;
  
  // Preview state
  String? previewSheet;
  List<List<dynamic>>? previewData;
  List<String>? previewColumns;

  final String baseUrl = 'http://127.0.0.1:8000/api/v1/excel';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Import Data from Excel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFileSelectionCard(),
            const SizedBox(height: 24),
            if (analysisResult != null) ...[
              _buildSheetsSelectionCard(),
              const SizedBox(height: 24),
              if (selectedSheets.isNotEmpty) _buildPreviewCard(),
              const SizedBox(height: 24),
              if (selectedSheets.isNotEmpty) _buildImportOptionsCard(),
              const SizedBox(height: 24),
              if (selectedSheets.isNotEmpty) _buildImportButtonCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.upload_file,
                    color: Color(0xFF1565C0),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Excel File',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Choose an Excel file (.xlsx or .xls) containing your fleet data',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (selectedFile == null) ...[
              GestureDetector(
                onTap: isFileUploading ? null : _pickFile,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF1565C0).withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF1565C0).withOpacity(0.05),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isFileUploading) ...[
                        const CircularProgressIndicator(
                          color: Color(0xFF1565C0),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Analyzing file...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: Color(0xFF1565C0),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Click to browse or drag and drop',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          'Supports .xlsx and .xls files',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName ?? 'Selected file',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (analysisResult != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${analysisResult!['total_sheets']} sheets found',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearFile,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (analysisError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        analysisError!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSheetsSelectionCard() {
    if (analysisResult == null || analysisResult!['sheets_info'] == null) {
      return const SizedBox.shrink();
    }

    final sheetsInfo = analysisResult!['sheets_info'] as Map<String, dynamic>;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.table_view,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Sheets to Import',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Choose which sheets contain data you want to import',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...sheetsInfo.keys.map((sheetName) {
              final sheetInfo = sheetsInfo[sheetName] as Map<String, dynamic>;
              final isSelected = selectedSheets.contains(sheetName);
              final detectedEntity = sheetInfo['detected_entity'] as String;
              final rowCount = sheetInfo['row_count'] as int;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected 
                      ? const Color(0xFF1565C0).withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected 
                    ? const Color(0xFF1565C0).withOpacity(0.05)
                    : Colors.white,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, 
                    vertical: 8,
                  ),
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (checked) => _toggleSheet(sheetName, checked ?? false),
                    activeColor: const Color(0xFF1565C0),
                  ),
                  title: Text(
                    sheetName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, 
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getEntityColor(detectedEntity).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              detectedEntity.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getEntityColor(detectedEntity),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$rowCount rows',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.preview),
                    onPressed: () => _previewSheet(sheetName),
                    tooltip: 'Preview data',
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    if (previewData == null || previewColumns == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.preview,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Preview: $previewSheet',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'First 5 rows of data from the selected sheet',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  columns: previewColumns!.map((column) => DataColumn(
                    label: Text(
                      column,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )).toList(),
                  rows: previewData!.take(5).map((row) => DataRow(
                    cells: row.map((cell) => DataCell(
                      Text(
                        cell?.toString() ?? '',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOptionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Configure how the data should be imported',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              title: const Text(
                'Clear existing data before import',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'Warning: This will delete all existing data in the selected entity types',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
              value: clearExistingData,
              onChanged: (value) {
                setState(() {
                  clearExistingData = value ?? false;
                });
              },
              activeColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButtonCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ready to Import',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${selectedSheets.length} sheet(s) selected for import',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isImporting ? null : _importData,
                icon: isImporting 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download, color: Colors.white),
                label: Text(
                  isImporting ? 'Importing...' : 'Start Import',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEntityColor(String entityType) {
    switch (entityType) {
      case 'vehicles':
        return Colors.blue;
      case 'drivers':
        return Colors.green;
      case 'trips':
        return Colors.orange;
      case 'fuel_entries':
        return Colors.red;
      case 'maintenance':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setState(() {
          selectedFile = file;
          fileName = result.files.first.name;
          analysisResult = null;
          analysisError = null;
          selectedSheets.clear();
          sheetEntityMappings.clear();
        });
        
        await _analyzeFile(file);
      }
    } catch (e) {
      setState(() {
        analysisError = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _analyzeFile(File file) async {
    setState(() {
      isFileUploading = true;
      analysisError = null;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          analysisResult = jsonData;
          isFileUploading = false;
        });
      } else {
        setState(() {
          analysisError = jsonData['detail'] ?? 'Failed to analyze file';
          isFileUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        analysisError = 'Network error: $e';
        isFileUploading = false;
      });
    }
  }

  void _clearFile() {
    setState(() {
      selectedFile = null;
      fileName = null;
      analysisResult = null;
      analysisError = null;
      selectedSheets.clear();
      sheetEntityMappings.clear();
      previewData = null;
      previewColumns = null;
      previewSheet = null;
    });
  }

  void _toggleSheet(String sheetName, bool selected) {
    setState(() {
      if (selected) {
        selectedSheets.add(sheetName);
        print('🔍 DEBUG: Added sheet "$sheetName". Selected sheets: $selectedSheets');
      } else {
        selectedSheets.remove(sheetName);
        print('🔍 DEBUG: Removed sheet "$sheetName". Selected sheets: $selectedSheets');
      }
    });
  }

  void _previewSheet(String sheetName) {
    if (analysisResult != null && analysisResult!['sheets_info'] != null) {
      final sheetsInfo = analysisResult!['sheets_info'] as Map<String, dynamic>;
      final sheetInfo = sheetsInfo[sheetName] as Map<String, dynamic>;
      
      setState(() {
        previewSheet = sheetName;
        previewColumns = (sheetInfo['columns'] as List).cast<String>();
        previewData = (sheetInfo['preview'] as List).cast<List<dynamic>>();
      });
    }
  }

  Future<void> _importData() async {
    if (selectedFile == null || selectedSheets.isEmpty) return;

    setState(() {
      isImporting = true;
    });

    // Debug: Print what sheets are selected
    print('🔍 DEBUG: Selected sheets: $selectedSheets');
    print('🔍 DEBUG: Selected sheets count: ${selectedSheets.length}');
    print('🔍 DEBUG: Joined sheets: ${selectedSheets.join(',')}');

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/import'));
      request.files.add(await http.MultipartFile.fromPath('file', selectedFile!.path));
      
      // Add form fields
      request.fields['selected_sheets'] = selectedSheets.join(',');
      request.fields['clear_existing'] = clearExistingData.toString();
      
      // Debug: Print form fields
      print('🔍 DEBUG: Form fields: ${request.fields}');

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200 && jsonData['success']) {
        _showSuccessDialog(jsonData);
      } else {
        _showErrorDialog(jsonData['message'] ?? 'Import failed');
      }
    } catch (e) {
      _showErrorDialog('Network error: $e');
    } finally {
      setState(() {
        isImporting = false;
      });
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Import Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result['message'] ?? 'Import completed successfully'),
            const SizedBox(height: 16),
            if (result['summary'] != null) ...[
              const Text(
                'Import Summary:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(result['summary'] as Map<String, dynamic>).entries.map(
                (entry) => Text('• ${entry.key}: ${entry.value['records']} records'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to main screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Import Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}