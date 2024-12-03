import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'basic_page.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final AuthService _authService = AuthService();

  String? errorMessage;
  bool isSignIn = true;
  bool showPassword = false;

  // Regular expression to validate email
  bool isValidEmail(String email) {
    String emailPattern =
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regExp = RegExp(emailPattern);
    return regExp.hasMatch(email);
  }

  // Authentication function
  Future<void> authenticate() async {
    setState(() {
      errorMessage = null;
    });

    try {
      String email = emailController.text;
      String password = passwordController.text;

      if (email.isEmpty || password.isEmpty || (!isSignIn && nameController.text.isEmpty)) {
        setErrorMessage('Please fill in all fields.');
        return;
      }

      // Email validation
      if (!isValidEmail(email)) {
        setErrorMessage('Please enter a valid email address.');
        return;
      }

      if (isSignIn) {
        // Sign in to the system
        Map<String, dynamic>? userData = await _authService.signIn(email, password);
        if (userData != null) {
          // Navigate to the main page with user data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BasicPage(
                userName: userData['userName'],
                orderCount: userData['orderCount'],
              ),
            ),
          );
        } else {
          setErrorMessage('Incorrect email or password. Please try again.');
        }
      } else {
        // Registration
        await _authService.signUp(email, password, nameController.text);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BasicPage(
              userName: nameController.text,
              orderCount: 0,
            ),
          ),
        );
      }
    } catch (e) {
      setErrorMessage('An error occurred. Please check your details and try again.');
    }
  }

  // Set error message and start a timer to hide it after 5 seconds
  void setErrorMessage(String message) {
    setState(() {
      errorMessage = message;
    });

    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          errorMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFC466B), // Lighter Pink
                  Color(0xFF3F5EFB), // Blue for contrast
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      isSignIn ? 'Sign In' : 'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 40),
                    if (!isSignIn)
                      _buildTextField(
                        controller: nameController,
                        hintText: 'Enter your name',
                        icon: Icons.person,
                      ),
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Enter your email',
                      icon: Icons.email,
                    ),
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Enter your password',
                      icon: Icons.lock,
                      obscureText: !showPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: authenticate,
                      child: Text(
                        isSignIn ? 'Sign In' : 'Sign Up',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          Color(0xFFFF6F61), // Soft Coral color for the button
                        ),
                        padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isSignIn = !isSignIn;
                        });
                      },
                      child: Text(
                        isSignIn
                            ? 'Don\'t have an account? Sign Up'
                            : 'Already have an account? Sign In',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (errorMessage != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16.0),
                margin: EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(30),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(30),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
