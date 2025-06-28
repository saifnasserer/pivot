 import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/responsive.dart';

class UserSearchCard extends StatelessWidget {
  final UserProfile user;
  const UserSearchCard({super.key, required this.user});

  String getTitle() {
    if (user.role == 'Professor') return 'دكتور';
    if (user.role == 'miniProfessor') return 'م.دكتور';
    if (user.role == 'Engineer') return 'مهندس';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFFFD700);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: gold, width: 1.2),
      ),
      padding: EdgeInsets.symmetric(
        vertical: Responsive.space(context, size: Space.small) * 1.2,
        horizontal: Responsive.space(context, size: Space.medium),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: Responsive.space(context, size: Space.medium),
            backgroundColor: gold.withOpacity(0.15),
            backgroundImage: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(user.profileImageUrl!)
                : null,
            child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                ? Icon(Icons.person, color: gold, size: Responsive.space(context, size: Space.large))
                : null,
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  getTitle(),
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                  ),
                  textAlign: TextAlign.right,
                ),
                Text(
                  user.name,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.text(context, size: TextSize.medium) * 1.1,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
