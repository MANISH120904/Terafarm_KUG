import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/app_services.dart';
import 'widgets/app_image.dart';

///
/// ForumPage: Top-level page with a TabBar for Groups and Channels.
///
class ForumPage extends StatefulWidget {
  const ForumPage({Key? key}) : super(key: key);

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Two tabs: Groups and Channels.
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeraChat'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Groups'), Tab(text: 'Channels')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [GroupsListView(), ChannelsListView()],
      ),
    );
  }
}

///
/// GroupsListView: Shows public groups and any private group the user is a member of.
/// Allows creating a new group (with public/private toggle).
///
class GroupsListView extends StatefulWidget {
  const GroupsListView({Key? key}) : super(key: key);

  @override
  State<GroupsListView> createState() => _GroupsListViewState();
}

class _GroupsListViewState extends State<GroupsListView> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescController = TextEditingController();
  File? _newGroupImage;
  bool _isPublic = true;
  final ImagePicker _picker = ImagePicker();

  void _deleteGroup(String groupId) async {
    final currentUserId = AppServices.auth.currentUser?.uid;
    final groupDoc =
        await AppServices.firestore.collection('groups').doc(groupId).get();
    final admins = groupDoc['admins'] as List<dynamic>? ?? [];
    if (currentUserId != null && admins.contains(currentUserId)) {
      await AppServices.firestore.collection('groups').doc(groupId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group deleted successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can delete this group.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter groups: show if public OR if user is a member.
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            AppServices.firestore
                .collection('groups')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final bool isPublic = data['isPublic'] ?? true;
                final members = data['members'] as List<dynamic>? ?? [];
                final currentUserId = AppServices.auth.currentUser?.uid;
                return isPublic ||
                    (currentUserId != null && members.contains(currentUserId));
              }).toList();

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final groupId = group.id;
              final groupData = group.data() as Map<String, dynamic>?;

              if (groupData == null) return const SizedBox.shrink();

              final groupName = groupData['name'] ?? 'No Name';
              final bool isPublic = groupData['isPublic'] ?? true;
              final members = groupData['members'] as List<dynamic>? ?? [];
              final currentUserId = AppServices.auth.currentUser?.uid;
              final bool isMember =
                  currentUserId != null && members.contains(currentUserId);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.group),
                ),
                title: Text(groupName),
                subtitle: Text(isPublic ? 'Public Group' : 'Private Group'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (!isMember && currentUserId != null) {
                          // For private groups, joining via link can be added.
                          await AppServices.firestore
                              .collection('groups')
                              .doc(groupId)
                              .update({
                                'members': FieldValue.arrayUnion([
                                  currentUserId,
                                ]),
                              });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMember ? Colors.grey : Colors.blue,
                      ),
                      child: Text(isMember ? 'Joined' : 'Join'),
                    ),
                    // Show "Manage" option if current user is admin/creator.
                    if (isMember &&
                        (groupData['admins'] as List<dynamic>? ?? []).contains(
                          currentUserId,
                        ))
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => GroupManagementPage(
                                    groupId: groupId,
                                    groupName: groupName,
                                  ),
                            ),
                          );
                        },
                      ),
                    if (isMember &&
                        (groupData['admins'] as List<dynamic>? ?? [])
                            .contains(currentUserId))
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteGroup(groupId),
                      ),
                  ],
                ),
                onTap: () {
                  if (isMember) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => GroupChatPage(
                              groupId: groupId,
                              groupName: groupName,
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please join the group first.'),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateGroupDialog() {
    // Use StatefulBuilder to locally update the public toggle.
    showDialog(
      context: context,
      builder: (context) {
        bool isPublicLocal = _isPublic;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Create Group'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickGroupImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            _newGroupImage != null
                                ? FileImage(_newGroupImage!)
                                : null,
                        child:
                            _newGroupImage == null
                                ? const Icon(Icons.camera_alt, size: 40)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _groupNameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                      ),
                    ),
                    TextField(
                      controller: _groupDescController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Public Group'),
                        Switch(
                          value: isPublicLocal,
                          onChanged: (val) {
                            setStateDialog(() {
                              isPublicLocal = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const Text(
                      'Public groups are visible to anyone. Private groups can only be joined via link.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearGroupCreationFields();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final groupName = _groupNameController.text.trim();
                    final groupDesc = _groupDescController.text.trim();
                    final currentUserId =
                        AppServices.auth.currentUser?.uid;
                    String profileUrl = "";

                    if (_newGroupImage != null) {
                      profileUrl = await _uploadGroupImage(_newGroupImage!);
                    }

                    if (groupName.isNotEmpty && currentUserId != null) {
                      try {
                        await AppServices.firestore
                            .collection('groups')
                            .add({
                              'name': groupName,
                              'description': groupDesc,
                              'profileUrl': profileUrl,
                              'isPublic': isPublicLocal,
                              'createdBy': currentUserId,
                              'members': [currentUserId],
                              'admins': [currentUserId],
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Group created successfully!'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating group: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Group name cannot be empty.'),
                        ),
                      );
                    }

                    _clearGroupCreationFields();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _clearGroupCreationFields() {
    _groupNameController.clear();
    _groupDescController.clear();
    setState(() {
      _newGroupImage = null;
      _isPublic = true;
    });
  }

  Future<void> _pickGroupImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _newGroupImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadGroupImage(File file) async {
    return AppServices.media.uploadFile(
      file: file,
      path: 'group_profiles/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }
}

///
/// ChannelsListView: Shows public channels and channels where user is already a member.
/// Supports creating a new channel with a public/private toggle and an optional connection to a group.
/// In channels, only admins can create new posts.
///
class ChannelsListView extends StatefulWidget {
  const ChannelsListView({Key? key}) : super(key: key);

  @override
  State<ChannelsListView> createState() => _ChannelsListViewState();
}

class _ChannelsListViewState extends State<ChannelsListView> {
  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _channelDescController = TextEditingController();
  final TextEditingController _groupIdController = TextEditingController();
  File? _newChannelImage;
  bool _isPublic = true;
  final ImagePicker _picker = ImagePicker();

  void _deleteChannel(String channelId) async {
    final currentUserId = AppServices.auth.currentUser?.uid;
    final channelDoc =
        await AppServices.firestore.collection('channels').doc(channelId).get();
    final admins = channelDoc['admins'] as List<dynamic>? ?? [];
    if (currentUserId != null && admins.contains(currentUserId)) {
      await AppServices.firestore.collection('channels').doc(channelId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Channel deleted successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can delete this channel.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter channels: show public channels OR channels where user is already a member.
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            AppServices.firestore
                .collection('channels')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final channels =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final bool isPublic = data['isPublic'] ?? true;
                final members = data['members'] as List<dynamic>? ?? [];
                final currentUserId = AppServices.auth.currentUser?.uid;
                return isPublic ||
                    (currentUserId != null && members.contains(currentUserId));
              }).toList();

          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              final channelId = channel.id;
              final channelData = channel.data() as Map<String, dynamic>?;

              if (channelData == null) return const SizedBox.shrink();

              final channelName = channelData['name'] ?? 'No Name';
              final bool isPublic = channelData['isPublic'] ?? true;
              final members = channelData['members'] as List<dynamic>? ?? [];
              final currentUserId = AppServices.auth.currentUser?.uid;
              final bool isMember =
                  currentUserId != null && members.contains(currentUserId);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.campaign),
                ),
                title: Text(channelName),
                subtitle: Text(isPublic ? 'Public Channel' : 'Private Channel'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (!isMember && currentUserId != null) {
                          await AppServices.firestore
                              .collection('channels')
                              .doc(channelId)
                              .update({
                                'members': FieldValue.arrayUnion([
                                  currentUserId,
                                ]),
                              });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMember ? Colors.grey : Colors.blue,
                      ),
                      child: Text(isMember ? 'Joined' : 'Join'),
                    ),
                    if (isMember &&
                        (channelData['admins'] as List<dynamic>? ?? [])
                            .contains(currentUserId))
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ChannelManagementPage(
                                    channelId: channelId,
                                    channelName: channelName,
                                  ),
                            ),
                          );
                        },
                      ),
                    if (isMember &&
                        (channelData['admins'] as List<dynamic>? ?? [])
                            .contains(currentUserId))
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteChannel(channelId),
                      ),
                  ],
                ),
                onTap: () {
                  if (isMember) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChannelChatPage(
                              channelId: channelId,
                              channelName: channelName,
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please join the channel first.'),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChannelDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateChannelDialog() {
    // Use StatefulBuilder to update the public toggle locally.
    showDialog(
      context: context,
      builder: (context) {
        bool isPublicLocal = _isPublic;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Create Channel'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickChannelImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            _newChannelImage != null
                                ? FileImage(_newChannelImage!)
                                : null,
                        child:
                            _newChannelImage == null
                                ? const Icon(Icons.camera_alt, size: 40)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _channelNameController,
                      decoration: const InputDecoration(
                        labelText: 'Channel Name',
                      ),
                    ),
                    TextField(
                      controller: _channelDescController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    TextField(
                      controller: _groupIdController,
                      decoration: const InputDecoration(
                        labelText: 'Connect to Group (optional)',
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Public Channel'),
                        Switch(
                          value: isPublicLocal,
                          onChanged: (val) {
                            setStateDialog(() {
                              isPublicLocal = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const Text(
                      'Public channels are visible to anyone. Private channels require a link to join.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearChannelCreationFields();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final channelName = _channelNameController.text.trim();
                    final channelDesc = _channelDescController.text.trim();
                    final groupId = _groupIdController.text.trim();
                    final currentUserId =
                        AppServices.auth.currentUser?.uid;
                    String profileUrl = "";

                    if (_newChannelImage != null) {
                      profileUrl = await _uploadChannelImage(_newChannelImage!);
                    }

                    if (channelName.isNotEmpty && currentUserId != null) {
                      try {
                        await AppServices.firestore
                            .collection('channels')
                            .add({
                              'name': channelName,
                              'description': channelDesc,
                              'profileUrl': profileUrl,
                              'isPublic': isPublicLocal,
                              'createdBy': currentUserId,
                              'members': [currentUserId],
                              'admins': [currentUserId],
                              'groupId': groupId.isNotEmpty ? groupId : null,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Channel created successfully!'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating channel: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Channel name cannot be empty.'),
                        ),
                      );
                    }

                    _clearChannelCreationFields();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _clearChannelCreationFields() {
    _channelNameController.clear();
    _channelDescController.clear();
    _groupIdController.clear();
    setState(() {
      _newChannelImage = null;
      _isPublic = true;
    });
  }

  Future<void> _pickChannelImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _newChannelImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadChannelImage(File file) async {
    return AppServices.media.uploadFile(
      file: file,
      path: 'channel_profiles/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }
}

///
/// GroupChatPage: Chat interface for groups (everyone can chat).
///
class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currentUserId = AppServices.auth.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          // Manage option (if user is admin/creator)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => GroupManagementPage(
                        groupId: widget.groupId,
                        groupName: widget.groupName,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildChatMessages(currentUserId)),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatMessages(String? currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          AppServices.firestore
              .collection('groups')
              .doc(widget.groupId)
              .collection('messages')
              .orderBy('sentAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final messages = snapshot.data!.docs;
        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data() as Map<String, dynamic>;
            final message = messageData['text'] ?? '';
            final senderId = messageData['senderId'] ?? 'Unknown';
            final imageUrl = messageData['imageUrl'] as String?;
            return FutureBuilder<DocumentSnapshot>(
              future:
                  AppServices.firestore
                      .collection('users')
                      .doc(senderId)
                      .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final userData =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final username = userData['username'] ?? 'Unknown User';
                final isCurrentUser = senderId == currentUserId;
                return Align(
                  alignment:
                      isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isCurrentUser
                              ? Colors.green.shade100
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isCurrentUser
                                    ? Colors.green.shade800
                                    : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 5),
                        imageUrl != null
                            ? AppImage(source: imageUrl, width: 200)
                            : Text(message),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attachment, color: Colors.deepPurple),
            onPressed: _pickAndSendImage,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: 'Enter message'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.deepPurple),
            onPressed: () async {
              final text = _messageController.text.trim();
              final currentUser = AppServices.auth.currentUser;
              if (text.isNotEmpty && currentUser != null) {
                await AppServices.firestore
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('messages')
                    .add({
                      'text': text,
                      'senderId': currentUser.uid,
                      'sentAt': FieldValue.serverTimestamp(),
                    });
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final currentUser = AppServices.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to send images')),
        );
      }
      return;
    }
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String downloadUrl = await _uploadFile(imageFile);
      await AppServices.firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
            'imageUrl': downloadUrl,
            'senderId': currentUser.uid,
            'sentAt': FieldValue.serverTimestamp(),
          });
    }
  }

  Future<String> _uploadFile(File file) async {
    return AppServices.media.uploadFile(
      file: file,
      path: 'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }
}

///
/// ChannelChatPage: Chat interface for channels.
/// - Only admins (from the channel’s "admins" list) may create posts.
/// - Posts are stored in a subcollection ("posts").
/// - If the channel is connected to a group (via "groupId"), each post displays a comment thread.
///
class ChannelChatPage extends StatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelChatPage({
    Key? key,
    required this.channelId,
    required this.channelName,
  }) : super(key: key);

  @override
  State<ChannelChatPage> createState() => _ChannelChatPageState();
}

class _ChannelChatPageState extends State<ChannelChatPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _postController = TextEditingController();
  bool isAdmin = false;
  String? connectedGroupId;

  @override
  void initState() {
    super.initState();
    _loadChannelData();
  }

  Future<void> _loadChannelData() async {
    final channelDoc =
        await AppServices.firestore
            .collection('channels')
            .doc(widget.channelId)
            .get();
    final data = channelDoc.data() ?? {};
    final List<dynamic> admins = data['admins'] ?? [];
    final currentUserId = AppServices.auth.currentUser?.uid;
    setState(() {
      isAdmin = currentUserId != null && admins.contains(currentUserId);
      connectedGroupId = data['groupId']; // optional connection to a group
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ChannelManagementPage(
                          channelId: widget.channelId,
                          channelName: widget.channelName,
                        ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  AppServices.firestore
                      .collection('channels')
                      .doc(widget.channelId)
                      .collection('posts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final postDoc = posts[index];
                    return ChannelPost(
                      postDoc: postDoc,
                      channelId: widget.channelId,
                      connectedGroupId: connectedGroupId,
                    );
                  },
                );
              },
            ),
          ),
          isAdmin
              ? _buildPostInput()
              : Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  "Only admins can create posts. You can comment on posts below.",
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPostInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attachment, color: Colors.deepPurple),
            onPressed: _pickAndSendImage,
          ),
          Expanded(
            child: TextField(
              controller: _postController,
              decoration: const InputDecoration(hintText: 'Enter post'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.deepPurple),
            onPressed: () async {
              final text = _postController.text.trim();
              final currentUser = AppServices.auth.currentUser;
              if (text.isNotEmpty && currentUser != null && isAdmin) {
                await AppServices.firestore
                    .collection('channels')
                    .doc(widget.channelId)
                    .collection('posts')
                    .add({
                      'text': text,
                      'senderId': currentUser.uid,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                _postController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final currentUser = AppServices.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to post images')),
        );
      }
      return;
    }
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null && isAdmin) {
      File imageFile = File(pickedFile.path);
      String downloadUrl = await _uploadFile(imageFile);
      await AppServices.firestore
          .collection('channels')
          .doc(widget.channelId)
          .collection('posts')
          .add({
            'imageUrl': downloadUrl,
            'senderId': currentUser.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
    }
  }

  Future<String> _uploadFile(File file) async {
    return AppServices.media.uploadFile(
      file: file,
      path: 'channel_posts/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }
}

///
/// ChannelPost: Displays a channel post and (if connected to a group) its comment thread.
/// All users can add comments.
///
class ChannelPost extends StatefulWidget {
  final QueryDocumentSnapshot postDoc;
  final String channelId;
  final String? connectedGroupId;

  const ChannelPost({
    Key? key,
    required this.postDoc,
    required this.channelId,
    required this.connectedGroupId,
  }) : super(key: key);

  @override
  _ChannelPostState createState() => _ChannelPostState();
}

class _ChannelPostState extends State<ChannelPost> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final postData = widget.postDoc.data() as Map<String, dynamic>;
    final text = postData['text'] ?? '';
    final senderId = postData['senderId'] ?? '';
    final imageUrl = postData['imageUrl'] as String?;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future:
                  AppServices.firestore
                      .collection('users')
                      .doc(senderId)
                      .get(),
              builder: (context, snapshot) {
                String username = 'Unknown';
                if (snapshot.hasData) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  username = userData['username'] ?? 'Unknown';
                }
                return Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 5),
            text.isNotEmpty ? Text(text) : Container(),
            imageUrl != null
                ? AppImage(source: imageUrl, width: 200)
                : Container(),
            const SizedBox(height: 10),
            widget.connectedGroupId != null
                ? _buildCommentsSection()
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream:
              AppServices.firestore
                  .collection('channels')
                  .doc(widget.channelId)
                  .collection('posts')
                  .doc(widget.postDoc.id)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final comments = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final commentData =
                    comments[index].data() as Map<String, dynamic>;
                final commentText = commentData['text'] ?? '';
                final commentSenderId = commentData['senderId'] ?? '';
                return FutureBuilder<DocumentSnapshot>(
                  future:
                      AppServices.firestore
                          .collection('users')
                          .doc(commentSenderId)
                          .get(),
                  builder: (context, snapshot) {
                    String commenterName = 'Unknown';
                    if (snapshot.hasData) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      commenterName = data['username'] ?? 'Unknown';
                    }
                    return ListTile(
                      title: Text(
                        commenterName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        commentText,
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(hintText: 'Add a comment'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.deepPurple),
              onPressed: _addComment,
            ),
          ],
        ),
      ],
    );
  }

  void _addComment() async {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      final currentUser = AppServices.auth.currentUser;
      if (currentUser != null) {
        await AppServices.firestore
            .collection('channels')
            .doc(widget.channelId)
            .collection('posts')
            .doc(widget.postDoc.id)
            .collection('comments')
            .add({
              'text': text,
              'senderId': currentUser.uid,
              'createdAt': FieldValue.serverTimestamp(),
            });
        _commentController.clear();
      }
    }
  }
}

///
/// GroupManagementPage: Allows a group admin/creator to add members by user ID and edit group details.
///
class GroupManagementPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupManagementPage({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<GroupManagementPage> createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  final TextEditingController _userIdController = TextEditingController();

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add User by ID'),
          content: TextField(
            controller: _userIdController,
            decoration: const InputDecoration(labelText: 'Enter User ID'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _userIdController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUserId = _userIdController.text.trim();
                if (newUserId.isNotEmpty) {
                  await AppServices.firestore
                      .collection('groups')
                      .doc(widget.groupId)
                      .update({
                        'members': FieldValue.arrayUnion([newUserId]),
                      });
                }
                _userIdController.clear();
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return EditGroupDialog(groupId: widget.groupId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage: ${widget.groupName}')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            AppServices.firestore
                .collection('groups')
                .doc(widget.groupId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groupData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final List<dynamic> members =
              groupData['members'] as List<dynamic>? ?? [];
          final List<dynamic> admins =
              groupData['admins'] as List<dynamic>? ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('Group: ${groupData['name'] ?? 'No Name'}'),
                subtitle: Text(
                  groupData['isPublic'] == true
                      ? 'Public Group'
                      : 'Private Group',
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Add User'),
                trailing: const Icon(Icons.person_add),
                onTap: _showAddUserDialog,
              ),
              ListTile(
                title: const Text('Edit Group'),
                trailing: const Icon(Icons.edit),
                onTap: _showEditGroupDialog,
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Members:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final memberId = members[index].toString();
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(memberId),
                      trailing:
                          admins.contains(memberId)
                              ? const Text('Admin')
                              : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

///
/// EditGroupDialog: Allows editing group details and toggling public/private.
///
class EditGroupDialog extends StatefulWidget {
  final String groupId;
  const EditGroupDialog({Key? key, required this.groupId}) : super(key: key);

  @override
  State<EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<EditGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isPublic = true;
  File? _newImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final doc =
        await AppServices.firestore
            .collection('groups')
            .doc(widget.groupId)
            .get();
    final data = doc.data() ?? {};
    _nameController.text = data['name'] ?? '';
    _descController.text = data['description'] ?? '';
    setState(() {
      _isPublic = data['isPublic'] ?? true;
    });
  }

  Future<String> _uploadImage(File file) async {
    return AppServices.media.uploadFile(
      file: file,
      path:
          'group_profiles/${widget.groupId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  void _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _newImage = File(pickedFile.path);
      });
    }
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });
    String? imageUrl;
    if (_newImage != null) {
      imageUrl = await _uploadImage(_newImage!);
    }
    await AppServices.firestore
        .collection('groups')
        .doc(widget.groupId)
        .update({
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'isPublic': _isPublic,
          if (imageUrl != null) 'profileUrl': imageUrl,
        });
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Group'),
      content:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            _newImage != null ? FileImage(_newImage!) : null,
                        child:
                            _newImage == null
                                ? const Icon(Icons.camera_alt, size: 40)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                      ),
                    ),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Public Group'),
                        Switch(
                          value: _isPublic,
                          onChanged: (val) {
                            setState(() {
                              _isPublic = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveChanges, child: const Text('Save')),
      ],
    );
  }
}

///
/// ChannelManagementPage: Allows a channel admin/creator to add members by user ID and edit channel details.
///
class ChannelManagementPage extends StatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelManagementPage({
    Key? key,
    required this.channelId,
    required this.channelName,
  }) : super(key: key);

  @override
  State<ChannelManagementPage> createState() => _ChannelManagementPageState();
}

class _ChannelManagementPageState extends State<ChannelManagementPage> {
  final TextEditingController _userIdController = TextEditingController();

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add User by ID'),
          content: TextField(
            controller: _userIdController,
            decoration: const InputDecoration(labelText: 'Enter User ID'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _userIdController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUserId = _userIdController.text.trim();
                if (newUserId.isNotEmpty) {
                  await AppServices.firestore
                      .collection('channels')
                      .doc(widget.channelId)
                      .update({
                        'members': FieldValue.arrayUnion([newUserId]),
                      });
                }
                _userIdController.clear();
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditChannelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return EditChannelDialog(channelId: widget.channelId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage: ${widget.channelName}')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            AppServices.firestore
                .collection('channels')
                .doc(widget.channelId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final channelData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final List<dynamic> members =
              channelData['members'] as List<dynamic>? ?? [];
          final List<dynamic> admins =
              channelData['admins'] as List<dynamic>? ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('Channel: ${channelData['name'] ?? 'No Name'}'),
                subtitle: Text(
                  channelData['isPublic'] == true
                      ? 'Public Channel'
                      : 'Private Channel',
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Add User'),
                trailing: const Icon(Icons.person_add),
                onTap: _showAddUserDialog,
              ),
              ListTile(
                title: const Text('Edit Channel'),
                trailing: const Icon(Icons.edit),
                onTap: _showEditChannelDialog,
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Members:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final memberId = members[index].toString();
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(memberId),
                      trailing:
                          admins.contains(memberId)
                              ? const Text('Admin')
                              : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

///
/// EditChannelDialog: Allows editing channel details and toggling public/private.
///
class EditChannelDialog extends StatefulWidget {
  final String channelId;
  const EditChannelDialog({Key? key, required this.channelId})
    : super(key: key);

  @override
  State<EditChannelDialog> createState() => _EditChannelDialogState();
}

class _EditChannelDialogState extends State<EditChannelDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isPublic = true;
  File? _newImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final doc =
        await AppServices.firestore
            .collection('channels')
            .doc(widget.channelId)
            .get();
    final data = doc.data() ?? {};
    _nameController.text = data['name'] ?? '';
    _descController.text = data['description'] ?? '';
    setState(() {
      _isPublic = data['isPublic'] ?? true;
    });
  }

  Future<String> _uploadImage(File file) async {
    return AppServices.media.uploadFile(
      file: file,
      path:
          'channel_profiles/${widget.channelId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  void _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _newImage = File(pickedFile.path);
      });
    }
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });
    String? imageUrl;
    if (_newImage != null) {
      imageUrl = await _uploadImage(_newImage!);
    }
    await AppServices.firestore
        .collection('channels')
        .doc(widget.channelId)
        .update({
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'isPublic': _isPublic,
          if (imageUrl != null) 'profileUrl': imageUrl,
        });
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Channel'),
      content:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            _newImage != null ? FileImage(_newImage!) : null,
                        child:
                            _newImage == null
                                ? const Icon(Icons.camera_alt, size: 40)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Channel Name',
                      ),
                    ),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Public Channel'),
                        Switch(
                          value: _isPublic,
                          onChanged: (val) {
                            setState(() {
                              _isPublic = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveChanges, child: const Text('Save')),
      ],
    );
  }
}