import 'package:flutter/material.dart';

class PostWidget extends StatelessWidget {
  final String authorProfilePicture;
  final String username;
  final int rating;
  final String postPicture;
  final String description;

  PostWidget({
    required this.authorProfilePicture,
    required this.username,
    required this.rating,
    required this.postPicture,
    required this.description,
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
                username,
                style: TextStyle(fontWeight: FontWeight.bold),
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
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '${username} ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: description,
                ),
        ],
      ),
          ),
        ],
      ),
    );
  }
}
