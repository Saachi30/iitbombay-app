import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ipfs_service.dart';

class FileUploadScreen extends StatefulWidget {
  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  final IPFSService _ipfsService = IPFSService();
  final _formKey = GlobalKey<FormState>();
  
  File? _selectedFile;
  String _fileName = '';
  String _description = '';
  bool _isNFT = false;
  bool _isUploading = false;
  String? _fileType;
  String? _fileSize;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _fileType = result.files.single.extension;
          // Convert bytes to MB with 2 decimal places
          _fileSize = (result.files.single.size / (1024 * 1024)).toStringAsFixed(2) + ' MB';
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      final result = await _ipfsService.uploadFile(_selectedFile!);
      
      if (!mounted) return;

      if (_isNFT) {
        // Show NFT minting success dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Icon(Icons.celebration, color: Colors.amber, size: 50),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NFT Minted Successfully!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text('Your file has been uploaded to IPFS and minted as an NFT.'),
                SizedBox(height: 8),
                Text(
                  'IPFS Hash: ${result['ipfsHash']}',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      } else {
        _showSuccess('File uploaded successfully to IPFS!');
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError('Error uploading file: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload File'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // File Upload Area
                GestureDetector(
                  onTap: _isUploading ? null : _pickFile,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 2,
                        // style: BorderStyle.dashed,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedFile != null ? Icons.check_circle : Icons.cloud_upload,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 16),
                        if (_selectedFile != null) ...[
                          Text(
                            _fileName,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Type: ${_fileType?.toUpperCase() ?? "Unknown"} • Size: $_fileSize',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ] else
                          Text(
                            'Drag and drop or click to select file',
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                
                // File Name Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'File Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.insert_drive_file),
                  ),
                  initialValue: _fileName,
                  onChanged: (value) => _fileName = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a file name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                // Description Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  onChanged: (value) => _description = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                // NFT Switch
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: SwitchListTile(
                    title: Text('Mint as NFT'),
                    subtitle: Text('Create a unique token for your file'),
                    value: _isNFT,
                    onChanged: _isUploading ? null : (value) {
                      setState(() => _isNFT = value);
                    },
                    secondary: Icon(
                      Icons.token,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 32),
                
                // Upload Button
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadFile,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Uploading...'),
                          ],
                        )
                      : Text('Upload to IPFS'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}