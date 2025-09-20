import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, Name!'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
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
            // Image.asset('lib/images/Food.png'), // Replace with your image

            SizedBox(height: 16),

            // Budget Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Left to spend',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Rs.15000',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.75, // Adjust value to show progress
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Budget',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Rs.20000',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Categories Section
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryItem('Food', 'lib/images/Food.png'),
                  CategoryItem('Entertainment', 'lib/images/entertainment.png'),
                  CategoryItem('Travel', 'lib/images/travel.png'),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Payment Section
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.yellow[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay to XYZ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Due on 30 Sep 2025',
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
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String label;
  final String imageAsset;

  const CategoryItem(this.label, this.imageAsset);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(imageAsset),
          ),
          SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
