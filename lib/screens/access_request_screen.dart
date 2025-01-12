import 'package:flutter/material.dart';
import '../models/access_request_model.dart';

class AccessRequestScreen extends StatefulWidget {
  @override
  _AccessRequestScreenState createState() => _AccessRequestScreenState();
}

class _AccessRequestScreenState extends State<AccessRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _userNameController;
  late TextEditingController _fileNameController;
  bool _isLoading = false;
  String? _selectedFile;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
    _fileNameController = TextEditingController();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // Implement file picking logic here
    setState(() {
      _selectedFile = 'Selected_File.pdf'; // Placeholder
      _fileNameController.text = _selectedFile!;
    });
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Create new access request
        final newRequest = AccessRequestModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userName: _userNameController.text,
          fileName: _fileNameController.text,
          status: 'Pending',
          requestDate: DateTime.now(),
        );

        // TODO: Implement the actual submission logic
        await Future.delayed(Duration(seconds: 2)); // Simulate network request

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Access request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Access Request'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 24),
                        TextFormField(
                          controller: _userNameController,
                          decoration: InputDecoration(
                            labelText: 'User Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter user name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _fileNameController,
                          decoration: InputDecoration(
                            labelText: 'File Name',
                            prefixIcon: Icon(Icons.file_present),
                            border: OutlineInputBorder(),
                            filled: true,
                            suffixIcon: IconButton(
                              icon: Icon(Icons.attach_file),
                              onPressed: _pickFile,
                            ),
                          ),
                          readOnly: true,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please select a file';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Terms',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '• This request will be reviewed by the data owner\n'
                          '• Access is temporary and can be revoked\n'
                          '• You agree to handle the data securely\n'
                          '• Misuse of data may result in penalties',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Submit Request',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}