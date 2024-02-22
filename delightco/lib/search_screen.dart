import 'package:delightco/post_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> allPosts = [];
  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    fetchAllPosts();
  }

  void fetchAllPosts() {
    FirebaseFirestore.instance
        .collection('posts')
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        allPosts = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        searchResults = allPosts;
      });
    });
  }

  void searchPosts(String query) {
    query = query.toLowerCase();
    setState(() {
      searchResults = allPosts
          .where((post) => post['description'].toLowerCase().contains(query))
          .toList();
    });
  }

  List<Map<String, dynamic>> bookmarkedPosts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for posts...',
          ),
          onChanged: (query) {
            searchPosts(query);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          return Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                var post = searchResults[index];
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

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      var username = userSnapshot.data?['username'] ?? '';
                      var profilePictureUrl =
                          userSnapshot.data?['profilePictureUrl'] ?? '';
                      print("profilePictureUrl: $profilePictureUrl");

                      return PostWidget(
                        authorProfilePicture: profilePictureUrl,
                        username: username,
                        rating: post['rating'],
                        postPicture: post['imageUrl'],
                        description: post['description'],
                        userId: post['userId'],
                        isBookmarked: bookmarkedPosts.any((bookmark) =>
                            bookmark['userId'] == post['userId'] &&
                            bookmark['description'] == post['description']),
                        onBookmarkToggle: (isBookmarked) {
                          setState(() {
                            if (isBookmarked) {
                              bookmarkedPosts.add({
                                'userId': post['userId'],
                                'description': post['description'],
                              });
                            } else {
                              bookmarkedPosts.removeWhere((bookmark) =>
                                  bookmark['userId'] == post['userId'] &&
                                  bookmark['description'] ==
                                      post['description']);
                            }
                          });
                        }, location: post['location']
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
      ),
    );
  }
}
