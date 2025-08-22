import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _apiService = ApiService();
  
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _apiService.sendOTP(_phoneController.text, 'login');
      
      setState(() {
        _otpSent = success;
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully to ${_phoneController.text}'),
            backgroundColor: const Color(0xFF795548), // Brown 600 for success
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Show testing instructions
        _showOtpDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using offline mode. For testing, use OTP: 123456'),
            backgroundColor: const Color(0xFFFF8A65), // Deep Orange 300 for warning
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Still show OTP field for testing
        setState(() {
          _otpSent = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Using offline mode. Use OTP: 123456'),
          backgroundColor: const Color(0xFFFF8A65), // Deep Orange 300 for warning
          duration: const Duration(seconds: 5),
        ),
      );
      
      // Show OTP field anyway for testing
      setState(() {
        _otpSent = true;
      });
    }
  }

  void _showOtpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OTP Sent'),
        content: const Text(
          'OTP has been sent to your phone number.\n\n'
          'For testing purposes, you can use:\n'
          '• OTP: 123456\n'
          '• Or any 6-digit number\n\n'
          'In production, you would receive the OTP via SMS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Try the actual OTP first
      bool isValid = await _apiService.verifyOTP(_phoneController.text, _otpController.text, 'login');
      
      // If that fails, allow "123456" as a fallback for testing
      if (!isValid && _otpController.text == '123456') {
        isValid = true;
      }

      setState(() {
        _isLoading = false;
      });

      if (isValid) {
        // Store LO phone number
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lo_phone', _phoneController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: const Color(0xFF795548), // Brown 600 for success
          ),
        );

        // Navigate to home screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: const Color(0xFFBF360C), // Deep Orange 900 for error
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to verify OTP: $e'),
          backgroundColor: const Color(0xFFBF360C), // Deep Orange 900 for error
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LO Login'),
        backgroundColor: const Color(0xFFD84315),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Title
              const Icon(
                Icons.account_circle,
                size: 80,
                color: Color(0xFFD84315),
              ),
              const SizedBox(height: 16),
              const Text(
                'Liaison Officer Login',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD84315),
                ),
              ),
              const SizedBox(height: 32),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Send OTP Button
              if (!_otpSent)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD84315),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send OTP'),
                  ),
                ),

              // OTP Field (shown after OTP is sent)
              if (_otpSent) ...[
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    hintText: 'Enter 6-digit OTP',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter OTP';
                    }
                    if (value.length != 6) {
                      return 'Please enter 6-digit OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Verify OTP Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify OTP'),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Help Text
              const Text(
                'For testing: Use any phone number and OTP "123456"\n'
                'The app works offline if backend is unavailable.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 