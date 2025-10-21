import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromDocument(Map<String, dynamic> data, String id) {
    return QuizQuestion(
      id: id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedIndex;

  String _currentCategory = 'Budgeting';
  final List<String>  _categories = ['Budgeting', 'Saving', 'Investing'];

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _loadCategoryQuestions(_currentCategory);
  }

  Future<void> _loadCategoryQuestions(String category) async {
    //load questions category wise
    final snapshot = await FirebaseFirestore.instance
      .collection('quizzes')
      .where('category', isEqualTo: category)
      .get();


    final questions = snapshot.docs.map((doc) {
      return QuizQuestion.fromDocument(doc.data(), doc.id);
    }).toList();

    setState(() {
      _questions = questions;
      _currentIndex = 0;
      _score = 0;
      _answered = false;
      _selectedIndex = null;
    });
    _fadeController.forward(from: 0);
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (_questions[_currentIndex].correctIndex == index) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (!_answered) return;
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedIndex = null;
      });
      _fadeController.forward(from: 0);
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _answered = false;
        _selectedIndex = null;
      });
      _fadeController.forward(from: 0);
    }
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('scores')
        .add({
      'score': _score,
      'total': _questions.length,
      'timestamp': FieldValue.serverTimestamp(),
      'category': _currentCategory,
    });
  }

  void _showFinalResult() async {
    await _saveScore();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Completed'),
        content:
            Text('Your Score: $_score / ${_questions.length}\n\n${_scoreRemark()}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _score = 0;
                _currentIndex = 0;
                _answered = false;
                _selectedIndex = null;
              });
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  String _scoreRemark() {
    double percentage = (_score / _questions.length) * 100;
    if (percentage >= 90) {
      return "Excellent! You're a budgeting pro!";
    } else if (percentage >= 70) {
      return "Good job! Keep practicing.";
    } else if (percentage >= 50) {
      return "Fair. Review budgeting basics to improve.";
    } else {
      return "Needs improvement. Try again!";
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Widget to show question categories tabs
  Widget _buildCategoryTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _categories.map((cat) {
        bool isSelected = cat == _currentCategory;
        return GestureDetector(
          onTap: () {
            if (!isSelected) {
              setState(() {
                _currentCategory = cat;
              });
              _loadCategoryQuestions(cat);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.deepPurpleAccent
                  : Colors.deepPurpleAccent.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              cat,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.deepPurple,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Quiz statistics dashboard
  Widget _buildStatsDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics Dashboard'),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('scores')
            .orderBy('timestamp', descending: true)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final scores = snapshot.data!.docs;
          if (scores.isEmpty) {
            return const Center(
              child: Text('No quiz data available yet.'),
            );
          }
          
          final totalQuizzes = scores.length;
          final totalScore = scores.fold<int>(
            0,
            (sum, doc) => sum + (doc['score'] as int),
          );
          final highestScore = scores.fold<int>(
            0,
            (max, doc) => (doc['score'] as int) > max ? doc['score'] as int : max,
          );
          final averageScore = (totalScore / totalQuizzes).toStringAsFixed(2);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Quizzes Taken: $totalQuizzes', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Average Score: $averageScore', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Highest Score: $highestScore', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                const Text('Recent Attempts:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: scores.length,
                    itemBuilder: (context, index) {
                      final doc = scores[index];
                      final scoreValue = doc['score'];
                      final totalValue = doc['total'];
                      final data = doc.data() as Map<String, dynamic>;
                      final category = data['category'] ?? 'Unknown';

                      final timestamp = (doc['timestamp'] as Timestamp?)?.toDate();
                      final formattedDate = timestamp != null
                          ? '${timestamp.day}/${timestamp.month}/${timestamp.year}'
                          : 'Date unknown';

                      return ListTile(
                        title: Text('Category: $category'),
                        subtitle: Text('Score: $scoreValue/$totalValue'),
                        trailing: Text(formattedDate),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }, 
      ),
    );
  }


  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => _buildStatsDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE3D1FF), Color(0xFFCAF0F8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Budgeting Quiz',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_outlined),
                onPressed: _openStats,
                tooltip: 'Statistics',
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryTabs(),
            const SizedBox(height: 6),
            Text(
              'Question ${_currentIndex + 1} of ${_questions.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    question.question,
                    style:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, idx) {
                  final option = question.options[idx];
                  final isSelected = _selectedIndex == idx;
                  final isCorrect = question.correctIndex == idx;

                  Color bgColor = Colors.white;
                 if (_answered) {
                  if (isSelected && isCorrect) {
                    bgColor = const Color.fromRGBO(0, 255, 0, 0.6); // greenAccent with 0.6 opacity
                  } else if (isSelected && !isCorrect) {
                    bgColor = const Color.fromRGBO(255, 82, 82, 0.6); // redAccent with 0.6 opacity
                  } else if (isCorrect) {
                    bgColor = const Color.fromRGBO(0, 255, 0, 0.3); // greenAccent with 0.3 opacity
                  }
                } else if (isSelected) {
                  bgColor = const Color.fromRGBO(124, 77, 255, 0.3); // deepPurpleAccent with 0.3 opacity
                }


                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bgColor,
                        foregroundColor: isSelected ? Colors.white : Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: isSelected ? 8 : 3,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      ),
                      onPressed: _answered ? null : () => _selectOption(idx),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          if (_answered)
                            Icon(
                              isSelected
                                  ? (isCorrect ? Icons.check_circle : Icons.cancel)
                                  : (isCorrect ? Icons.check_circle : null),
                              color: isSelected
                                  ? (isCorrect ? Colors.white : Colors.white)
                                  : (isCorrect ? Colors.green : null),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentIndex > 0 ? _previousQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3D1FF),
                    foregroundColor: Colors.deepPurpleAccent,
                    shape: const StadiumBorder(),
                    elevation: 3,
                  ),
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: !_answered
                      ? null
                      : (_currentIndex < _questions.length - 1
                          ? _nextQuestion
                          : _showFinalResult),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCAF0F8),
                    foregroundColor: Colors.deepPurpleAccent,
                    shape: const StadiumBorder(),
                    elevation: 3,
                  ),
                  child:
                      Text(_currentIndex < _questions.length - 1 ? 'Next' : 'Submit'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AnimatedProgressBar(
              value: (_currentIndex + 1) / _questions.length,
            ),
            const SizedBox(height: 12),
            Text(
              'Score: $_score',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );
  }
}

class AnimatedProgressBar extends StatefulWidget {
  final double value;
  const AnimatedProgressBar({super.key, required this.value});

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double previousValue = 0.0;

  @override
  void initState() {
    super.initState();
    previousValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: previousValue, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressBar oldWidget) {
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: oldWidget.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller
        ..reset()
        ..forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return LinearProgressIndicator(
            value: _animation.value,
            backgroundColor: Colors.deepPurple.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
          );
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}