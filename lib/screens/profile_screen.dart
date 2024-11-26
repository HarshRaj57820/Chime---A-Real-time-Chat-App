import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chime/model/user_model.dart';
import 'package:chime/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../api/apis.dart';
import '../main.dart';
import '../utils/dialogs.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.user, super.key});
  final UserModel user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // appbar
        appBar: AppBar(
          title: const Text("Profile Screen"),
        ),

        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: mq.width,
                    height: mq.height * 0.03,
                  ),
                  Stack(
                    children: [
                      //profile picture
                      _image != null
                          ?

                          //local image
                          ClipRRect(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(mq.height * .1)),
                              child: Image.file(File(_image!),
                                  width: mq.height * .2,
                                  height: mq.height * .2,
                                  fit: BoxFit.cover))
                          :
                          //image from server
                          ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(mq.height * .7),
                              child: CachedNetworkImage(
                                fit: BoxFit.fill,
                                height: mq.height * 0.23,
                                width: mq.width * 0.5,
                                imageUrl: widget.user.image,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  CupertinoIcons.person,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                      // edit image icon
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: MaterialButton(
                          onPressed: () {
                            _showBottomSheet();
                          },
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: const Icon(
                            Icons.edit,
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    width: mq.width,
                    height: mq.height * 0.03,
                  ),
                  // user email
                  Text(
                    widget.user.email,
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  SizedBox(
                    width: mq.width,
                    height: mq.height * 0.03,
                  ),

                  // upating name of user
                  TextFormField(
                    onSaved: (newValue) =>
                        Apis.currentUser.name = newValue ?? '',
                    validator: (value) => value != null && value.isNotEmpty
                        ? null
                        : "Required Fields",
                    initialValue: widget.user.name,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        hintText: "eg. Aman Arora",
                        prefixIcon: const Icon(CupertinoIcons.person),
                        label: const Text("Name")),
                  ),
                  SizedBox(
                    width: mq.width,
                    height: mq.height * 0.03,
                  ),

                  // upating about info of user
                  TextFormField(
                    onSaved: (newValue) =>
                        Apis.currentUser.about = newValue ?? '',
                    validator: (value) => value != null && value.isNotEmpty
                        ? null
                        : "Required Fields",
                    initialValue: widget.user.about,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        hintText: "Hey, I am using Chime",
                        prefixIcon: const Icon(CupertinoIcons.info),
                        label: const Text("about")),
                  ),
                  SizedBox(
                    width: mq.width,
                    height: mq.height * 0.03,
                  ),
                  // update button
                  ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          minimumSize: Size(mq.width * 0.4, mq.height * 0.06),
                          shape: const StadiumBorder()),
                      onPressed: () {
                        // validating formstate
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                        }
                        Apis.updateUserInfo().then((value) {
                          Dialogs.showSnackBar(context, "Profile Updated Successfully");
                          Navigator.pop(context);
                        });
                      },
                      icon: const Icon(
                        Icons.download_done,
                        size: 32,
                      ),
                      label: const Text(
                        "Update",
                        style: TextStyle(fontSize: 20),
                      ))
                ],
              ),
            ),
          ),
        ),

        // add logout button
        floatingActionButton: Padding(
          padding:
              EdgeInsets.only(bottom: mq.height * .02, right: mq.width * 0.02),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.amber,
            shape: const StadiumBorder(),
            onPressed: () async {

              await Apis.updateOnlineStatus(false);

              await Apis.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value){
                // for moving to homescreen
                Navigator.pop(context);
                // replacing homescreen with loginscreen
                Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
                });
              });
              

              Apis.auth = FirebaseAuth.instance;
             
            },
            icon: const Icon(Icons.logout),
            label: const Text(
              "logout",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  // bottom sheet for picking a profile picture for user
  void _showBottomSheet() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            padding:
                EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
            children: [
              //pick profile picture label
              const Text('Pick Profile Picture',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),

              //for adding some space
              SizedBox(height: mq.height * .02),

              //buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //pick from gallery button
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          fixedSize: Size(mq.width * .3, mq.height * .15)),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // Pick an image
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 80);
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() {
                            _image = image.path;
                            log(_image!);
                          });

                          Apis.updateProfilePicture(File(_image!));

                          // for hiding bottom sheet
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      child: Image.asset('assets/images/add_image.png')),

                  //take picture from camera button
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          fixedSize: Size(mq.width * .3, mq.height * .15)),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // Pick an image
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 80);
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() {
                            _image = image.path;
                          });

                          Apis.updateProfilePicture(File(_image!));

                          // for hiding bottom sheet
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      child: Image.asset('assets/images/camera.png')),
                ],
              )
            ],
          );
        });
  }
}
