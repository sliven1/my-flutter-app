import 'package:flutter/material.dart';
import 'package:p7/components/my_driver_tile.dart';
import 'package:p7/pages/find_tutor_page.dart';
import 'package:p7/pages/home_page.dart';
import 'package:p7/pages/profile_page.dart';
import 'package:p7/pages/setting_page.dart';
import 'package:p7/pages/song_page.dart';
import 'package:p7/pages/weather_page.dart';

import '../service/auth.dart';
class MyDrawer extends StatelessWidget {
  MyDrawer({super.key});

  final _auth = Auth();

  void logout(){
    _auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),

      child: Column(
        children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 50),
          child: GestureDetector(
            onTap: (){
              Navigator.pop(context);

            },

          child: Image.asset('assets/icon/Icon.png',
            width: 150,
            height: 150,
          ),
      ),


          ),
          const SizedBox(height: 10),

          MyDrawerTile(
            title: "P r o f i l e",
            iconData: Icons.person,
            onTap: (){
              Navigator.pop(context);

              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ProfilePage(uid: _auth.getCurrentUid())),
              );
            },
          ),

          MyDrawerTile(
            title: "C h a t s",
            iconData: Icons.chat,
            onTap: (){
              Navigator.pop(context);
            },
          ),

          MyDrawerTile(
            title: "S e a r c h",
            iconData: Icons.person_search,
            onTap: (){
              Navigator.pop(context);

              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => FindTutorPage()
              ),
              );
            },
          ),

          MyDrawerTile(
            title: "S e t t i n g s",
            iconData: Icons.settings,
            onTap: (){
              Navigator.pop(context);

              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingPage()
              ),
              );
            },
          ),

          const Spacer(),

          MyDrawerTile(
            title: "L o g o u t",
            iconData: Icons.logout_sharp,
            onTap: logout,
          ),

        ],
      ),
      ),
    ),
    );
  }
}