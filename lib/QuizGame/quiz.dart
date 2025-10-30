import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ====================================================================
// APP THEME AND CONSTANTS
// ====================================================================

const int kQuizLimit = 5; // 5 questions per quiz - Confirmed to be 5

const Color kLightHeaderColor = Color(0xFFB5D1FF);
const Color kDarkHeaderColor = Color(0xFFE0C3FF);
const Color kMainColor = Color(0xFF5A96F0);
const Color kAccentColor = Color(0xFF9C6CDD);
const Color kSuccessColor = Color(0xFF66BB6A);
const Color kErrorColor = Color(0xFFEF5350);

const LinearGradient kAppGradient = LinearGradient(
  colors: [kLightHeaderColor, kDarkHeaderColor],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ====================================================================
// STATIC QUIZ DATA (Each category has 5 questions)
// ====================================================================

final Map<String, List<Map<String, dynamic>>> kStaticQuestions = {
  'Budgeting': [
    {
      'question': 'What is the main purpose of budgeting?',
      'options': [
        'To spend more money',
        'To plan and manage expenses',
        'To avoid saving',
        'To take more loans'
      ],
      'correctIndex': 1
    },
    {
      'question': 'Which of the following is a fixed expense?',
      'options': ['Rent', 'Groceries', 'Electricity bill', 'Movie tickets'],
      'correctIndex': 0
    },
    {
      'question': 'Why should you track your spending?',
      'options': [
        'To know where your money goes',
        'To earn more',
        'To avoid paying taxes',
        'For fun'
      ],
      'correctIndex': 0
    },
    {
      'question': 'What helps in creating a realistic budget?',
      'options': [
        'Ignoring past expenses',
        'Tracking actual spending',
        'Spending impulsively',
        'Guessing expenses'
      ],
      'correctIndex': 1
    },
    {
      'question': 'Emergency funds should cover how many months of expenses?',
      'options': ['1-2 months', '3-6 months', '6-9 months', '12 months'],
      'correctIndex': 1
    },
  ],
  'Saving': [
    {
      'question': 'What is an emergency fund?',
      'options': [
        'Money saved for vacations',
        'Money for unexpected expenses',
        'Money for luxury shopping',
        'Money for gifts'
      ],
      'correctIndex': 1
    },
    {
      'question': 'How much of your income should ideally be saved?',
      'options': ['10%', '20%', '30%', '50%'],
      'correctIndex': 2
    },
    {
      'question': 'Which account type offers interest on savings?',
      'options': ['Savings account', 'Current account', 'Loan account', 'Credit account'],
      'correctIndex': 0
    },
    {
      'question': 'Which is a good saving habit?',
      'options': [
        'Spend first, save later',
        'Save first, spend later',
        'Avoid saving',
        'Borrow to save'
      ],
      'correctIndex': 1
    },
    {
      'question': 'Which tool helps track savings goals?',
      'options': ['Notebook', 'Mobile app', 'Spending tracker', 'All of these'],
      'correctIndex': 3
    },
  ],
  'Investing': [
    {
      'question': 'What is diversification in investing?',
      'options': [
        'Putting all money in one stock',
        'Spreading investments across assets',
        'Borrowing money to invest',
        'Avoiding investments'
      ],
      'correctIndex': 1
    },
    {
      'question': 'Which investment is considered low-risk?',
      'options': ['Stocks', 'Bonds', 'Cryptocurrency', 'Options trading'],
      'correctIndex': 1
    },
    {
      'question': 'Why do people invest in mutual funds?',
      'options': [
        'For professional management',
        'For quick gambling returns',
        'To avoid diversification',
        'Because they hate banks'
      ],
      'correctIndex': 0
    },
    {
      'question': 'What does ROI stand for?',
      'options': [
        'Return on Investment',
        'Rate of Inflation',
        'Risk of Interest',
        'Return of Insurance'
      ],
      'correctIndex': 0
    },
    {
      'question': 'What is a common advantage of SIP (Systematic Investment Plan)?',
      'options': [
        'Invests a fixed amount regularly',
        'High risk investment',
        'Short-term trading only',
        'Only for businesses'
      ],
      'correctIndex': 0
    },
  ],
};

// ====================================================================
// DATA MODEL
// ====================================================================

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

  factory QuizQuestion.fromMap(Map<String, dynamic> data, String id) {
    return QuizQuestion(
      id: id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
    );
  }
}

