import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/web3_service.dart';
import '../providers/web3_provider.dart';
import 'company_dashboard_screen.dart';
import 'user_dashboard_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  String _accountType = 'user';
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _privateKeyController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _showPrivateKey = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _gstController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final web3Provider = Provider.of<Web3Provider>(context, listen: false);

        if (_isSignUp) {
          if (_accountType == 'company') {
            await authService.signUpCompany(
              _emailController.text,
              _passwordController.text,
              _companyNameController.text,
              _gstController.text,
            );
          } else {
            await authService.signUpUser(
              _emailController.text,
              _passwordController.text,
              _nameController.text,
              _phoneController.text,
            );
          }
          _navigateToDashboard();
        } else {
          // Handle login
          final result = await authService.signIn(
            _emailController.text,
            _passwordController.text,
          );
          
          // Navigate based on user type
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => result['isCompany'] 
                  ? CompanyDashboardScreen()
                  : UserDashboardScreen(),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => _accountType == 'company'
            ? CompanyDashboardScreen()
            : UserDashboardScreen(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isPrivateKey = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPrivateKey ? !_showPrivateKey : obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPrivateKey
            ? IconButton(
                icon: Icon(
                  _showPrivateKey ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _showPrivateKey = !_showPrivateKey;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildAccountTypeButton(String label, String type) {
    final isSelected = _accountType == type;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: () => setState(() => _accountType = type),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: isSelected ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 64,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(height: 24),
                          Text(
                            _isSignUp ? 'Create Account' : 'Welcome Back',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          SizedBox(height: 32),
                          if (_isSignUp) ...[
                            Row(
                              children: [
                                Expanded(
                                    child: _buildAccountTypeButton(
                                        'User', 'user')),
                                SizedBox(width: 16),
                                Expanded(
                                    child: _buildAccountTypeButton(
                                        'Company', 'company')),
                              ],
                            ),
                            SizedBox(height: 24),
                          ],
                          if (_isSignUp && _accountType == 'company') ...[
                            _buildTextField(
                              controller: _companyNameController,
                              label: 'Company Name',
                              icon: Icons.business,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter company name'
                                  : null,
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _gstController,
                              label: 'GST Number',
                              icon: Icons.receipt_long,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter GST number'
                                  : null,
                            ),
                          ],
                          if (_isSignUp && _accountType == 'user') ...[
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter your name'
                                  : null,
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter your phone number'
                                  : null,
                            ),
                          ],
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter email' : null,
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock,
                            obscureText: true,
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter password' : null,
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _privateKeyController,
                            label: 'Private Key',
                            icon: Icons.key,
                            isPrivateKey: true,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter private key'
                                : null,
                          ),
                          SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    )
                                  : Text(
                                      _isSignUp ? 'Create Account' : 'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors
                                            .white, // Set the text color to white
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                setState(() => _isSignUp = !_isSignUp),
                            child: Text(
                              _isSignUp
                                  ? 'Already have an account? Login'
                                  : "Don't have an account? Sign Up",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
