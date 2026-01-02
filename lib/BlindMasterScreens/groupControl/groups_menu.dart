import 'dart:convert';

import 'package:blind_master/BlindMasterScreens/groupControl/create_group_dialog.dart';
import 'package:blind_master/BlindMasterScreens/groupControl/group_screen.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:flutter/material.dart';

class GroupsMenu extends StatefulWidget {
  const GroupsMenu({super.key});

  @override
  State<GroupsMenu> createState() => _GroupsMenuState();
}

class _GroupsMenuState extends State<GroupsMenu> {
  List<Map<String, dynamic>> groups = [];
  Widget? groupList;
  
  @override
  void initState() {
    super.initState();
    getGroups();
  }

  Future getGroups() async {
    await Future.delayed(Duration.zero); // Ensure async behavior
    
    try {
      final response = await secureGet('group_list');

      if (response != null && response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['groups'] != null) {
          groups = List<Map<String, dynamic>>.from(body['groups']);
        } else {
          groups = [];
        }
      } else {
        groups = [];
      }
    } catch (e) {
      print("Error fetching groups: $e");
      groups = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading groups: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() {
      groupList = RefreshIndicator(
        onRefresh: getGroups,
        child: groups.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: Text(
                      "No groups found...\nAdd one using the '+' button",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, i) {
                  final group = groups[i];
                  return Dismissible(
                    key: Key(group['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Group'),
                          content: const Text('Are you sure you want to delete this group?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) async {
                      try {
                        final response = await securePost(
                          {'groupId': group['id']},
                          'delete_group'
                        );

                        if (response != null && response.statusCode == 204) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Group "${group['name']}" deleted successfully'),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to delete group'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting group: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                      
                      // Always refresh the list
                      getGroups();
                    },
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.window_rounded),
                        title: Text(group['name']),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupScreen(
                                groupId: group['id'],
                                groupName: group['name'],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }

  void addGroup() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CreateGroupDialog();
      }
    ).then((_) { getGroups(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: groupList ?? const Center(child: CircularProgressIndicator()),
      floatingActionButton: Container(
        padding: EdgeInsets.all(25),
        child: FloatingActionButton(
          onPressed: addGroup,
          foregroundColor: Theme.of(context).highlightColor,
          backgroundColor: Theme.of(context).primaryColorDark,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}