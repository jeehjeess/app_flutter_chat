import 'package:chat/screens/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chat/screens/text_composer.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';


import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ChatScreenState();
  }
}

class ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  User? _currentUser;
  FirebaseAuth auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();




  bool _isLoading = false;
  final CollectionReference _mensagens =
      FirebaseFirestore.instance.collection("mensagens");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser != null
            ? 'Olá, ${_currentUser?.displayName}'
            : "Chat App"),
        actions: <Widget>[
          _currentUser != null
              ? IconButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googleSignIn.signOut();
                    // _scaffoldKey.currentState?.showSnackBar(
                    //   SnackBar(content: Text("Logout"))
                    //);
                  },
                  icon: Icon(Icons.exit_to_app))
              : Container()
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: _mensagens.orderBy('time').snapshots(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return Center(child: CircularProgressIndicator());
                    default:
                      List<DocumentSnapshot> documents =
                          snapshot.data!.docs.reversed.toList();
                      return ListView.builder(
                          itemCount: documents.length,
                          reverse: true,
                          itemBuilder: (context, index) {
                            return ChatMessage(
                                documents[index],
                                documents[index].get("uid") ==
                                    _currentUser?.uid);
                          });
                  }
                }),
          ),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }

  void _sendMessage({String? text, XFile? imgFile}) async {
    final CollectionReference _mensagens =
        FirebaseFirestore.instance.collection("mensagens");
    User? user = await _getUser(context: context);
    Position position  = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);


    if (user == null) {
      const snackBar = SnackBar(
          content: Text("Não foi possível fazer o login"),
          backgroundColor: Colors.red);
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    Map<String, dynamic> data = {
      'time': Timestamp.now(),
      'url': "",
      'uid': user?.uid,
      'senderName': user?.displayName,
      "sendPhotoUrl": user?.photoURL,
      "localizacao": await GetAddressFromLatLong(position),
      "latitude": position.latitude,
      "longitude": position.longitude,
    };

    if (imgFile != null) {
      setState(() {
        _isLoading = true;
      });
      firebase_storage.UploadTask uploadTask;
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child("imgs")
          .child(DateTime.now().microsecondsSinceEpoch.toString());
      final metadados = firebase_storage.SettableMetadata(
          contentType: "image/jpeg",
          customMetadata: {"picked-file-path": imgFile.path});
      if (kIsWeb) {
        uploadTask = ref.putData(await imgFile.readAsBytes(), metadados);
      } else {
        uploadTask = ref.putFile(File(imgFile.path));
      }

      var taskSnapshot = await uploadTask;
      String imageUrl = "";
      imageUrl = await taskSnapshot.ref.getDownloadURL();
      setState(() {
        _isLoading = false;
      });
      data["url"] = imageUrl;
      print("url" + imageUrl);
    } else {
      data["text"] = text;
    }

    print(data);
    _mensagens.add(data);
    print("dado enviado para o Firebase");
  }

  Future<User?> _getUser({required BuildContext context}) async {
    User? user;
    if (_currentUser != null) return _currentUser;

    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      try {
        final UserCredential userCredential =
            await auth.signInWithPopup(authProvider);
        user = userCredential.user;
      } catch (e) {
        print(e);
      }
    } else {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        try {
          final UserCredential userCredential =
              await auth.signInWithCredential(credential);
          user = userCredential.user;
        } on FirebaseAuthException catch (e) {
          print(e);
        } catch (e) {
          print(e);
        }
      }
    }

    return user;
  }

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }


  Future<String> GetAddressFromLatLong(Position position)async {
    String Address = "Sem endereço";

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks != null && placemarks.length > 0) {
      print(placemarks);
      Placemark place = placemarks[0];
      Address =
      '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
      setState(() {});
    }
    return Address;
  }

}
