import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MSQScreen extends StatefulWidget {
  const MSQScreen({super.key});

  @override
  State<MSQScreen> createState() => _MSQScreenState();
}

class _MSQScreenState extends State<MSQScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  int _currentStep = 0;
  final Map<String, List<String>> _multiAnswers = {};
  late final PageController _pageController;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What type of food do you prefer?',
      'key': 'favCuisine',
      'options': ['Gujarati', 'Chinese', 'Italian', 'Punjabi', 'Rajasthani', 'South Indian', 'Bengali'],
      'image': 'assets/msq1.png',
      'imageWidth': 350.0,
      'imageHeight': 350.0,
      'spacingAboveImage' : 50.0,
      'spacingBelowImage': 65.0,
      'spacingBelowQuestion': 30.0,
      'alignment': TextAlign.left,
    },
    {
      'question': 'What\'s your favorite time to eat out?',
      'key': 'favTime',
      'options': ['Breakfast', 'Lunch', 'Evening Snacks', 'Dinner', 'Late Night'],
      'image': 'assets/msq2.png',
      'imageWidth': 350.0,
      'imageHeight': 350.0,
      'spacingAboveImage' : 50.0,
      'spacingBelowImage': 50.0,
      'spacingBelowQuestion': 30.0,
      'alignment': TextAlign.left,
    },
    {
      'question': 'What\'s your favorite city to enjoy food in?',
      'key': 'favoriteCity',
      'options': ['Ahmedabad', 'Mumbai', 'Kolkata', 'Delhi', 'Hyderabad', 'Bangalore', 'Chennai', 'Amritsar', 'Jaipur'],
      'image': 'assets/msq3.png',
      'imageWidth': 350.0,
      'imageHeight': 350.0,
      'spacingAboveImage' : 20.0,
      'spacingBelowImage': 40.0,
      'spacingBelowQuestion': 30.0,
      'alignment': TextAlign.left,
    },
    {
      'question': 'What\'s your favorite snack?',
      'key': 'favSnack',
      'options': ['Sandwich', 'Pizza', 'Samosa', 'Fries', 'Vada Pav', 'Noodles', 'Burger'],
      'image': 'assets/msq4.png',
      'imageWidth': 350.0,
      'imageHeight': 350.0,
      'spacingAboveImage' : 50.0,
      'spacingBelowImage': 50.0,
      'spacingBelowQuestion': 30.0,
      'alignment': TextAlign.left,
    },
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkIfShouldSkipMSQ();
  }

  Future<void> _checkIfShouldSkipMSQ() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    final emailKey = sanitizeEmail(user.email!);

    // Use UID or sanitized email based on your structure
    final snapshot = await _db.child('Users/$emailKey/firstTime').get();
    final alreadyAttempted = snapshot.exists && snapshot.value == false;

    if (alreadyAttempted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }



  void _toggleOption(String value) {
    final key = _questions[_currentStep]['key'];
    final selectedList = _multiAnswers[key] ?? [];

    setState(() {
      if (selectedList.contains(value)) {
        selectedList.remove(value);
      } else {
        selectedList.add(value);
      }
      _multiAnswers[key] = selectedList;
    });
  }

  String sanitizeEmail(String email) {
    return email.replaceAll('.', ',');
  }

  Future<void> _submitAnswers() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final emailKey = sanitizeEmail(user.email!);

    setState(() => _isLoading = true);

    await _db.child('Users/$emailKey/preferences').set(_multiAnswers);
    await _db.child('Users/$emailKey/firstTime').set(false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
    setState(() => _isLoading = false);
  }


  Widget _buildOptionBox(String text, List<String>? selected, void Function() onTap) {
    final isSelected = selected?.contains(text) ?? false;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade100 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.deepPurple : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_questions.length, (index) {
        final isActive = index == _currentStep;
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.deepPurple : Colors.grey.shade300,
            border: Border.all(color: Colors.deepPurple, width: 1),
          ),
        );
      }),
    );
  }

  Widget _buildQuestionPage(Map<String, dynamic> qData) {
    final selected = _multiAnswers[qData['key']];
    final double spacingAboveImage = qData['spacingAboveImage'] ?? 0.0;
    final double spacingBelowImage = qData['spacingBelowImage'] ?? 30.0;
    final double spacingBelowQuestion = qData['spacingBelowQuestion'] ?? 20.0;
    final TextAlign questionAlign = qData['alignment'] ?? TextAlign.center;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: spacingAboveImage),
        Center(
          child: Image.asset(
            qData['image'],
            width: qData['imageWidth'],
            height: qData['imageHeight'],
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: spacingBelowImage),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
                    qData['question'],
                    textAlign: questionAlign,
                    style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                      color: Colors.black,
    ),
    ),

    ),
        SizedBox(height: spacingBelowQuestion),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(
            qData['options'].length,
                (index) => _buildOptionBox(
              qData['options'][index],
              selected,
                  () => _toggleOption(qData['options'][index]),
            ),
          ),
        ),
      ],
    );
  }




  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentStep];
    final selected = _multiAnswers[currentQ['key']];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _questions.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildQuestionPage(_questions[index]),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildProgressDots(),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back or Skip Button
                    _currentStep == 0
                        ? OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepPurple),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Text("Skip"),
                      ),
                    )
                        : OutlinedButton(
                      onPressed: () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep--);
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepPurple),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Text("Back"),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: (selected == null || selected.isEmpty)
                          ? null
                          : () {
                        if (_currentStep < _questions.length - 1) {
                          setState(() => _currentStep++);
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _submitAnswers();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Text(_currentStep < _questions.length - 1 ? "Next" : "Let’s Go!",
                        style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
