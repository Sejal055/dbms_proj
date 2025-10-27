// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Placeholder Imports for Compilation ---
import 'add_expense_page.dart';
import 'profile_page.dart';
import 'history.dart';
import 'stats_page.dart' as stats;
import 'notification_page.dart';
import 'chat/chat_page.dart';
import 'category_page.dart';
import 'category_detail_page.dart';
import 'ai chat bot/ai_intro_page.dart';
import 'Quiz Game/quiz.dart';
import 'models/news_article.dart';
import 'services/rss_news_services.dart';
import 'services/recurring_payment_checker.dart';
import 'pending_payments_page.dart';
import 'budget_page.dart';
import 'goal_page.dart';
import 'debts_page.dart';
import 'planned_payments_page.dart';

// 1. Color Palette Definition
const Color _primaryColor = Color(0xFFD0E3FF); // Light Blue/Lavender
const Color _secondaryColor = Color(0xFFE9D5F8); // Light Purple/Pink
const Color _incomeColor = Color(
  0xFF5A96F0,
); // Bright Blue (Primary Action/Income, Progress Fill)
const Color _expenseColor = Color(0xFFB47BE8); // Medium Purple (Expense/Accent)
const Color _lightBackground = Color(
  0xFFF9FAFF,
); // Very light background for overall UI
const Color _headerColor = Colors.white; // Crisp white for the top header
const Color _textPrimary = Color(0xFF333333); // Dark text for contrast
const Color _textSecondary = Color(0xFF777777); // Light text for context

// Updated categories list with new color scheme
final categories = [
  {
    'title': 'Food & Dining',
    'icon': Icons.restaurant,
    'color': _primaryColor.withOpacity(0.5),
  },
  {
    'title': 'Transportation',
    'icon': Icons.directions_bus,
    'color': _secondaryColor.withOpacity(0.5),
  },
  {
    'title': 'Education',
    'icon': Icons.school,
    'color': const Color(0xFFE8FFF0),
  }, // Custom light
  {
    'title': 'Entertainment',
    'icon': Icons.movie,
    'color': const Color(0xFFFFECEB),
  }, // Custom light
];

