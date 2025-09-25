import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/responsive.dart';

class TeamFindCard extends StatefulWidget {
  final String name;
  final List<String> skills;
  final List<Map<String, String>> previousProjects; // [{title, url}]
  final String? linkedinProfile;
  final String whatsappNumber;
  final String? profilePicUrl;
  final bool showDelete;
  final VoidCallback? onDelete;
  final String? department;

  const TeamFindCard({
    super.key,
    required this.name,
    required this.skills,
    required this.previousProjects,
    required this.whatsappNumber,
    this.linkedinProfile,
    this.profilePicUrl,
    this.showDelete = false,
    this.onDelete,
    this.department,
  });

  @override
  State<TeamFindCard> createState() => _TeamFindCardState();
}

class _TeamFindCardState extends State<TeamFindCard> {
  bool showAllLinks = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: Responsive.space(context, size: Space.small),
        ),
        padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.small),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture (fixed width)
              SizedBox(
                width: Responsive.space(context, size: Space.xlarge) * 2,
                height: Responsive.space(context, size: Space.xlarge) * 2,
                child: ClipOval(
                  child:
                      (widget.profilePicUrl != null &&
                              widget.profilePicUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                            imageUrl: widget.profilePicUrl!,
                            width:
                                Responsive.space(context, size: Space.xlarge) *
                                2,
                            height:
                                Responsive.space(context, size: Space.xlarge) *
                                2,
                            fit: BoxFit.cover,
                            errorWidget:
                                (context, url, error) => Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: Responsive.space(
                                    context,
                                    size: Space.large,
                                  ),
                                ),
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          )
                          : CircleAvatar(
                            radius: Responsive.space(
                              context,
                              size: Space.xlarge,
                            ),
                            backgroundColor: Colors.black,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: Responsive.space(
                                context,
                                size: Space.large,
                              ),
                            ),
                          ),
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.medium)),
              // Main info column (only this is Expanded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.department != null &&
                            widget.department!.isNotEmpty &&
                            widget.department != 'عام' &&
                            widget.department!.toLowerCase() != 'general')
                          Padding(
                            padding: EdgeInsets.only(
                              right: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            child: Text(
                              '(${widget.department!})',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    if (widget.skills.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              widget.skills
                                  .map(
                                    (skill) => Container(
                                      margin: EdgeInsets.only(
                                        left: Responsive.space(
                                          context,
                                          size: Space.tiny,
                                        ),
                                      ),
                                      child: Chip(
                                        label: Text(
                                          skill,
                                          style: TextStyle(
                                            fontSize: Responsive.text(
                                              context,
                                              size: TextSize.small,
                                            ),
                                          ),
                                        ),
                                        backgroundColor: Colors.grey[100],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            Responsive.space(
                                              context,
                                              size: Space.large,
                                            ),
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: Responsive.space(
                                            context,
                                            size: Space.small,
                                          ),
                                          vertical: 0,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    if (widget.previousProjects.isNotEmpty) ...[
                      SizedBox(
                        height: Responsive.space(context, size: Space.tiny),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                showAllLinks = !showAllLinks;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerRight,
                            ),
                            icon: null,
                            label: Row(
                              children: [
                                Text('المشاريع السابقة'),
                                Icon(
                                  showAllLinks
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                          if (showAllLinks)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  widget.previousProjects
                                      .map(
                                        (proj) => Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: _buildProjectLink(
                                            context,
                                            proj,
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              // LinkedIn icon (fixed width)
              if (widget.linkedinProfile != null &&
                  widget.linkedinProfile!.isNotEmpty)
                SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: Icon(
                      FontAwesomeIcons.linkedin,
                      color: Color(0xFF0077B5),
                      size: Responsive.space(context, size: Space.large),
                    ),
                    tooltip: 'لينكدإن',
                    onPressed:
                        () => launchUrl(Uri.parse(widget.linkedinProfile!)),
                  ),
                ),
              // WhatsApp icon (fixed width)
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: Icon(
                    FontAwesomeIcons.whatsapp,
                    color: Color(0xff25D366),
                    size: Responsive.space(context, size: Space.large),
                  ),
                  tooltip: 'واتساب',
                  onPressed:
                      () => launchUrl(
                        Uri.parse('https://wa.me/+2${widget.whatsappNumber}'),
                      ),
                ),
              ),
              // Delete icon (fixed width)
              if (widget.showDelete)
                SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    tooltip: 'حذف',
                    onPressed: widget.onDelete,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectLink(BuildContext context, Map<String, String> proj) {
    return InkWell(
      onTap: () {
        final url = proj['url'] ?? '';
        if (url.isNotEmpty) {
          launchUrl(Uri.parse(url));
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FontAwesomeIcons.link, size: 14, color: Colors.grey),
          SizedBox(width: Responsive.space(context, size: Space.tiny)),
          Container(
            constraints: BoxConstraints(
              maxWidth: Responsive.width(context) * 0.18,
            ),
            child: Text(
              proj['title'] ?? '',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
