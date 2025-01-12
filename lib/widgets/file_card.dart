import 'package:flutter/material.dart';
import '../models/file_model.dart';
import 'package:iitbombapp/screens/file_details_screen.dart';

class FileCard extends StatelessWidget {
  final FileModel file;
  final VoidCallback? onDownload;
  
  const FileCard({
    required this.file,
    this.onDownload,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'private':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FileDetailsScreen(file: file),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  file.isNFT ? Icons.token : Icons.folder,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            file.isNFT ? "NFT":"IPFS",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(width: 8),
                        Text(
                          file.uploadDate.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Download button
              IconButton(
                icon: Icon(
                  Icons.download,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: onDownload,
                tooltip: 'Download file',
              ),
            ],
          ),
        ),
      ),
    );
  }
}