List<Map<String, dynamic>> notifications = []; // low budget notifications

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = 'User';
  double totalIncome = 0;
  double totalExpense = 0;
  double monthlyBudget = 0;
  double initialAccountBalance = 0;
  List<NewsArticle> _rssArticles = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTotals();
    _loadNotifications();
    _loadRssNews();
    RecurringPaymentChecker.checkAndMoveRecurringPayments();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (mounted) {
          setState(() {
            userName = data?['name'] ?? 'User';
            monthlyBudget = (data?['monthly_budget'] is num)
                ? (data?['monthly_budget'] as num).toDouble()
                : 0.0;
            initialAccountBalance = (data?['amount_in_account'] is num)
                ? (data?['amount_in_account'] as num).toDouble()
                : 0.0;
          });
        }
      }
    }
  }

  Future<void> _loadRssNews() async {
    try {
      final articles = await RssNewsService.fetchNews();
      if (mounted) {
        setState(() {
          _rssArticles = articles.take(5).toList();
        });
      }
    } catch (e) {
      print('Error loading RSS news: $e');
    }
  }

  Future<void> _loadNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      notifications = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _loadTotals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .get();

    double income = 0;
    double expense = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['expense_amount'] is num)
          ? (data['expense_amount'] as num).toDouble()
          : 0.0;
      final type = data['expense_type'] ?? '';

      if (type == 'Income') {
        income += amount;
      } else if (type == 'Expense') {
        expense += amount;
      }
    }

    if (mounted) {
      setState(() {
        totalIncome = income;
        totalExpense = expense;
      });
    }
  }

  // Header Section
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 12),
      decoration: const BoxDecoration(
        color: _headerColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW: menu icon left and icons (notifications, pending, profile) on the right
          Row(
            children: [
              // menu icon (opens drawer)
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: _textPrimary,
                    size: 24,
                  ),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),

              const Spacer(),

              // notification icon
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: _textPrimary,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
              ),

              // pending payments icon
              IconButton(
                icon: const Icon(
                  Icons.hourglass_bottom,
                  color: _incomeColor,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PendingPaymentsPage(),
                    ),
                  );
                },
              ),

              const SizedBox(width: 6), // Spacing between icons
              // profile avatar
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: _expenseColor,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // GREETING
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ready to track your expenses today?',
                  style: TextStyle(fontSize: 14, color: _textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Helper widget for Income/Expense display
  Widget _buildMetricPill({
    required IconData icon,
    required String title,
    required double amount,
    required Color color,
    required bool isExpense,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.8),
                ),
              ),
              Text(
                '${isExpense ? '-' : '+'} ₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Total Balance Card (Uses the bright gradient)
  Widget _buildTotalBalanceCard() {
    final currentTotalBalance =
        initialAccountBalance + totalIncome - totalExpense;
    final double amountLeft = monthlyBudget - totalExpense;
    final double percentLeft = monthlyBudget <= 0
        ? 1.0
        : ((monthlyBudget - totalExpense) / monthlyBudget).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor], // Bright Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _expenseColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. Total Account Balance Section ---
          const Text(
            'Current Account Balance',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${currentTotalBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 15),

          // --- Income and Expense Summary ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricPill(
                icon: Icons.arrow_downward_rounded,
                title: 'Total Expense',
                amount: totalExpense,
                color: _expenseColor,
                isExpense: true,
              ),
              _buildMetricPill(
                icon: Icons.arrow_upward_rounded,
                title: 'Total Income',
                amount: totalIncome,
                color: _incomeColor,
                isExpense: false,
              ),
            ],
          ),

          const Divider(height: 30, color: Colors.white70),

          // --- 2. Monthly Budget Status Section (Merged) ---
          Row(
  children: [
    const Expanded(
      child: Text(
        "Budget Left",
        style: TextStyle(
            fontWeight: FontWeight.w600, fontSize: 15, color: _textPrimary),
      ),
    ),
    Text(
      "Monthly Budget: ₹${monthlyBudget.toStringAsFixed(0)}",
      style: const TextStyle(
          fontWeight: FontWeight.w500, fontSize: 12, color: _textSecondary),
    ),
  ],
),
const SizedBox(height: 6),
// Text(
//   // "₹${amountLeft.toStringAsFixed(0)}",
//   // style: TextStyle(
//   //   fontSize: 24,
//   //   fontWeight: FontWeight.w800,
//   //   color: amountLeft >= 0 ? _incomeColor : Colors.red.shade700,
//   // ),
// ),
          const SizedBox(height: 6),
          Text(
            "₹${amountLeft.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: amountLeft >= 0 ? _incomeColor : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
  value: percentLeft,
  minHeight: 8,
  backgroundColor: _headerColor,
  color: percentLeft < 0.2 ? Colors.red.shade400 : _incomeColor,
  borderRadius: BorderRadius.circular(8),
),

          const SizedBox(height: 5),
          Text(
  "${((1 - percentLeft) * 100).toStringAsFixed(1)}% of budget used",
  style: const TextStyle(
    fontSize: 11,
    color: _textSecondary,
  ),
),

        ],
      ),
    );
  }

  // Finance News Section
  Widget _buildFinanceNewsSection() {
    if (_rssArticles.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primaryColor, width: 1),
        ),
        child: Row(
          children: const [
            Icon(Icons.article_outlined, color: _incomeColor, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Loading latest finance news...',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Text(
            'Finance News Digest',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: _textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: _rssArticles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final article = _rssArticles[index];
              return GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(article.link);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _headerColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _textSecondary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      Row(
                        children: const [
                          Icon(
                            Icons.open_in_new,
                            color: _incomeColor,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Tap to Read More",
                            style: TextStyle(
                              fontSize: 12,
                              color: _incomeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // Helper Widget for a single category card in the 2x2 grid
  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CategoryDetailPage(category: cat['title'] as String),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: cat['color'] as Color, // Uses bright colors
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _textSecondary.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(cat['icon'] as IconData, size: 24, color: _expenseColor),
              const SizedBox(height: 8),
              Text(
                cat['title'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Categories Section (2x2 grid structure maintained)
  Widget _buildCategoriesSection(BuildContext context) {
    // Ensure we have at least 4 categories to display in a 2x2 grid
    final safeCategories = categories.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Explore Categories',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesPage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: _incomeColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size(50, 30),
                ),
                child: const Text('View All', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 2x2 GRID IMPLEMENTATION
        if (safeCategories.length >= 4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                // Row 1: Food & Transportation
                Row(
                  children: [
                    _buildCategoryCard(safeCategories[0]), // Food & Dining
                    const SizedBox(width: 10), // Spacing between cards
                    _buildCategoryCard(safeCategories[1]), // Transportation
                  ],
                ),
                const SizedBox(height: 10), // Spacing between rows
                // Row 2: Entertainment & Education
                Row(
                  children: [
                    _buildCategoryCard(safeCategories[3]), // Entertainment
                    const SizedBox(width: 10), // Spacing between cards
                    _buildCategoryCard(safeCategories[2]), // Education
                  ],
                ),
              ],
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Text('Not enough categories for 2x2 grid view.'),
          ),
        const SizedBox(height: 15),
      ],
    );
  }

  // Urgent Payments Section
  Widget _buildUrgentPaymentsSection() {
    final urgentNotifications = notifications.where((notif) {
      final body = (notif['body'] ?? '').toString().toLowerCase();
      final title = (notif['title'] ?? '').toString().toLowerCase();
      return body.contains('due') ||
          body.contains('overdue') ||
          body.contains('unpaid') ||
          title.contains('due') ||
          title.contains('overdue') ||
          title.contains('unpaid');
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'Urgent Payments',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFFD62828), // High-alert red
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            decoration: BoxDecoration(
              color: _headerColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFCCCC), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD62828).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: urgentNotifications.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No urgent payments 🎉',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: urgentNotifications.map((notif) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDADA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFD62828),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif['title'] ?? 'Urgent Alert',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    notif['body'] ?? 'Payment is due soon.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                notif['timestamp'] != null &&
                                        notif['timestamp'] is Timestamp
                                    ? (notif['timestamp'] as Timestamp)
                                          .toDate()
                                          .toLocal()
                                          .toString()
                                          .substring(5, 10) // Show only MM-DD
                                    : '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Drawer (Uses bright gradient, Quiz maintained)
  Drawer _buildSideDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _secondaryColor], // Bright Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Budget Buddy',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: _incomeColor),
              title: const Text(
                'Home',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet_rounded,
                color: _incomeColor,
              ),
              title: const Text(
                'Budget',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BudgetPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_rounded, color: _incomeColor),
              title: const Text(
                'Goals',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GoalPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off_rounded, color: _incomeColor),
              title: const Text(
                'Debts',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DebtsPage()),
                );
              },
            ),
            // Quiz replaces Planned Payments (Maintained)
            ListTile(
              leading: const Icon(Icons.quiz_rounded, color: _incomeColor),
              title: const Text(
                'Quiz',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizPage()),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Close'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      drawer: _buildSideDrawer(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. TOP HEADER
          _buildHeader(context),

          // 2. Current Account Balance Card
          _buildTotalBalanceCard(),

          // 3. Finance News Section
          _buildFinanceNewsSection(),

          // 4. Quiz Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuizPage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _secondaryColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _secondaryColor, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: _secondaryColor.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: const [
                    Icon(Icons.quiz_rounded, size: 26, color: _expenseColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Boost your Finance IQ!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: _textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Categories Section (2x2 grid structure maintained)
          _buildCategoriesSection(context),

          // 6. Urgent Payments Section
          _buildUrgentPaymentsSection(),
        ],
      ),
      // --- START OF FAB/BottomAppBar CHANGES ---

      // 1. Set location for the AI FAB (bottom right)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // 2. The Floating Action Button is now the AI Chat Bot icon
      floatingActionButton: FloatingActionButton(
        heroTag:
            "ai_fab", // Use a unique heroTag for multiple FloatingActionButtons
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiIntroPage()),
          );
        },
        backgroundColor: _expenseColor,
        // CHANGED ICON TO SMART TOY/ROBOT
        child: const Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),

      // 3. Bottom Bar: Re-implement Add Expense button inside the row
      bottomNavigationBar: BottomAppBar(
        color: _headerColor,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.home_rounded, color: _incomeColor, size: 24),
                  Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 10,
                      color: _incomeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // History
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryPage(),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: _textSecondary,
                      size: 24,
                    ),
                    Text(
                      'History',
                      style: TextStyle(fontSize: 10, color: _textSecondary),
                    ),
                  ],
                ),
              ),

              // Add Expense Button (Custom circle button to replace the docked FAB)
              Container(
                margin: const EdgeInsets.only(
                  top: 0,
                ), // No extra margin needed as it's inline
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _incomeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _incomeColor.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddExpensePopup(
                        onCancel: () => Navigator.of(context).pop(),
                      ),
                    );
                  },
                ),
              ),

              // Stats
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => stats.StatisticsMainPage(),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: _textSecondary,
                      size: 24,
                    ),
                    Text(
                      'Stats',
                      style: TextStyle(fontSize: 10, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              // Chat
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatListScreen()),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_rounded, color: _textSecondary, size: 24),
                    Text(
                      'Chat',
                      style: TextStyle(fontSize: 10, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
