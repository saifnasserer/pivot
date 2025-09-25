import 'package:flutter/material.dart';
import 'package:pivot/models/comment_data.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:provider/provider.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:lottie/lottie.dart';

class CommentTile extends StatefulWidget {
  final CommentData comment;
  final List<CommentData> allComments;
  final AnnouncementProvider provider;
  final String announcementId;
  final String userId;
  final bool canEdit;
  final bool isOwnComment;
  final bool isReply;
  final TextEditingController? editController;
  final Function(String, TextEditingController) onEditStart;
  final bool isEditing;
  final bool isSavingEdit;
  final Function(String, String) onEditSave;
  final Function() onEditCancel;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
  final String userRole;
  final Function(String, String) onReply;
  final int nestingLevel;

  const CommentTile({
    super.key,
    required this.comment,
    required this.allComments,
    required this.provider,
    required this.announcementId,
    required this.userId,
    required this.canEdit,
    required this.isOwnComment,
    required this.isReply,
    this.editController,
    required this.onEditStart,
    required this.isEditing,
    required this.isSavingEdit,
    required this.onEditSave,
    required this.onEditCancel,
    this.isExpanded = false,
    this.onToggleExpanded,
    required this.userRole,
    required this.onReply,
    this.nestingLevel = 0,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile>
    with AutomaticKeepAliveClientMixin {
  late bool isLiked;
  late int likeCount;
  bool showEdit = false;
  bool _isExpanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    isLiked = widget.comment.likes.contains(widget.userId);
    likeCount = widget.comment.likes.length;
    _isExpanded = widget.isExpanded;
  }

  void handleLike() async {
    setState(() {
      final wasLiked = isLiked;
      isLiked = !wasLiked;
      likeCount += wasLiked ? -1 : 1;
    });
    await widget.provider.likeComment(
      widget.announcementId,
      widget.comment.id,
      widget.userId,
    );
  }

  void handleToggleReplies() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onToggleExpanded?.call();
  }

  // Replace _showOptions with a bottom sheet action menu
  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.space(context, size: Space.large)),
        ),
      ),
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.edit, color: Colors.blue),
                    title: Text('تعديل'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        widget.onEditStart(
                          widget.comment.id,
                          TextEditingController(text: widget.comment.content),
                        );
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('حذف'),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => UnifiedDialog(
                              title: 'حذف التعليق',
                              subtitle:
                                  'هل أنت متأكد من رغبتك في حذف هذا التعليق؟',
                              content: Container(
                                padding: EdgeInsets.all(
                                  Responsive.space(context, size: Space.medium),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                      size: Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                    SizedBox(
                                      width: Responsive.space(
                                        context,
                                        size: Space.medium,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'لا يمكن التراجع عن هذا الإجراء بعد الحذف',
                                        style: TextStyle(
                                          fontSize: Responsive.text(
                                            context,
                                            size: TextSize.medium,
                                          ),
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmText: 'حذف',
                              confirmIcon: Icons.delete,
                              onConfirm: () => Navigator.pop(ctx, true),
                              onCancel: () => Navigator.pop(ctx, false),
                            ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('announcements')
                            .doc(widget.announcementId)
                            .collection('comments')
                            .doc(widget.comment.id)
                            .delete();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    UserProfile? commenterProfile =
        userProfileProvider.userProfilesCache[widget.comment.userId];
    if (commenterProfile == null) {
      userProfileProvider.getUserProfileById(widget.comment.userId).then((
        profile,
      ) {
        if (profile != null) setState(() {});
      });
    }
    Widget avatarWidget;
    if (commenterProfile != null &&
        commenterProfile.profileImageUrl != null &&
        commenterProfile.profileImageUrl!.isNotEmpty) {
      avatarWidget = CircleAvatar(
        backgroundImage: NetworkImage(commenterProfile.profileImageUrl!),
        radius: Responsive.space(context, size: Space.large),
      );
    } else {
      String initials =
          widget.comment.userName.isNotEmpty
              ? widget.comment.userName
                  .trim()
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join()
              : '?';
      avatarWidget = CircleAvatar(
        backgroundColor: Colors.grey[400],
        radius: Responsive.space(context, size: Space.large),
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: Responsive.text(context, size: TextSize.medium),
          ),
        ),
      );
    }
    final replies =
        widget.allComments
            .where((c) => c.parentId == widget.comment.id)
            .toList();
    // Main comment bubble
    Widget bubble = GestureDetector(
      onLongPress: () => widget.canEdit ? _showOptions(context) : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child:
            widget.isEditing
                ? Container(
                  key: const ValueKey('edit'),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.medium),
                    vertical: Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    border: Border.all(color: Colors.amber, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.comment.userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Text(
                            formatTimestamp(widget.comment.timestamp),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          if (widget.comment.edited == true)
                            Padding(
                              padding: EdgeInsets.only(
                                right: Responsive.space(
                                  context,
                                  size: Space.tiny,
                                ),
                              ),
                              child: Text(
                                '(تم التعديل)',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      widget.isSavingEdit
                          ? Center(
                            child: SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : Column(
                            children: [
                              TextField(
                                controller: widget.editController,
                                autofocus: true,
                                minLines: 1,
                                maxLines: 5,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  hintText: 'تعديل التعليق...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: Responsive.space(
                                      context,
                                      size: Space.medium,
                                    ),
                                    vertical: Responsive.space(
                                      context,
                                      size: Space.small,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.check,
                                      color: Colors.green,
                                      size: Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                      semanticLabel: 'حفظ التعديل',
                                    ),
                                    onPressed: () async {
                                      if (widget.editController!.text
                                              .trim()
                                              .isEmpty ||
                                          widget.editController!.text.trim() ==
                                              widget.comment.content) {
                                        widget.onEditCancel();
                                        return;
                                      }
                                      widget.onEditSave(
                                        widget.comment.id,
                                        widget.editController!.text.trim(),
                                      );
                                    },
                                  ),
                                  SizedBox(
                                    width: Responsive.space(
                                      context,
                                      size: Space.medium,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                      semanticLabel: 'إلغاء التعديل',
                                    ),
                                    onPressed: widget.onEditCancel,
                                  ),
                                ],
                              ),
                            ],
                          ),
                    ],
                  ),
                )
                : Container(
                  key: const ValueKey('view'),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.medium),
                    vertical: Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    border:
                        widget.isReply
                            ? Border(
                              right: BorderSide(
                                color: Colors.blueGrey.shade100,
                                width:
                                    Responsive.space(
                                      context,
                                      size: Space.tiny,
                                    ) /
                                    2,
                              ),
                            )
                            : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatarWidget,
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.comment.userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Text(
                                  formatTimestamp(widget.comment.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                if (widget.comment.edited == true)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: Responsive.space(
                                        context,
                                        size: Space.tiny,
                                      ),
                                    ),
                                    child: Text(
                                      '(تم التعديل)',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: Responsive.text(
                                          context,
                                          size: TextSize.small,
                                        ),
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                top: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              child: buildCommentText(
                                context,
                                widget.comment.content,
                              ),
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Row(
                              children: [
                                if (widget.userRole != 'Student')
                                  Container(
                                    decoration: BoxDecoration(
                                      border: const GradientBoxBorder(
                                        gradient: LinearGradient(
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                          colors: [
                                            Color(0xFF4158D0),
                                            Color(0xFFC850C0),
                                          ],
                                        ),
                                        width: 1.2,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        Responsive.space(
                                          context,
                                          size: Space.large,
                                        ),
                                      ),
                                    ),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
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
                                            size: Space.medium,
                                          ),
                                          vertical: Responsive.space(
                                            context,
                                            size: Space.tiny,
                                          ),
                                        ),
                                        minimumSize: Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        side:
                                            BorderSide
                                                .none, // Remove default border
                                      ),
                                      onPressed:
                                          () => widget.onReply(
                                            widget.comment.id,
                                            widget.comment.userName,
                                          ),
                                      label: Text(
                                        'رد',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: Responsive.text(
                                            context,
                                            size: TextSize.small,
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.reply,
                                        size: Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                        color: Colors.blueGrey,
                                        semanticLabel:
                                            'رد على ${widget.comment.userName}',
                                      ),
                                    ),
                                  ),
                                if (replies.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                    child: GestureDetector(
                                      onTap: handleToggleReplies,
                                      child: Row(
                                        children: [
                                          Text(
                                            _isExpanded
                                                ? 'إخفاء الردود (${replies.length})'
                                                : 'عرض الردود (${replies.length})',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: Responsive.text(
                                                context,
                                                size: TextSize.small,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Icon(
                                            _isExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                              size: Responsive.space(
                                context,
                                size: Space.large,
                              ),
                              semanticLabel:
                                  isLiked ? 'إزالة الإعجاب' : 'إضافة إعجاب',
                            ),
                            onPressed: handleLike,
                            splashRadius: Responsive.space(
                              context,
                              size: Space.large,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          likeCount > 0
                              ? Text(
                                '$likeCount',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : SizedBox.shrink(),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );

    Widget repliesWidget = Container();
    if (replies.isNotEmpty && _isExpanded) {
      repliesWidget = Padding(
        padding: EdgeInsets.only(
          top: Responsive.space(context, size: Space.small),
          right: Responsive.space(context, size: Space.medium),
        ),
        child: Column(
          children:
              replies
                  .map(
                    (reply) => CommentTile(
                      key: PageStorageKey('comment-${reply.id}'),
                      comment: reply,
                      allComments: widget.allComments,
                      provider: widget.provider,
                      announcementId: widget.announcementId,
                      userId: widget.userId,
                      canEdit: widget.userId == reply.userId,
                      isOwnComment: widget.userId == reply.userId,
                      isReply: true,
                      editController: widget.editController,
                      onEditStart: widget.onEditStart,
                      isEditing: widget.isEditing,
                      isSavingEdit: widget.isSavingEdit,
                      onEditSave: widget.onEditSave,
                      onEditCancel: widget.onEditCancel,
                      isExpanded:
                          widget.onToggleExpanded != null
                              ? (widget.isExpanded &&
                                  widget.onToggleExpanded != null)
                              : false,
                      onToggleExpanded: () {
                        setState(() {
                          // This state is managed by the parent CommentSection
                        });
                      },
                      userRole: widget.userRole,
                      onReply: widget.onReply,
                      nestingLevel: widget.nestingLevel + 1,
                    ),
                  )
                  .toList(),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: Responsive.space(context, size: Space.small),
        bottom: Responsive.space(context, size: Space.small),
        right:
            widget.isReply && widget.nestingLevel < 2
                ? Responsive.space(context, size: Space.medium) *
                    widget.nestingLevel
                : 0,
        left: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [bubble, repliesWidget],
      ),
    );
  }
}

class _LikeButton extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;
  const _LikeButton({
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
  });

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likeCount;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likeCount = widget.likeCount;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked ||
        oldWidget.likeCount != widget.likeCount) {
      _isLiked = widget.isLiked;
      _likeCount = widget.likeCount;
    }
  }

  void _handleTap() {
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likeCount--;
      } else {
        _isLiked = true;
        _likeCount++;
      }
    });
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: IconButton(
        icon: Icon(
          _isLiked ? Icons.favorite : Icons.favorite_border,
          color: _isLiked ? Colors.red : Colors.grey,
          size: Responsive.space(context, size: Space.large),
          semanticLabel: _isLiked ? 'إزالة الإعجاب' : 'إضافة إعجاب',
        ),
        onPressed: _handleTap,
        splashRadius: Responsive.space(context, size: Space.large),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final BuildContext context;
  final String text;
  final bool isLong;
  final int trimLines;
  final int trimChars;
  const _ExpandableText({
    required this.context,
    required this.text,
    required this.isLong,
    this.trimLines = 4,
    this.trimChars = 120,
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isLong) {
      return Text(
        widget.text,
        style: TextStyle(
          fontSize: Responsive.text(widget.context, size: TextSize.medium),
        ),
      );
    }
    if (expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            style: TextStyle(
              fontSize: Responsive.text(widget.context, size: TextSize.medium),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => expanded = false),
            child: Padding(
              padding: EdgeInsets.only(
                top: Responsive.space(widget.context, size: Space.small),
              ),
              child: Text(
                'عرض أقل',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: Responsive.text(
                    widget.context,
                    size: TextSize.small,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      String shortText = widget.text;
      if (widget.text.length > widget.trimChars) {
        shortText = '${widget.text.substring(0, widget.trimChars)}...';
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shortText,
            maxLines: widget.trimLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Responsive.text(widget.context, size: TextSize.medium),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => expanded = true),
            child: Padding(
              padding: EdgeInsets.only(
                top: Responsive.space(widget.context, size: Space.small),
              ),
              child: Text(
                'عرض المزيد',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: Responsive.text(
                    widget.context,
                    size: TextSize.small,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}

class CommentSection extends StatefulWidget {
  final String announcementId;
  final ScrollController? scrollController;
  const CommentSection({
    super.key,
    required this.announcementId,
    this.scrollController,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _controller = TextEditingController();
  String? _replyToCommentId;
  String? _replyToUserName;
  String? _editingCommentId;
  TextEditingController? _editController;
  bool _isSavingEdit = false;
  final Map<String, bool> _expandedReplies = {};
  List<CommentData>? _cachedComments;
  // In _CommentSectionState, cache the user role
  late String? _userRole;
  // In _CommentSectionState, add a character limit
  static const int _maxCommentLength = 300;
  String? _sendError;
  // In CommentSection, add a FocusNode for the input
  final FocusNode _inputFocusNode = FocusNode();
  // In _CommentSectionState, add state for pagination
  int _rootCommentsLimit = 30;

  // Add ValueNotifier for efficient state management
  final ValueNotifier<bool> _canSendNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> _errorTextNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    _userRole = userProfileProvider.loggedInUserProfile?.role;

    // Listen to text changes
    _controller.addListener(_updateSendState);
  }

  @override
  void dispose() {
    _controller.dispose();
    _editController?.dispose();
    _inputFocusNode.dispose();
    _canSendNotifier.dispose();
    _errorTextNotifier.dispose();
    super.dispose();
  }

  void _updateSendState() {
    final text = _controller.text;
    final newCanSend =
        text.trim().isNotEmpty && text.length <= _maxCommentLength;
    final newErrorText =
        text.length > _maxCommentLength ? 'تجاوزت الحد الأقصى لعدد الأحرف' : '';

    if (_canSendNotifier.value != newCanSend) {
      _canSendNotifier.value = newCanSend;
    }

    if (_errorTextNotifier.value != newErrorText) {
      _errorTextNotifier.value = newErrorText;
    }
  }

  void _toggleReplies(String commentId) {
    setState(() {
      _expandedReplies[commentId] = !(_expandedReplies[commentId] ?? false);
    });
  }

  void _sendComment(BuildContext context) async {
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final userProfile = userProfileProvider.loggedInUserProfile;
    if (userProfile == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }
    final userId = userProfile.id;
    final userName = userProfile.name;
    final content = _controller.text.trim();
    if (content.isEmpty || content.length > _maxCommentLength) return;
    if (_userRole == 'Student' && _replyToCommentId == null) {
      final provider = Provider.of<AnnouncementProvider>(
        context,
        listen: false,
      );
      final comments =
          await provider.commentsStream(widget.announcementId).first;
      final hasComment = comments.any(
        (c) => c.userId == userId && c.parentId == null,
      );
      if (hasComment) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'يمكنك إضافة تعليق واحد فقط.',
              textAlign: TextAlign.center,
            ),
          ),
        );
        return;
      }
    }
    final comment = CommentData(
      id: '',
      userId: userId,
      userName: userName,
      content: content,
      timestamp: DateTime.now(),
      likes: [],
      parentId: _replyToCommentId,
    );
    try {
      if (_replyToCommentId != null) {
        await provider.replyToComment(
          widget.announcementId,
          _replyToCommentId!,
          comment,
        );
      } else {
        await provider.addComment(widget.announcementId, comment);
      }
      setState(() {
        _controller.clear();
        _replyToCommentId = null;
        _replyToUserName = null;
        _sendError = null;
      });
    } catch (e) {
      setState(() {
        _sendError = 'حدث خطأ أثناء إرسال التعليق. حاول مرة أخرى.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sendError!, textAlign: TextAlign.center)),
      );
    }
  }

  Widget _buildLikeButton(
    CommentData comment,
    String announcementId,
    String userId,
    AnnouncementProvider provider, {
    required List<String> likerNames,
    required bool isOwnLike,
  }) {
    return _LikeButton(
      isLiked: comment.likes.contains(userId),
      likeCount: comment.likes.length,
      onTap: () => provider.likeComment(announcementId, comment.id, userId),
    );
  }

  Widget buildCommentText(
    BuildContext context,
    String text, {
    int trimLines = 4,
    int trimChars = 120,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: Responsive.text(context, size: TextSize.medium),
      ),
    );
    final tp = TextPainter(
      text: span,
      maxLines: trimLines,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: 1000);
    final isLong = text.length > trimChars || tp.didExceedMaxLines;
    return _ExpandableText(
      context: context,
      text: text,
      isLong: isLong,
      trimLines: trimLines,
      trimChars: trimChars,
    );
  }

  String _exactTimestamp(DateTime timestamp) {
    return '${timestamp.year}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnouncementProvider>(
      builder: (context, provider, _) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Header with drag handle
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: Responsive.space(context, size: Space.medium),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        Text(
                          'التعليقات',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.heading,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Comments list
                  Expanded(
                    child: StreamBuilder<List<CommentData>>(
                      stream: provider.commentsStream(widget.announcementId),
                      initialData: _cachedComments,
                      builder: (context, snapshot) {
                        // Update cache if new data is available
                        if (snapshot.hasData && snapshot.data != null) {
                          _cachedComments = snapshot.data;
                        }
                        final comments = snapshot.data ?? _cachedComments ?? [];
                        final rootComments =
                            comments.where((c) => c.parentId == null).toList();
                        if ((!snapshot.hasData &&
                                (_cachedComments == null ||
                                    _cachedComments!.isEmpty)) ||
                            (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                (_cachedComments == null ||
                                    _cachedComments!.isEmpty))) {
                          // Skeleton loader (simple shimmer effect)
                          return ListView.builder(
                            itemCount: 3,
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.space(
                                context,
                                size: Space.large,
                              ),
                            ),
                            itemBuilder:
                                (context, i) => Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                    vertical: Responsive.space(
                                      context,
                                      size: Space.small,
                                    ),
                                  ),
                                  child: Container(
                                    height:
                                        Responsive.space(
                                          context,
                                          size: Space.large,
                                        ) *
                                        2,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(
                                        Responsive.space(
                                          context,
                                          size: Space.large,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          );
                        }
                        if (rootComments.isEmpty) {
                          return Center(
                            child: SizedBox(
                              width: Responsive.width(context) * 0.6,
                              height: Responsive.height(context) * 0.35,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  Lottie.asset(
                                    'assets/animation/nothing.json',
                                    repeat: true,
                                    width: Responsive.width(context) * 0.6,
                                    height: Responsive.height(context) * 0.3,
                                  ),
                                  Positioned(
                                    top: Responsive.height(context) * 0.25 + 5,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Text(
                                        'لا توجد اي اسألة بعد.',
                                        style: TextStyle(
                                          fontSize: Responsive.text(
                                            context,
                                            size: TextSize.heading,
                                          ),
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final visibleRootComments =
                            rootComments.take(_rootCommentsLimit).toList();
                        return ListView.builder(
                          controller: widget.scrollController,
                          padding: EdgeInsets.only(
                            bottom: Responsive.space(
                              context,
                              size: Space.large,
                            ),
                            top: 0,
                          ),
                          itemCount:
                              visibleRootComments.length +
                              (rootComments.length > _rootCommentsLimit
                                  ? 1
                                  : 0),
                          itemBuilder: (context, i) {
                            if (i < visibleRootComments.length) {
                              return CommentTile(
                                key: PageStorageKey(
                                  'comment-${visibleRootComments[i].id}',
                                ),
                                comment: visibleRootComments[i],
                                allComments: comments,
                                provider: provider,
                                announcementId: widget.announcementId,
                                userId:
                                    Provider.of<UserProfileProvider>(
                                      context,
                                      listen: false,
                                    ).loggedInUserProfile?.id ??
                                    '',
                                canEdit:
                                    Provider.of<UserProfileProvider>(
                                      context,
                                      listen: false,
                                    ).loggedInUserProfile?.id ==
                                    visibleRootComments[i].userId,
                                isOwnComment:
                                    Provider.of<UserProfileProvider>(
                                      context,
                                      listen: false,
                                    ).loggedInUserProfile?.id ==
                                    visibleRootComments[i].userId,
                                isReply: false,
                                editController: _editController,
                                onEditStart: (id, controller) {
                                  setState(() {
                                    _editingCommentId = id;
                                    _editController = controller;
                                  });
                                },
                                isEditing:
                                    _editingCommentId ==
                                    visibleRootComments[i].id,
                                isSavingEdit: _isSavingEdit,
                                onEditSave: (id, newText) async {
                                  setState(() => _isSavingEdit = true);
                                  await provider.updateComment(
                                    widget.announcementId,
                                    id,
                                    newText,
                                    Provider.of<UserProfileProvider>(
                                          context,
                                          listen: false,
                                        ).loggedInUserProfile?.id ??
                                        '',
                                  );
                                  setState(() {
                                    _editingCommentId = null;
                                    _isSavingEdit = false;
                                  });
                                },
                                onEditCancel:
                                    () => setState(
                                      () => _editingCommentId = null,
                                    ),
                                isExpanded:
                                    _expandedReplies[visibleRootComments[i]
                                        .id] ??
                                    false,
                                onToggleExpanded: () {
                                  setState(() {
                                    _expandedReplies[visibleRootComments[i]
                                            .id] =
                                        !(_expandedReplies[visibleRootComments[i]
                                                .id] ??
                                            false);
                                  });
                                },
                                userRole: _userRole ?? '',
                                onReply: (commentId, userName) {
                                  setState(() {
                                    _replyToCommentId = commentId;
                                    _replyToUserName = userName;
                                  });
                                  _inputFocusNode.requestFocus();
                                },
                                nestingLevel: 0,
                              );
                            } else {
                              // Load More button
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: Responsive.space(
                                    context,
                                    size: Space.medium,
                                  ),
                                ),
                                child: Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _rootCommentsLimit += 30;
                                      });
                                    },
                                    child: Text('تحميل المزيد'),
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                  // Input field at the bottom
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.medium),
                      vertical: Responsive.space(context, size: Space.small),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                          offset: Offset(
                            0,
                            -Responsive.space(context, size: Space.tiny),
                          ),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _inputFocusNode,
                              textAlign: TextAlign.right,
                              maxLength: _maxCommentLength,
                              decoration: InputDecoration(
                                hintText:
                                    _replyToUserName != null
                                        ? 'الرد على $_replyToUserName'
                                        : 'تحب تسأل عن حاجة ؟',
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: Responsive.space(
                                    context,
                                    size: Space.medium,
                                  ),
                                  vertical: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                counterText:
                                    '${_controller.text.length}/$_maxCommentLength',
                                errorText:
                                    _errorTextNotifier.value.isNotEmpty
                                        ? _errorTextNotifier.value
                                        : null,
                              ),
                              minLines: 1,
                              maxLines: 3,
                              autofocus: _replyToUserName != null,
                              // onChanged is no longer needed since we use controller listener
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: _canSendNotifier,
                            builder: (context, canSend, child) {
                              return IconButton(
                                icon: Icon(
                                  Icons.send,
                                  color: canSend ? Colors.blue : Colors.grey,
                                  semanticLabel: 'إرسال التعليق',
                                ),
                                onPressed:
                                    canSend
                                        ? () => _sendComment(context)
                                        : null,
                                splashRadius: Responsive.space(
                                  context,
                                  size: Space.large,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return '${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return '${diff.inHours} ساعة';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 7) return '${diff.inDays} أيام';
  return '${timestamp.year}/${timestamp.month}/${timestamp.day}';
}

Widget buildCommentText(
  BuildContext context,
  String text, {
  int trimLines = 4,
  int trimChars = 120,
}) {
  final span = TextSpan(
    text: text,
    style: TextStyle(fontSize: Responsive.text(context, size: TextSize.medium)),
  );
  final tp = TextPainter(
    text: span,
    maxLines: trimLines,
    textDirection: TextDirection.rtl,
  )..layout(maxWidth: 1000);
  final isLong = text.length > trimChars || tp.didExceedMaxLines;
  return _ExpandableText(
    context: context,
    text: text,
    isLong: isLong,
    trimLines: trimLines,
    trimChars: trimChars,
  );
}
