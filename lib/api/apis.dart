import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:chime/model/message_model.dart';
import 'package:chime/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Apis {
  // instance for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // instance for firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // instance for firestore database
  static FirebaseStorage storage = FirebaseStorage.instance;

  // getter method for current user
  static User get user => auth.currentUser!;

  // current user information storage variable
  static late UserModel currentUser;

  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // for checking if user already exists
  static Future<bool> userAlreadyExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  // for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((value) {
      if (value != null) {
        currentUser.pushToken = value;
        log('Push Token: $value');
      }
    });

  }

  // get current user information
  static Future<void> currentUserInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        currentUser = UserModel.fromJson(user.data()!);
        await getFirebaseMessagingToken();

        //for setting user status to active
        updateOnlineStatus(true);
        // log('My Data: ${user.data()}');
      } else {
        await createUser().then((value) => currentUserInfo());
      }
    });
  }

  // for creating new user
  static Future<void> createUser() async {
    // setting time for every user creation
    final time = DateTime.now().millisecondsSinceEpoch;
    final newUser = UserModel(
        image: user.photoURL.toString(),
        about: "Hey, I am using Chime",
        name: user.displayName.toString(),
        createdAt: time.toString(),
        isOnline: user.isAnonymous,
        id: user.uid,
        lastActive: time.toString(),
        email: user.email.toString(),
        pushToken: "");
    await firestore.collection('users').doc(user.uid).set(newUser.toJson());
  }

  // for getting all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    log('\nUserIds: $userIds');

    return firestore
        .collection('users')
        .where('id',
            whereIn: userIds.isEmpty
                ? ['']
                : userIds) //because empty list throws an error
        // .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // updating user information
  static Future<void> updateUserInfo() async {
    await firestore
        .collection('users')
        .doc(currentUser.id)
        .update({'name': currentUser.name, 'about': currentUser.about});
  }

  // storing and updating user's profile picture in firebase
  static Future<void> updateProfilePicture(File file) async {
    // extracting image type
    final String ext = file.path.split('.').last;
    // log("message: $ext");

    // creating folder fo storing images data
    final Reference ref =
        // storage.ref('profile_pictures/${currentUser.id}').child(file.path);
        storage.ref().child('profile_pictures/${currentUser.id}.$ext');

    await ref.putFile(file, SettableMetadata(contentType: "images/$ext")).then(
      (p0) {
        // log("content: $p0");
        // log('\n data transferred: ${p0.bytesTransferred / 1000}');
      },
    );
    // downloading image url
    final String imageUrl = await ref.getDownloadURL();
    // updating imageurl in firestore database as well
    await firestore
        .collection('users')
        .doc(currentUser.id)
        .update({"image": imageUrl});
  }

  /// ************ChatScreen related APIS ///////////
  // chats -> getConversationId -> messages -> time -> messageModel data

  // getting conversation Id for the document name
  static String getConversationId(String id) {
    return user.uid.hashCode <= id.hashCode
        ? "${user.uid}_$id"
        : "${id}_${user.uid}";
  }

  // for getting messages from cloud firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      UserModel secUser) {
    // log("Attempting to fetch messages from Firestore path: chats/${getConversationId(secUser.id)}/messages");
    // log("Using orderBy: 'sent', descending: true");
    // log("Listening to snapshots...");
    firestore
        .collection('chats/${getConversationId(secUser.id)}/messages')
        .orderBy("sent", descending: true)
        .snapshots()
        .listen((snapshot) {
      // log("Received snapshot with size: ${snapshot.size}");
    });

    return firestore
        .collection('chats/${getConversationId(secUser.id)}/messages/')
        .orderBy("sent", descending: true)
        .snapshots();
  }

  // sending user message to firestore
  static Future<void> sendMessage(
      UserModel secUser, String msg, Type type) async {
    // creating document id for messsages
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final MessageModel message = MessageModel(
        toId: secUser.id,
        read: "",
        message: msg,
        type: type,
        sent: time,
        fromId: user.uid);

    final ref = firestore
        .collection('chats/${getConversationId(secUser.id)}/messages/');
    // posting data to firestore
    await ref.doc(time).set(message.toJson()).then((_) {
      log("Message sent succesfully");
    }).catchError((error) {
      log("Message contains error : $error");
    });
  }

  // for adding an chat user for our conversation
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    log('data: ${data.docs}');

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exists

      log('user exists: ${data.docs.first.data()}');

      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      //user doesn't exists

      return false;
    }
  }

  // for getting id's of known users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
  log("My users : ${firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots().toString()}");
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  // for adding an user to my user when first message is send
  static Future<void> sendFirstMessage(
      UserModel secUser, String msg, Type type) async {
    await firestore
        .collection('users')
        .doc(secUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(secUser, msg, type));
  }

  // updating read status in message model
  static Future<void> updateMessageRead(MessageModel message) async {
    firestore
        .collection("chats/${getConversationId(message.fromId)}/messages")
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch});
  }

// fetching user's conversation last message
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      UserModel secUser) {
    return firestore
        .collection("chats/${getConversationId(secUser.id)}/messages/")
        .orderBy("sent", descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<void> sendImageMessage(UserModel secUser, File file) async {
    final String ext = file.path.split('.').last;

    // creating folder fo storing images data
    final Reference ref = storage.ref().child(
        'images/${getConversationId(secUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref.putFile(file, SettableMetadata(contentType: "images/$ext")).then(
      (p0) {
        // log("content: $p0");
        log('\n data transferred: ${p0.bytesTransferred / 1000} kb');
      },
    );
    // downloading image url
    final String imageUrl = await ref.getDownloadURL();
    log("Image Url : $imageUrl");
    // updating imageurl in firestore database as well
    await sendMessage(secUser, imageUrl, Type.image);
  }

// for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      UserModel secUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: secUser.id)
        .snapshots();
  }

  static Future<void> updateOnlineStatus(bool isOnline) async {
    return firestore.collection('users').doc(user.uid).update({
      "is_online": isOnline,
      "last_active": DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': currentUser.pushToken,
    });
  }

  // delete message
  static Future<void> deleteMessage(MessageModel message) async {
    await firestore
        .collection('chats/${getConversationId(message.toId)}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.message).delete();
    }
  }

  //update message
  static Future<void> updateMessage(
      MessageModel message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationId(message.toId)}/messages/')
        .doc(message.sent)
        .update({'message': updatedMsg});
  }
}
