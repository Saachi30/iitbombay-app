import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import '../models/file_model.dart';
import '../widgets/file_card.dart';
import '../widgets/stats_card.dart';
import '../services/ipfs_service.dart';
import 'file_upload_screen.dart';
import 'chatbot_screen.dart';
import '../models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDashboardScreen extends StatefulWidget {
  @override
  _UserDashboardScreenState createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
 final IPFSService _ipfsService = IPFSService();
  final FlutterTts _flutterTts = FlutterTts();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  
  List<FileModel> files = [];
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  bool isBlindModeEnabled = false;
  bool showNotifications = false;
  int nftCount = 0;
  int ipfsCount = 0;
  int unreadCount = 0;
  String userName = '';
  Map<String, String> senderNames = {};
  
  // Mock user address
  final String mockAddress = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e";

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadUserData();
    _setupNotificationListener();
    _loadMockData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user's name from Firebase
        final userDoc = await _firestore
            .collection('Users')
            .where('uid', isEqualTo: user.uid)
            .get();
        
        if (userDoc.docs.isNotEmpty) {
          setState(() {
            userName = userDoc.docs.first.data()['fullName'];
          });
          // Once we have the username, start listening to notifications
          _setupNotificationListener();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _setupNotificationListener() {
    _firestore
        .collection('requests')
        .where('sentTo', isEqualTo: userName)
        .snapshots()
        .listen((snapshot) {
      List<NotificationModel> notifs = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        notifs.add(NotificationModel(
          id: doc.id,
          sentBy: data['sentBy'],
          fileName: data['fileName'],
          status: data['status'] ?? 'pending',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          read: data['read'] ?? false,
          senderName: data['senderName'] ?? data['sentBy'],
        ));
      }

      // Sort notifications by date (newest first)
      notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        notifications = notifs;
        unreadCount = notifs.where((n) => !n.read).length;
      });
    });
  }

  Future<void> _handleAcceptRequest(NotificationModel notification) async {
    try {
      await _firestore.collection('requests').doc(notification.id).update({
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
        'read': true
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request accepted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept request')),
      );
    }
  }

  Future<void> _handleRejectRequest(NotificationModel notification) async {
    try {
      await _firestore.collection('requests').doc(notification.id).update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
        'read': true
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject request')),
      );
    }
  }

  Future<void> _markNotificationsAsRead() async {
    final unreadNotifications = notifications.where((n) => !n.read);
    for (var notification in unreadNotifications) {
      await _firestore
          .collection('requests')
          .doc(notification.id)
          .update({
            'read': true,
            'readAt': FieldValue.serverTimestamp()
          });
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(notification.senderName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requested access to: ${notification.fileName}'),
            Text(
              _formatTimestamp(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: notification.status == 'pending'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => _handleAcceptRequest(notification),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => _handleRejectRequest(notification),
                  ),
                ],
              )
            : Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: notification.status == 'accepted'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notification.status.toUpperCase(),
                  style: TextStyle(
                    color: notification.status == 'accepted'
                        ? Colors.green
                        : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        tileColor: !notification.read ? Colors.blue.withOpacity(0.1) : null,
      ),
    );
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
      title: Text('My Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                setState(() {
                  showNotifications = !showNotifications;
                  if (showNotifications) {
                    _markNotificationsAsRead();
                  }
                });
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
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
    body: Stack(
      children: [
        // Main Dashboard Content
        isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() => isLoading = true);
                  _loadMockData();
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wallet Card
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

                        // Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: StatsCard(
                                title: 'NFT Assets',
                                value: nftCount.toString(),
                                color: Colors.indigo,
                                // icon: Icons.token,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: StatsCard(
                                title: 'IPFS Files',
                                value: ipfsCount.toString(),
                                color: Colors.blue,
                                // icon: Icons.folder,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Files Section
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

                        // Files List
                        files.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No files found',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      icon: Icon(Icons.add),
                                      label: Text('Upload your first file'),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FileUploadScreen(),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadMockData();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: files.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding:
                                        EdgeInsets.only(bottom: index == files.length - 1 ? 80 : 16),
                                    child: GestureDetector(
                                      onDoubleTap: () =>
                                          _speakFileDetails(files[index]),
                                      child: FileCard(
                                        file: files[index],
                                        onDownload: () =>
                                            _downloadFile(files[index]),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ),

        // Notifications Overlay
        if (showNotifications)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                margin: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notifications,
                                  color: Theme.of(context).primaryColor),
                              SizedBox(width: 8),
                              Text(
                                'Access Requests',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                showNotifications = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: notifications.isEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 32, horizontal: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_none,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No notifications',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: notifications.length,
                              itemBuilder: (context, index) =>
                                  _buildNotificationCard(notifications[index]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(Icons.add),
            tooltip: 'Upload New File',
          ),
        ),
      ],
    ),
  );
}
}