import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'user_profile.dart';

class PostWidget extends StatefulWidget {
  final String authorProfilePicture;
  final String username;
  final int rating;
  final String postPicture;
  final String description;
  final String userId;
  bool isBookmarked;
  final Function(bool) onBookmarkToggle;

  PostWidget({
    required this.authorProfilePicture,
    required this.username,
    required this.rating,
    required this.postPicture,
    required this.description,
    required this.userId,
    this.isBookmarked = false,
    required this.onBookmarkToggle,
  });
  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isExpanded = false;
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

  void toggleBookmark() {
    setState(() {
      widget.isBookmarked = !widget.isBookmarked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(widget.authorProfilePicture),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserProfileScreen(userId: widget.userId),
                    ),
                  );
                },
                child: Text(
                  widget.username,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              Spacer(),
              IconButton(
                icon: widget.isBookmarked
                    ? Icon(Icons.bookmark)
                    : Icon(Icons.bookmark_border),
                onPressed: () {
                  widget.onBookmarkToggle(!widget.isBookmarked);
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text('Rating:'),
              SizedBox(width: 8),
              Row(children: buildStarRating(widget.rating)),
            ],
          ),
          SizedBox(height: 8),
          Image.network(widget.postPicture),
          SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '${widget.username} ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                isExpanded
                    ? TextSpan(
                        text: widget.description,
                      )
                    : TextSpan(
                        text: widget.description.length > 250
                            ? widget.description.substring(0, 250) + '...'
                            : widget.description,
                      ),
                widget.description.length > 250
                    ? WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isExpanded = !isExpanded;
                            });
                          },
                          child: Text(
                            isExpanded ? ' View Less' : ' View More',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : TextSpan(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  final String userId;
  final UserProfile userProfile = UserProfile();

  UserProfileScreen({required this.userId});

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
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              if (userSnapshot.hasError) {
                return Text('Error: ${userSnapshot.error}');
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                var username = userSnapshot.data?['username'] ?? '';
                var profilePictureUrl =
                    userSnapshot.data?['profilePictureUrl'] ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(profilePictureUrl),
                    ),
                    SizedBox(height: 16),
                    Text(
                      username,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              } else {
                return Text(
                    'User document not found or does not contain a username field.');
              }
            },
          ),
          SizedBox(height: 16),
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId', isEqualTo: userId)
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
                    var postUserId = post['userId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(postUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        if (userSnapshot.hasError) {
                          return Text('Error: ${userSnapshot.error}');
                        }

                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          var username = userSnapshot.data?['username'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullPostScreen(
                                    authorProfilePicture: userSnapshot
                                            .data?['profilePictureUrl'] ??
                                        '',
                                    username: username,
                                    rating: post['rating'],
                                    postPicture: imageUrl,
                                    description: post['description'],
                                    userId: postUserId,
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
                        } else {
                          return Text(
                              'User document not found or does not contain a username field.');
                        }
                      },
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
  final String authorProfilePicture;
  final String username;
  final int rating;
  final String postPicture;
  final String description;
  final String userId;

  FullPostScreen({
    required this.authorProfilePicture,
    required this.username,
    required this.rating,
    required this.postPicture,
    required this.description,
    required this.userId,
  });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
      ),
      body: Container(
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
                  username,
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
                  fontSize: 16,
                ),
                children: [
                  TextSpan(
                    text: '$username ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: description,
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
