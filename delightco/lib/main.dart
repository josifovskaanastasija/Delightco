import 'package:delightco/add_post_screen.dart';
import 'package:delightco/firebase_options.dart';
import 'package:delightco/login_screen.dart';
import 'package:delightco/profile_screen.dart';
import 'package:delightco/search_screen.dart';
import 'package:delightco/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile.dart';
import 'post_widget.dart';
import 'bookmarks_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => MyHomePage(),
        '/profile': (context) => ProfileScreen(),
        '/add_post': (context) => AddPostScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  String username = '';
  UserProfile userProfile = UserProfile();
  List<Map<String, dynamic>> bookmarkedPosts = [];

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && user.email != null) {
        updateUsername(user.email!);
      }
    });
  }

  void updateUsername(String email) {
    setState(() {
      username = email.split('@')[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delightco'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.explore),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('posts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                var posts = snapshot.data?.docs ?? [];
                return Expanded(
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      var post = posts[index].data() as Map<String, dynamic>;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(post['userId'])
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }

                          if (userSnapshot.hasError) {
                            print("UserID: ${post['userId']}");
                            return Text('Error: ${userSnapshot.error}');
                          }

                          if (userSnapshot.hasData &&
                              userSnapshot.data!.exists) {
                            var username = userSnapshot.data?['username'] ?? '';
                            var profilePictureUrl =
                                userSnapshot.data?['profilePictureUrl'] ?? '';
                            print(post['imageUrl']);

                            return PostWidget(
                              authorProfilePicture: profilePictureUrl,
                              username: username,
                              rating: post['rating'],
                              postPicture: post['imageUrl'],
                              description: post['description'],
                              userId: post['userId'],
                              isBookmarked: bookmarkedPosts.any((bookmark) =>
                                  bookmark['userId'] == post['userId'] &&
                                  bookmark['description'] ==
                                      post['description']),
                              onBookmarkToggle: (isBookmarked) {
                                setState(() {
                                  if (isBookmarked) {
                                    print("Added to List: " +
                                        post['description']);

                                    bookmarkedPosts.add({
                                      'username': username,
                                      'rating': post['rating'],
                                      'userId': post['userId'],
                                      'description': post['description'],
                                      'imageUrl': post['imageUrl'],
                                      'location': post['location'],
                                    });
                                  } else {
                                    print("Removed to List: " +
                                        post['description']);
                                    bookmarkedPosts.removeWhere((bookmark) =>
                                        bookmark['userId'] == post['userId'] &&
                                        bookmark['description'] ==
                                            post['description'] &&
                                        bookmark['username'] == username &&
                                        bookmark['rating'] == post['rating'] &&
                                        bookmark['imageUrl'] ==
                                            post['imageUrl'] &&
                                        bookmark['location'] ==
                                            post['location']);
                                  }
                                });
                              },
                              location: post['location'],
                            );
                          } else {
                            print("UserID: ${post['userId']}");
                            return Text(
                                'User document not found or does not contain a username field.');
                          }
                        },
                      );
                    },
                  ),
                );
              },
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 2) {
              Navigator.pushNamed(context, '/add_post');
            } else if (index == 3) {
              Navigator.pushNamed(context, '/profile');
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BookmarksScreen(bookmarkedPosts: bookmarkedPosts),
                ),
              );
            }
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Post',
          ),
          BottomNavigationBarItem(
            icon: FirebaseAuth.instance.currentUser != null
                ? FutureBuilder<String?>(
                    future: userProfile.getUserProfilePicture(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
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