// ====================================================================
// QUIZ PAGE
// ====================================================================

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
  int? _confirmedIndex;

  String _currentCategory = 'Budgeting';
  List<String> _categories = ['Budgeting', 'Saving', 'Investing'];

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
    final random = Random();
    final all = kStaticQuestions[category] ?? [];
    all.shuffle(random);
    // Enforces the kQuizLimit (which is 5) questions
    final selected = all.take(kQuizLimit).toList(); 

    setState(() {
      _questions = selected
          .asMap()
          .entries
          .map((e) => QuizQuestion.fromMap(e.value, e.key.toString()))
          .toList();
      _currentIndex = 0;
      _score = 0;
      _answered = false;
      _selectedIndex = null;
      _confirmedIndex = null;
    });

    _fadeController.forward(from: 0);
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void _confirmAnswer() {
    if (_selectedIndex == null || _answered) return;
    setState(() {
      _confirmedIndex = _selectedIndex;
      _answered = true;
      if (_questions[_currentIndex].correctIndex == _confirmedIndex) {
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
        _confirmedIndex = null;
      });
      _fadeController.forward(from: 0);
    } else {
      _showFinalResult();
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

  String _scoreRemark() {
    double percentage = (_score / _questions.length) * 100;
    if (percentage >= 90) return "Excellent! You're a financial whiz!";
    if (percentage >= 70) return "Great effort! Solid knowledge base.";
    if (percentage >= 50) return "Fair. Review the basics to boost your score.";
    return "Keep learning! Don't give up and try again!";
  }

  void _showFinalResult() async {
    await _saveScore();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎉 Quiz Completed!', style: TextStyle(color: kMainColor)),
        content: Text(
            'Your Score: $_score / ${_questions.length}\n\n${_scoreRemark()}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadCategoryQuestions(_currentCategory);
            },
            child: const Text('Start Again', style: TextStyle(color: kMainColor)),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QuizDashboardPage()),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildCategoryTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _categories.map((cat) {
        bool isSelected = cat == _currentCategory;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (!isSelected) {
                setState(() => _currentCategory = cat);
                _loadCategoryQuestions(cat);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isSelected ? kAccentColor : kLightHeaderColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: kAccentColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : kAccentColor.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 5,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        disabledBackgroundColor: bgColor.withOpacity(0.5),
        disabledForegroundColor: fgColor.withOpacity(0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kMainColor)),
      );
    }

    final question = _questions[_currentIndex];
    final canConfirm = _selectedIndex != null && !_answered;
    final canProceed = _answered;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          child: Container(
            decoration: const BoxDecoration(gradient: kAppGradient),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Financial Quiz',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                  onPressed: () => _navigateToDashboard(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryTabs(),
            const SizedBox(height: 15),
            AnimatedProgressBar(value: (_currentIndex + 1) / _questions.length),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Question ${_currentIndex + 1} of ${_questions.length}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: kMainColor)),
                Text('Score: $_score',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: kMainColor))
              ],
            ),
            const SizedBox(height: 15),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Card(
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(question.question,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
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
                  final isConfirmed = _confirmedIndex == idx;
                  final isCorrect = question.correctIndex == idx;

                  Color bg = Colors.white;
                  Color textColor = Colors.black87;
                  IconData? icon;

                  if (_answered) {
                    if (isCorrect) {
                      bg = kSuccessColor.withOpacity(0.3);
                      icon = Icons.check_circle_outline;
                    }
                    if (isConfirmed && !isCorrect) {
                      bg = kErrorColor.withOpacity(0.8);
                      textColor = Colors.white;
                      icon = Icons.cancel;
                    }
                    if (isConfirmed && isCorrect) {
                      bg = kSuccessColor.withOpacity(0.8);
                      textColor = Colors.white;
                      icon = Icons.check_circle;
                    }
                  } else if (isSelected) {
                    bg = kAccentColor.withOpacity(0.2);
                    textColor = kAccentColor;
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isSelected ? kAccentColor : Colors.grey.shade300, width: 2),
                    ),
                    child: InkWell(
                      onTap: _answered ? null : () => _selectOption(idx),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(option,
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: textColor)),
                            ),
                            if (icon != null)
                              Icon(icon, color: textColor == Colors.white ? Colors.white : kMainColor),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_answered)
                  _buildActionButton(
                    onPressed: canConfirm ? _confirmAnswer : null,
                    label: 'Confirm',
                    icon: Icons.check,
                    bgColor: kAccentColor,
                    fgColor: Colors.white,
                  )
                else
                  _buildActionButton(
                    onPressed: canProceed ? _nextQuestion : null,
                    label: _currentIndex == _questions.length - 1 ? 'Finish' : 'Next',
                    icon: Icons.arrow_forward,
                    bgColor: kMainColor,
                    fgColor: Colors.white,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// DASHBOARD PAGE (Fixed Overlap)
// ====================================================================

class QuizDashboardPage extends StatelessWidget {
  const QuizDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
           body: Center(child: Text('Please log in to view your performance.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quiz Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: kAppGradient)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scores')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: kMainColor));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('No quiz attempts yet. Start your first quiz!',
                  style: TextStyle(fontSize: 16, color: Colors.black54)),
            );
          }

          final scores = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['score'] ?? 0) / (data['total'] ?? 1);
          }).toList();

          double average = scores.reduce((a, b) => a + b) / scores.length;
          double best = scores.reduce((a, b) => a > b ? a : b);
          double latest = scores.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // --- Updated Overall Performance Card ---
                _buildPerformanceCard(
                  average: average,
                ),
                // --- End Updated Performance Card ---
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      icon: Icons.school,
                      label: "Quizzes Taken",
                      value: docs.length.toString(),
                      color: kMainColor,
                    ),
                    _buildStatCard(
                      icon: Icons.emoji_events,
                      label: "Best Score",
                      value: "${(best * 100).toStringAsFixed(1)}%",
                      color: kSuccessColor,
                    ),
                    _buildStatCard(
                      icon: Icons.assessment,
                      label: "Recent",
                      value: "${(latest * 100).toStringAsFixed(1)}%",
                      color: kAccentColor,
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                const Divider(thickness: 1.2),
                const SizedBox(height: 10),
                const Text(
                  "Your Quiz History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kMainColor),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final score = data['score'] ?? 0;
                    final total = data['total'] ?? 1;
                    final category = data['category'] ?? 'General';
                    final ts = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now();

                    final percentage = (score / total) * 100;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: percentage >= 80
                              ? kSuccessColor.withOpacity(0.8)
                              : percentage >= 60
                                  ? kMainColor.withOpacity(0.8)
                                  : kErrorColor.withOpacity(0.8),
                          child: Text(
                            "${score}",
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          "$category Quiz",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: kAccentColor),
                        ),
                        subtitle: Text(
                          "${percentage.toStringAsFixed(1)}% • ${ts.day}/${ts.month}/${ts.year}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: Icon(
                          percentage >= 80
                              ? Icons.emoji_events
                              : percentage >= 60
                                  ? Icons.thumb_up
                                  : Icons.refresh,
                          color: percentage >= 80
                              ? kSuccessColor
                              : percentage >= 60
                                  ? kMainColor
                                  : kErrorColor,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method for the redesigned Performance Card with FIXED OVERLAP
  Widget _buildPerformanceCard({
    required double average,
  }) {
    String remark;
    IconData icon;
    Color color;

    if (average >= 0.8) {
      remark = "Excellent progress! Keep up the financial smarts.";
      icon = Icons.star;
      color = kSuccessColor;
    } else if (average >= 0.6) {
      remark = "Good work! A solid foundation for financial literacy.";
      icon = Icons.trending_up;
      color = kMainColor;
    } else {
      remark = "Keep practicing! You're on your way to better scores.";
      icon = Icons.refresh;
      color = kErrorColor;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kMainColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: kLightHeaderColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Overall Performance",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kAccentColor),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 150,
            width: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // CircularProgressIndicator remains the background element
                SizedBox(
                  height: 150,
                  width: 150,
                  child: CircularProgressIndicator(
                    value: average,
                    strokeWidth: 15,
                    backgroundColor: kLightHeaderColor.withOpacity(0.5),
                    color: kMainColor,
                  ),
                ),
                // This Column holds the centered text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${(average * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        color: kMainColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Average',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  remark,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// PROGRESS BAR WIDGET
// ====================================================================

class AnimatedProgressBar extends StatelessWidget {
  final double value;
  const AnimatedProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.grey.shade300,
        color: kAccentColor,
        minHeight: 10,
      ),
    );
  }
}