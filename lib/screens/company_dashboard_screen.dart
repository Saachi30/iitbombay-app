import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import '../models/access_request_model.dart';
import '../widgets/request_card.dart';
import '../providers/web3_provider.dart';
import 'chatbot_screen.dart';
import 'access_request_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  @override
  _CompanyDashboardScreenState createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final String pinataApiKey = '815cb6c5b936de120de6';
  final String pinataSecretKey = '71b9f2139171591882a5b4cbb9d5ab4846b9b845911a5960111a2cd8ad4a9984';
  final String contractAddress = '0x376Fb6EB51F0860d699EC73e49CB79AF7F9fE0f8';

  List<AccessRequestModel> requests = [];
  bool isLoading = true;
  Map<String, dynamic>? companyInfo;
  int activeDataAccess = 24;
  double approvalRate = 85;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    try {
      final web3Provider = Provider.of<Web3Provider>(context, listen: false);
      // Load company info from blockchain
      // This is a placeholder
      setState(() {
        companyInfo = {
          'name': 'Test Company',
          'isAuthorized': true,
        };
        
        requests = [
          AccessRequestModel(
            id: '1',
            userName: 'John Doe',
            fileName: 'Personal Data.pdf',
            status: 'Pending',
            requestDate: DateTime.now(),
          ),
          AccessRequestModel(
            id: '2',
            userName: 'Jane Smith',
            fileName: 'Medical Records.pdf',
            status: 'Approved',
            requestDate: DateTime.now().subtract(Duration(days: 1)),
          ),
        ];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading company data: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildAnalyticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      activeDataAccess.toString(),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text('Active Data Access'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$approvalRate%',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                    Text('Approval Rate'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorizationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  companyInfo?['isAuthorized'] == true 
                    ? Icons.verified 
                    : Icons.warning,
                  color: companyInfo?['isAuthorized'] == true 
                    ? Colors.green 
                    : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  companyInfo?['isAuthorized'] == true 
                    ? 'Authorized Company' 
                    : 'Not Authorized',
                  style: TextStyle(
                    color: companyInfo?['isAuthorized'] == true 
                      ? Colors.green 
                      : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (companyInfo == null || companyInfo?['isAuthorized'] != true) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Company Not Authorized',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 8),
                Text(
                  'Please contact administrator for authorization.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Company Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCompanyData,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAuthorizationCard(),
              SizedBox(height: 16),
              _buildAnalyticsCard(),
              SizedBox(height: 24),
              Text(
                'Data Access Requests',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return RequestCard(request: requests[index]);
                  },
                ),
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
        
        onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AccessRequestScreen()),
    );
  },
        child: Icon(Icons.upload_file),
        tooltip: 'Upload Company Data',
      ),
    ),
        ],
      )
    );
  }
}