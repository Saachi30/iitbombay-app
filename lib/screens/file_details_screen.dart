import 'package:flutter/material.dart';
import '../models/file_model.dart';

class FileDetailsScreen extends StatelessWidget {
  final FileModel file;

  const FileDetailsScreen({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text('Type: ${file.isNFT?"NFT":"IPFS"}'),
                    Text('Upload Date: ${file.uploadDate}'),
                    // Text('Description: ${file.status}'),
                    // Text('Access Count: ${file.accessCount}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Access History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Replace with actual access history
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Access by Company XYZ'),
                    subtitle: Text('2024-01-10 14:30'),
                    leading: Icon(Icons.history),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
