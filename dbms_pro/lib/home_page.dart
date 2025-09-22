import 'package:flutter/material.dart';

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

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              title: Text('Home'),
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
        title: Text('Hi, Name!'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //News Section
            // Text(
            //   'News',
            //   style: TextStyle(
            //     fontSize: 24,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            SizedBox(height: 8),
           // Image.asset('lib/images/Food.png'), // Replace with your image

            SizedBox(height: 16),

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
                  CategoryItem('Food', 'lib/images/Food.png'),
                  CategoryItem('Entertainment', 'lib/images/entertainment.png'),
                  CategoryItem('Travel', 'lib/images/travel.png'),
                ],
              ),
            ),
            SizedBox(height: 24),

            Container(
              padding: EdgeInsets.all(16),
              color: Colors.yellow[100],
              child: Column(
                children: [
                  Text(
                    'Motivational Quote',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  Text(
                    'Wealth consists not in having great possessions, but in having few wants',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  )
                ],
              ),
            ),
            SizedBox(height: 15,),

            // Payment Section
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.orangeAccent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay to XYZ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            label: 'Group',
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
