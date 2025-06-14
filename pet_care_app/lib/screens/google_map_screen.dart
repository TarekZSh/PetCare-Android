import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart'; // Add this import for permission handling
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:location/location.dart' as loc;

class GoogleMapScreen extends StatefulWidget {
  final Function(LatLng, String) onPlaceSelected;

  GoogleMapScreen({required this.onPlaceSelected});

  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late GoogleMapController mapController;
  LatLng? selectedPlace;
  String? selectedAddress;

  LatLng _center = const LatLng(32.794044, 34.989571);
  final loc.Location _location = loc.Location(); 
  final String apiKey = 'AIzaSyBxCWpxscWGJgWBJNujLD40Z1JOjGqWytA'; // Replace with your API key


  @override
  void initState() {
    super.initState();
    _requestLocationPermission(); // Request permissions during initialization
    _getUserLocation();
  }


  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (!status.isGranted) {
      // If permission is denied, show an alert
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Permission Denied"),
          content: const Text(
              "Location permission is required to use the map. Please enable it in settings."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }

  }

Future<void> _getUserLocation() async {
  try {
    final hasPermission = await _location.serviceEnabled() &&
        await _location.requestPermission() == loc.PermissionStatus.granted;

    if (!hasPermission) {
      return; // Exit if permission is not granted
    }

    final userLocation = await _location.getLocation();
    setState(() {
      _center = LatLng(userLocation.latitude!, userLocation.longitude!);
    });

    // Move the camera to the user's location
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLng(_center),
      );
    }
  } catch (e) {
    print('Error fetching location: $e');
  }
}

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_center != null) {
    mapController.animateCamera(
      CameraUpdate.newLatLng(_center),
    );
  }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          setState(() {
            selectedAddress = data['results'][0]['formatted_address'];
          });
        }
      } else {
        setState(() {
          selectedAddress = 'Failed to get address';
        });
      }
    } catch (e) {
      setState(() {
        selectedAddress = 'Error: $e';
      });
    }
  }

  void _onTap(LatLng position) async {
  setState(() {
    selectedPlace = position;
    selectedAddress = 'Loading...';
  });

  final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        setState(() {
          selectedAddress = data['results'][0]['formatted_address'];
        });
      } else {
        setState(() {
          selectedAddress = 'No address available';
        });
      }
    } else {
      setState(() {
        selectedAddress = 'Failed to fetch address from Google API';
      });
    }
  } catch (e) {
    setState(() {
      selectedAddress = 'Error: $e';
    });
  }
}

  Future<void> _searchAndNavigate(String searchQuery) async {
    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(searchQuery);
      if (locations.isNotEmpty) {
        geocoding.Location location = locations.first;
        LatLng target = LatLng(location.latitude, location.longitude);
        mapController.animateCamera(CameraUpdate.newLatLng(target));
        setState(() {
          selectedPlace = target;
          selectedAddress = searchQuery;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Map'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (selectedPlace != null && selectedAddress != null) {
                widget.onPlaceSelected(selectedPlace!, selectedAddress!);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 15.0,
            ),
            onTap: _onTap,
            markers: selectedPlace != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected-place'),
                      position: selectedPlace!,
                    ),
                  }
                : {},
          ),
          if (selectedAddress != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: Text(selectedAddress!),
              ),
            ),
            Positioned(
          top: 10,
          left: 15,
          right: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search here',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                _searchAndNavigate(value);
              },
            ),
          ),
        ),
        ],
      ),
    );
  }
}
