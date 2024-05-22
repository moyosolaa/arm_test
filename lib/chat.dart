import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class ChatScreen extends ConsumerWidget {
  final String groupId;
  final String groupName;
  final TextEditingController messageController = TextEditingController();

  ChatScreen({super.key, required this.groupId, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firestoreProvider);
    // final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Row(
          children: [
            CircleAvatar(
              child: Text(
                groupName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
              // backgroundImage: AssetImage('assets/profile_image.jpg'),
            ),
            const SizedBox(width: 10),
            Text(
              groupName,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onPressed: () {
              // TODO: Implement more options functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  firestore.collection('groups').doc(groupId).collection('messages').orderBy('timestamp').snapshots(),
              // stream: firestore.collection('messages').orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs.map((doc) {
                  return Message.fromJson(doc.data() as Map<String, dynamic>);
                }).toList();
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final currentUser = ref.read(firebaseAuthProvider).currentUser;
                    final isCurrentUser = messages[index].sender == currentUser?.email;
                    return Container(
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? const Color.fromARGB(255, 180, 240, 184)
                            : const Color.fromARGB(255, 163, 192, 232),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          isCurrentUser
                              ? const SizedBox.shrink()
                              : Align(
                                  alignment: Alignment.topCenter,
                                  child: CircleAvatar(
                                    child: Text(
                                      messages[index].sender.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                    // backgroundImage: AssetImage('assets/profile_image.jpg'),
                                  ),
                                ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                isCurrentUser
                                    ? const SizedBox.shrink()
                                    : Text(
                                        messages[index].sender,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Column(
                                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      messages[index].text,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                      textAlign: isCurrentUser ? TextAlign.right : TextAlign.left,
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        messages[index].timestamp.toDate().toString(),
                                        style: const TextStyle(
                                          color: Color.fromARGB(255, 51, 129, 55),
                                          fontSize: 12,
                                        ),
                                        textAlign: isCurrentUser ? TextAlign.right : TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    // TODO: Implement file attachment functionality
                  },
                ),
                // IconButton(
                //   icon: const Icon(Icons.camera_alt),
                //   onPressed: () {
                //     // TODO: Implement camera functionality
                //   },
                // ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final auth = ref.read(firebaseAuthProvider);
                    final user = auth.currentUser;
                    if (user != null) {
                      await firestore.collection('groups').doc(groupId).collection('messages').add({
                        'text': messageController.text,
                        'sender': user.email,
                        'timestamp': Timestamp.now(),
                      });
                      messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String sender;
  final String text;
  final Timestamp timestamp;

  Message({
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'],
      text: json['text'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
