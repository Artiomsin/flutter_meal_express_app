import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/order_service.dart';
import 'myhome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String userName = 'Loading...';
  int orderCount = 0;
  int balance = 0;
  final OrderService _orderService = OrderService();
  late AnimationController _animationController;

  bool _isCardHovered = false; // animation cart
  bool _isButtonPressed = false; // animation button

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _loadUserProfile() async {
    final profileData = await _orderService.getUserProfile();
    if (profileData != null) {
      setState(() {
        userName = profileData['userName'];
        orderCount = profileData['orderCount'];
        balance = profileData['balance'];
      });
    } else {
      setState(() {
        userName = 'Error loading profile';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade300, Colors.purple.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
               SizedBox(height: 160),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, math.sin(_animationController.value * 2 * math.pi) * 10),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 30),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Total Orders: $orderCount',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCardHovered = !_isCardHovered;
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isCardHovered
                          ? [Colors.orange.shade300, Colors.red.shade400]
                          : [Colors.pink.shade400, Colors.purple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 60,
                        color: Colors.white,
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balance',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '$balance'+'\$',
                            style: TextStyle(
                              fontSize: 26,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              AnimatedScale(
                scale: _isButtonPressed ? 0.95 : 1.0,
                duration: Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isButtonPressed = true;
                    });
                    Future.delayed(Duration(milliseconds: 200), () {
                      setState(() {
                        _isButtonPressed = false;
                      });
                      _showAddBalanceDialog();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Top Up Balance',
                    style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 18, 17, 17)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
        },
        backgroundColor: Colors.purple,
        child: Icon(Icons.logout),
      ),
    );
  }

  void _showAddBalanceDialog() {
    TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Enter Amount to Top Up',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Amount in dollars',
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.pink),
              ),
            ),
            cursorColor: Colors.pink,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.pink),
              ),
            ),
            TextButton(
              onPressed: () async {
                int amount = int.tryParse(_controller.text) ?? 0;
                if (amount > 0) {
                  final newBalance = balance + amount;
                  final success = await _orderService.updateUserBalance(newBalance);
                  if (success) {
                    setState(() {
                      balance = newBalance;
                    });
                  } else {
                    print('Failed to update balance on server');
                  }
                }
                Navigator.pop(context);
              },
              child: Text(
                'Top Up',
                style: TextStyle(color: Colors.pink),
              ),
            ),
          ],
        );
      },
    );
  }
}
