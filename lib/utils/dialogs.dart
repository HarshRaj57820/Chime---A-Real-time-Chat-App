import 'package:flutter/material.dart';

class Dialogs{

  static showSnackBar(BuildContext context, String msg){
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        dismissDirection: DismissDirection.endToStart,
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500),), 
      behavior: SnackBarBehavior.floating, 
      backgroundColor: Colors.blueAccent.withOpacity(0.8),)
      );
  }

  static showProgressBar(BuildContext context){
    showDialog(context: context, builder: (_){
      return const Center(child: CircularProgressIndicator(strokeWidth: 2,),);
    });
  }

  
}