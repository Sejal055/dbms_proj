import 'package:flutter/material.dart';
import 'add_expense_page.dart';
import 'history.dart';
import 'models/expense.dart';

void main() {
  runApp(homepage());
}

class homepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> _expenses = [];
  
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  int _selectedIndex = 0;

void _onItemTapped(int index) {
  switch (index) {
    case 0:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
      break;
    case 1:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HistoryPage(expenses: _expenses)),
      );
      break;
    case 2:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddExpensePage(
            onSaveExpense: (expense) {
              setState(() {
                _expenses.add(expense);
              });
            },
          ),
        ),
      );
      break;
    case 3:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GroupPage()),
      );
      break;
    case 4:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StatisticsPage()),
      );
      break;
  }
}


  final List<Map<String, String>> newsItems = [
    {
      'title': 'Budget Tips',
      'content': 'Learn how to manage your money better this month.',
      'image': 'lib/images/Food.png',
    },
    {
      'title': 'Save More',
      'content': 'Tips to save 20% of your income without stress.',
      'image': 'lib/images/entertainment.png',
    },
    {
      'title': 'Invest Smart',
      'content': 'Beginner\'s guide to investing in 2025.',
      'image': 'lib/images/travel.png',
    },
  ];

  final List<String> financeQuotes = [
    "“Wealth consists not in having great possessions, but in having few wants.” - Epictetus",
    "“Do not save what is left after spending, but spend what is left after saving.” - Warren Buffett",
    "“An investment in knowledge pays the best interest.” - Benjamin Franklin",
    "“Beware of little expenses. A small leak will sink a great ship.” - Benjamin Franklin",
    "“The goal isn't more money. The goal is living life on your terms.” - Chris Brogan",
    "“Money is a terrible master but an excellent servant.” - P.T. Barnum",
  ];

  late String _currentQuote = getRandomQuote();

  String getRandomQuote() {
    final random = financeQuotes.toList()..shuffle();
    return random.first;
  }

  @override
  void initState() {
    super.initState();
    _currentQuote = getRandomQuote();
    Future.delayed(Duration.zero, () {
      _startAutoSlide();
    });
  }
  
  void _startAutoSlide() {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 4));
      if (!mounted) return false;
      int nextPage = (_currentPage + 1) % newsItems.length;
      _pageController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage = nextPage;
      });
      return true;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildHomePage() {
    return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // News Section
                Text(
                  'News',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: newsItems.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final news = newsItems[index];
                            return NewsCard(
                              title: news['title']!,
                              content: news['content']!,
                              //imagePath: news['image']!,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(newsItems.length, (index) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 12 : 8,
                            height: _currentPage == index ? 12 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? Colors.blue : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Motivational Quote Section with random generator
                Container(
                  padding: EdgeInsets.all(20),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.yellow.shade100, Colors.orange.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 36,
                            color: Colors.orange.shade700,
                          ),
                          
                          SizedBox(width: 8),
                          Text(
                            'Motivational Quote',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        _currentQuote,
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentQuote = getRandomQuote();
                            });
                          },
                          icon: Icon(Icons.refresh, color: Colors.orange),
                          label: Text(
                            'New Quote',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25),
          
                // Budget Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Left to spend',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, ),
                    ),
                    Text(
                      'Monthly Budget',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,),
                    ),
                  ],
                ),
          
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.500',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold ),
                    ),
                    Text(
                      'Rs.1000',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,),
                    ),
                  ],
                ),
          
                SizedBox(height: 8),
                LinearProgressIndicator(
                  minHeight: 15,
                  borderRadius: BorderRadius.circular(8),
                  value: 0.5, // Adjust value to show progress
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                
                SizedBox(height: 24),
          
                // Categories Section
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize:21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      CategoryItem('Food', icon: Icons.fastfood),
                      CategoryItem('Entertainment', icon: Icons.movie),
                      CategoryItem('Travel', icon: Icons.flight),
                      CategoryItem('Shopping', icon: Icons.shopping_cart),
                    ],
                  ),
                ),

                SizedBox(height: 24),
          
                // Payment Section
                Text(
                  'Urgent Payments',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20,),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, weight: 8,),
                              Text(
                                '  Pay to Simran',
                                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
          
                            ],
          
                          ),
                          
                          Text(
                            'Cafeteria   30 Sep 2025',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        'Rs.200',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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


  @override
  Widget build(BuildContext context) {
  
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer( // <-- Step 1: Add Drawer
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home',),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // Add more menu items here
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Hi, Sonal!'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {},
          ),
        ],
      ),

      body: _buildHomePage(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        //unselectedItemColor: Colors.black,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              size: 30,
              color: Colors.black,
              Icons.home_rounded,
              ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              size: 30,
              color: Colors.black,
              Icons.history,
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(size: 30,
              color: Colors.black,
              Icons.add_box_outlined,
              ),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              size: 30,
              color: Colors.black,
              Icons.group_add_outlined,
              ),
            label: 'Group',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              size: 30,
              color: Colors.black,
              Icons.stacked_bar_chart,
              ),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String label;
  final String? imageAsset;
  final IconData? icon;

  const CategoryItem(this.label, {this.imageAsset, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade100, Colors.blue.shade300],
              ),
            ),
            child: imageAsset != null
                ? Image.asset(
                    imageAsset!,
                    width: 30,
                    height: 30,
                  )
                : Icon(
                    icon,
                    size: 30,
                    color: Colors.blue.shade800,
                  ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class NewsCard extends StatelessWidget {
  final String title;
  final String content;
  ///final String imagePath;

  const NewsCard({
    required this.title,
    required this.content,
    //required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      width: MediaQuery.of(context).size.width * 0.8, // Responsive width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          // Expanded(
          //   child: Image.asset(
          //     imagePath,
          //     fit: BoxFit.contain,
          //   ),
          // ),
        ],
      ),
    );
  }
}


class GroupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Group Page',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class StatisticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Statistics Page',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
