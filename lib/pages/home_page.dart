// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:p7/components/my_drawer.dart';
import 'package:p7/components/user_tile.dart';
import 'package:p7/service/auth.dart';
import 'package:p7/service/chat_service.dart';
import 'chat_page.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final ChatService _chatService = ChatService();
  final Auth _auth = Auth();

  String getCurrentUser(){
    return _auth.getCurrentUid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: MyDrawer(),
      appBar: AppBar(
        centerTitle: true,
        title: Text("C H A T S"),
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList(){
    return StreamBuilder(
        stream: _chatService.getUsersStreamExcludingBlocked(),
        builder: (context, snapshot){

          if (snapshot.hasError){
            return const Text("Error");
          }

          if (snapshot.connectionState == ConnectionState.waiting){
            return const Text("Loading..");
          }

          return ListView(
            children: snapshot.data!.map<Widget>((userData) => _buildUserListItem(
                userData, context)).toList(),
          );
        },
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> data, BuildContext context) {
    final avatarUrl = data['avatarUrl'] as String?;
    if (data['uid'] != _auth.getCurrentUid()){
      return UserTile(
        text: data[("username")],
        avatarUrl: avatarUrl,
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) =>
                  ChatPage(
                    receiverUsername: data["username"],
                    receiverID: data['uid'],
                  ),
              ));
        },
      );
    }else{
      return Container();
    }
  }
}