import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarksScreen extends StatelessWidget {
  final List<Map<String, dynamic>> bookmarkedPosts;

  BookmarksScreen({required this.bookmarkedPosts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarks'),
      ),
      body: ListView.builder(
        itemCount: bookmarkedPosts.length,
        itemBuilder: (context, index) {
          var bookmarkedPost = bookmarkedPosts[index];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(bookmarkedPost['userId'])
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

                var postImageUrl = bookmarkedPost['imageUrl'] ?? '';
                print("XXXXXXXXXXXXXXXXX: $postImageUrl");

                return Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(profilePictureUrl),
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
                          Spacer(),
                          Icon(Icons.bookmark, color: Colors.blue),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Rating:'),
                          SizedBox(width: 8),
                          Row(
                            children: buildStarRating(bookmarkedPost['rating']),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Image.network(postImageUrl),
                      SizedBox(height: 8),
                      Text(bookmarkedPost['description']),
                    ],
                  ),
                );
              } else {
                return Text(
                    'User document not found or does not contain a username field.');
              }
            },
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