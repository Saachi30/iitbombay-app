import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import '../models/file_model.dart';
import '../widgets/file_card.dart';
import '../widgets/stats_card.dart';
import '../services/ipfs_service.dart';
import 'file_upload_screen.dart';
import 'chatbot_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  @override
  _UserDashboardScreenState createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final IPFSService _ipfsService = IPFSService();
  final FlutterTts _flutterTts = FlutterTts();
  List<FileModel> files = [];
  bool isLoading = true;
  bool isBlindModeEnabled = false;
  int nftCount = 0;
  int ipfsCount = 0;
  
  // Mock user address
  final String mockAddress = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e";

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadMockData();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _toggleBlindMode() async {
    setState(() {
      isBlindModeEnabled = !isBlindModeEnabled;
    });

    if (!isBlindModeEnabled) {
      await _flutterTts.stop();
      return;
    }

    // Speak dashboard summary when blind mode is enabled
    final summary = '''
    Welcome to your dashboard. 
    You have ${files.length} files in total.
    ${nftCount} NFT assets and ${ipfsCount} IPFS files.
    Your wallet address is ${mockAddress.substring(0, 6)}...${mockAddress.substring(mockAddress.length - 4)}
    Double tap on any file to hear its details.
    ''';

    await _flutterTts.speak(summary);
  }

  Future<void> _speakFileDetails(FileModel file) async {
    if (!isBlindModeEnabled) return;

    final details = '''
    File name: ${file.fileName}
    Description: ${file.description}
    Type: ${file.isNFT ? 'NFT Asset' : 'IPFS File'}
    Upload date: ${file.uploadDate.toString().split(' ')[0]}
    IPFS Hash: ${file.ipfsHash.substring(0, 6)}...${file.ipfsHash.substring(file.ipfsHash.length - 4)}
    ''';

    await _flutterTts.speak(details);
  }

  void _loadMockData() {
    // Simulate loading delay
    Future.delayed(Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        files = [
          FileModel(
            ipfsHash: "QmX4zdJ6QbWXuJ9rF12car4rWe9YbZ8bKjF9qj9RgJfL9q",
            fileName: "Research Paper.pdf",
            description: "Latest research findings",
            ownerAddress: mockAddress,
            encryptedKey: "encrypted_key_1",
            iv: "iv_1",
            uploadDate: DateTime.now().subtract(Duration(days: 2)),
            isNFT: true,
          ),
          FileModel(
            ipfsHash: "QmYbZ8bKjF9qj9RgJfL9qX4zdJ6QbWXuJ9rF12car4rWe",
            fileName: "Dataset.csv",
            description: "Experimental data",
            ownerAddress: mockAddress,
            encryptedKey: "encrypted_key_2",
            iv: "iv_2",
            uploadDate: DateTime.now().subtract(Duration(days: 5)),
            isNFT: false,
          ),
          FileModel(
            ipfsHash: "QmJ9rF12car4rWe9YbZ8bKjF9qj9RgJfL9qX4zdJ6QbWXu",
            fileName: "Project Report.docx",
            description: "Final project documentation",
            ownerAddress: mockAddress,
            encryptedKey: "encrypted_key_3",
            iv: "iv_3",
            uploadDate: DateTime.now().subtract(Duration(days: 1)),
            isNFT: true,
          ),
        ];

        nftCount = files.where((f) => f.isNFT).length;
        ipfsCount = files.where((f) => !f.isNFT).length;
        isLoading = false;
      });
    });
  }

  Future<void> _downloadFile(FileModel file) async {
    try {
      final savePath = '/path/to/downloads/${file.fileName}'; // Implement proper path
      await _ipfsService.downloadAndDecryptFile(
        file.ipfsHash,
        file.encryptedKey,
        file.iv,
        savePath,
      );
      if (!mounted) return;
      _showSuccess('File downloaded successfully');
      
      if (isBlindModeEnabled) {
        await _flutterTts.speak('File downloaded successfully');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error downloading file: $e');
      
      if (isBlindModeEnabled) {
        await _flutterTts.speak('Error downloading file');
      }
    }
  }

  void _copyAddressToClipboard() {
    Clipboard.setData(ClipboardData(text: mockAddress));
    _showSuccess('Address copied to clipboard');
    
    if (isBlindModeEnabled) {
      _flutterTts.speak('Wallet address copied to clipboard');
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Text(
          'My Dashboard', 
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBlindModeEnabled ? Icons.hearing : Icons.hearing_disabled,
              color: isBlindModeEnabled ? Colors.green : null,
            ),
            onPressed: _toggleBlindMode,
            tooltip: 'Toggle Blind Mode',
          ),
        ],
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              setState(() => isLoading = true);
              _loadMockData();
            },
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Address',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, 
                                   color: Theme.of(context).primaryColor),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  mockAddress,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy),
                                onPressed: _copyAddressToClipboard,
                                tooltip: 'Copy address',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Files',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (isBlindModeEnabled)
                        Text(
                          'Double tap for details',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: files.isEmpty
                      ? Center(
                          child: Text('No files found',
                            style: Theme.of(context).textTheme.bodyLarge),
                        )
                      : ListView.builder(
                          itemCount: files.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onDoubleTap: () => _speakFileDetails(files[index]),
                              child: FileCard(
                                file: files[index],
                                onDownload: () => _downloadFile(files[index]),
                              ),
                            );
                          },
                        ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'NFT Assets',
                          value: nftCount.toString(),
                          color: Colors.indigo,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: StatsCard(
                          title: 'IPFS Files',
                          value: ipfsCount.toString(),
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 80,
            right: 0,
            child: FloatingActionButton(
              heroTag: 'chat',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
              child: Icon(Icons.chat),
              tooltip: 'Chat with AI Assistant',
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton(
              heroTag: 'upload',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FileUploadScreen()),
                );
                if (result == true) {
                  _loadMockData();
                }
              },
              child: Icon(Icons.add),
              tooltip: 'Upload New File',
            ),
          ),
        ],
      ),
    );
  }
}