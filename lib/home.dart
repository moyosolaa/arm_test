import 'package:arm_test/chat.dart';
import 'package:arm_test/login.dart';
import 'package:arm_test/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class HomeScreen extends ConsumerWidget {
  final TextEditingController groupNameController = TextEditingController();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsyncValue = ref.watch(groupsStreamProvider);
    final auth = ref.read(firebaseAuthProvider);
    NotificationService ns = NotificationService();
    ns.init();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text(
          'Group Chats',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () => _showAddGroupDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () async {
              await auth.signOut().then(
                    (value) => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    ),
                  );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: groupsAsyncValue.when(
        data: (snapshot) {
          final groups = snapshot.docs;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: groups.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Groups Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the plus sign to add a new group',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return Dismissible(
                        key: Key(group.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) => _deleteGroup(group.id, context, ref),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                group['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(groupId: group.id, groupName: group['name']),
                                ),
                              ),
                              tileColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  group['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(groupId: group.id, groupName: group['name']),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Group'),
          content: TextField(
            controller: groupNameController,
            decoration: const InputDecoration(hintText: 'Enter group name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _addGroup(context, ref),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addGroup(BuildContext context, WidgetRef ref) {
    final firestore = ref.read(firestoreProvider);
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;

    if (user != null && groupNameController.text.isNotEmpty) {
      firestore.collection('groups').add({
        'name': groupNameController.text,
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
      }).then((_) {
        groupNameController.clear();
        Navigator.pop(context);
      });
    }
  }

  void _deleteGroup(String groupId, BuildContext context, WidgetRef ref) {
    final firestore = ref.read(firestoreProvider);
    firestore.collection('groups').doc(groupId).delete();
  }
}
