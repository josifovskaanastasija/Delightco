import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'user_profile.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile userProfile = UserProfile(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 16),
          FutureBuilder<String?>(
            future: userProfile.getUserProfilePicture(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                return CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(snapshot.data!),
                );
              } else {
                return CircleAvatar(radius: 60, child: Icon(Icons.person));
              }
            },
          ),
          SizedBox(height: 16),
          Text(
            FirebaseAuth.instance.currentUser != null
                ? FirebaseAuth.instance.currentUser!.email!.split('@')[0]
                : '',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Followers: 100', style: TextStyle(fontSize: 16)),
              SizedBox(width: 16),
              Text('Following: 50', style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
            },
            child: Text('Follow'),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text('User Images Placeholder'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, 
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/home');
          }
          if (index == 1) {
            Navigator.pushNamed(context, '/bookmarks');
          }
          if (index == 2) {
            Navigator.pushNamed(context, '/add_post');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Post',),
          BottomNavigationBarItem(
            icon: FirebaseAuth.instance.currentUser != null
                ? FutureBuilder<String?>(
                    future: userProfile.getUserProfilePicture(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(snapshot.data!),
                        );
                      } else {
                        return Icon(Icons.person);
                      }
                    },
                  )
                : Icon(Icons.person),
            label: FirebaseAuth.instance.currentUser != null
                ? FirebaseAuth.instance.currentUser!.email!.split('@')[0]
                : 'Sign In',
          ),
        ],
      ),
    );
  }
}
