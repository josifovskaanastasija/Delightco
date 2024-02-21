import 'package:delightco/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
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
              // Implement follow logic
            },
            child: Text('Follow'),
          ),
          SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No posts available.'));
                }
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var post = snapshot.data!.docs[index];
                    var imageUrl = post['imageUrl'];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullPostScreen(
                              rating: post['rating'],
                              postPicture: imageUrl,
                              description: post['description'],
                              userId:
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                            ),
                          ),
                        );
                      },
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              },
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

class FullPostScreen extends StatelessWidget {
  final String userId;
  final int rating;
  final String postPicture;
  final String description;
  final UserProfile userProfile = UserProfile();

  FullPostScreen({
    required this.userId,
    required this.rating,
    required this.postPicture,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
      ),
      body: FutureBuilder<String?>(
        future: userProfile.getUserProfilePicture(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var authorProfilePicture = snapshot.data ?? '';

          return Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(authorProfilePicture),
                    ),
                    SizedBox(width: 8),
                    Text(
                      FirebaseAuth.instance.currentUser != null
                          ? FirebaseAuth.instance.currentUser!.email!
                              .split('@')[0]
                          : '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text('Rating:'),
                    SizedBox(width: 8),
                    Row(children: buildStarRating(rating)),
                  ],
                ),
                SizedBox(height: 8),
                Image.network(postPicture),
                SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                    children: [
                      TextSpan(
                        text: FirebaseAuth.instance.currentUser != null
                            ? FirebaseAuth.instance.currentUser!.email!
                                .split('@')[0]
                            : ' ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(text: ' '),
                      TextSpan(
                        text: description,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> buildStarRating(int rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (i <= rating) {
        stars.add(Icon(Icons.star, color: Colors.yellow));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.yellow));
      }
    }
    return stars;
  }
}
