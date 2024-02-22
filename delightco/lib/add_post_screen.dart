import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController descriptionController = TextEditingController();
  int rating = 1;
  File? _pickedImage;
  LatLng? _selectedLocation;
  String? _selectedPlaceName;
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(0, 0),
    zoom: 15,
  );

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedImage = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  _setImage(pickedImage);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedImage = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  _setImage(pickedImage);
                },
              ),
            ],
          ),
        );
      },
    );
  }

 Future<void> _selectLocation() async {
  
    Position position = await Geolocator.getCurrentPosition();
    LatLng currentPosition = LatLng(position.latitude, position.longitude);

    List<Placemark> placemarks = await placemarkFromCoordinates(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    Placemark place = placemarks.first;

    _selectedLocation = await showMapPicker(currentPosition, place.name ?? '');

    setState(() {
      if (_selectedLocation != null) {
        _initialCameraPosition = CameraPosition(
          target: _selectedLocation!,
          zoom: 15,
        );
      }
    });
}


  Future<LatLng?> showMapPicker(LatLng initialLocation, String initialPlaceName) async {
    LatLng? selectedLocation;
    String? selectedPlaceName;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPicker(
          initialLocation: initialLocation,
          initialPlaceName: initialPlaceName,
          onPlacePicked: (LatLng location, String placeName) {
            selectedLocation = location;
            selectedPlaceName = placeName;
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    _selectedPlaceName = selectedPlaceName;
    return selectedLocation;
  }

  void _setImage(XFile? pickedImage) {
    if (pickedImage != null) {
      setState(() {
        _pickedImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _pickedImage != null
                      ? Image.file(_pickedImage!)
                      : Icon(Icons.add_a_photo, size: 30, color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectLocation,
              child: Text('Select Location'),
            ),
            SizedBox(height: 16),
            Text('Selected Place: ${_selectedPlaceName ?? 'N/A'}'),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: null,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('Rating:'),
                SizedBox(width: 8),
                DropdownButton<int>(
                  value: rating,
                  onChanged: (value) {
                    setState(() {
                      rating = value!;
                    });
                  },
                  items: List.generate(5, (index) => index + 1)
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _uploadPost();
          Navigator.pop(context);
        },
        child: Icon(Icons.post_add),
      ),
    );
  }

  Future<void> _uploadPost() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      String uid = user?.uid ?? '';

      String postId = FirebaseFirestore.instance.collection('posts').doc().id;

      if (_pickedImage != null) {
        firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('posts/$postId.jpg');
        await storageRef.putFile(_pickedImage!);

        String imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance.collection('posts').doc(postId).set({
          'userId': uid,
          'description': descriptionController.text,
          'rating': rating,
          'imageUrl': imageUrl,
          'location': _selectedLocation != null
              ? GeoPoint(
                  _selectedLocation!.latitude,
                  _selectedLocation!.longitude,
                )
              : null,
          'placeName': _selectedPlaceName ?? '',
        });
      }
    } catch (e) {
      print('Error uploading post: $e');
    }
  }
}

class MapPicker extends StatelessWidget {
  final LatLng initialLocation;
  final String initialPlaceName;
  final Function(LatLng, String) onPlacePicked;

  MapPicker({required this.initialLocation, required this.initialPlaceName, required this.onPlacePicked});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialLocation,
          zoom: 15,
        ),
        onTap: (LatLng location) async {
          List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
          String placeName = placemarks.isNotEmpty ? placemarks[0].name ?? '' : '';

          onPlacePicked(location, placeName);
        },
      ),
    );
  }
}
