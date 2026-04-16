import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';

class SpotsOnboardingScreen extends StatelessWidget {
  const SpotsOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
          child: Column(
            children: [
              const Text(
                'Spots',
                style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              // --- ADDED IMAGE SECTION ---
              const SizedBox(height: 20), // Space between Title and Image
              Image.asset(
                'assets/photos/spots_logo.png', // Replace with your actual filename
                height:  300,                  // Adjust height as needed
                fit: BoxFit.contain,
              ),
              // ---------------------------
              const SizedBox(height: 30),
              const Text(
                'DISCOVER HIDDEN GEMS.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),

              // 4. Sub-description (New Text)
              const Text(
                'Discover your perfect place. Find unique locations for every moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, 
                  color: Colors.black54, // Slightly grey for visual hierarchy
                  height: 1.5,           // Better line spacing for readability
                ),
              ),
              const SizedBox(height: 50),
              // Solid Black Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const OnboardingStepTwo()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'GET STARTED',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingStepTwo extends StatelessWidget {
  const OnboardingStepTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
          child: Column(
            children: [
              const Text(
                'YOUR JOURNEY AWAITS.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              // --- ADDED IMAGE SECTION ---
              const SizedBox(height: 40), // Space between Title and Image
              Image.asset(
                'assets/photos/spots_logo_2.png', // Replace with your actual filename
                height:  300,                  // Adjust height as needed
                fit: BoxFit.contain,
              ),
              // ---------------------------
              const Spacer(),
              const Text(
                'READY TO FIND YOUR SPOT?',
                style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
              ),
              const SizedBox(height: 30),
              // Sign Up Outlined Button
              _buildOutlinedButton(
                label: 'SIGN UP', 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateUserScreen()),
                  );
                },
              ),
              const SizedBox(height: 15),
              // Sign In With Google Outlined Button
              _buildOutlinedButton(label: 'SIGN IN WITH GOOGLE', onTap: () {}),
              const SizedBox(height: 30),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Log in',
                      style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}