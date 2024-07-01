import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _messageController= TextEditingController();

  void _submitMessage()async {
    final enteredMessage=_messageController.text;
    if(enteredMessage.trim().isEmpty){
      return;
    }
    FocusScope.of(context).unfocus();
    _messageController.clear();

    final user=FirebaseAuth.instance.currentUser!;
    final userData=await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    FirebaseFirestore.instance.collection('chat').add({
      'text':enteredMessage,
      'createdAt':Timestamp.now(),
      'userId':user.uid,
      'userName':userData.data()!['username'],
      'userImage':userData.data()!['imageUrl']
    });


  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              enableSuggestions: true,
              autocorrect: true,
              decoration: const InputDecoration(label:Text( "Send a message..")),
            ),
          ),
          IconButton(onPressed: _submitMessage, color: Theme.of(context).colorScheme.primary,icon: const Icon(Icons.send)),
        ],
      ),
    );
  }
}
