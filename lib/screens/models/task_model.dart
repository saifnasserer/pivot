import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class TaskModel extends StatefulWidget {
  TaskModel({
    super.key,
    required this.date,
    required this.color,
    required this.title,
    required this.description,
  });

  bool check = false;
  final DateTime date;
  final Color color;
  final String title;
  final String description;

  @override
  State<TaskModel> createState() => _TaskModelState();
}

class _TaskModelState extends State<TaskModel> {
  @override
  Widget build(BuildContext context) {
    String formattedDate = '${widget.date.month}/${widget.date.day}';

    // Compute contrasting text color based on background color
    final Color textColor = widget.check ? Colors.grey : Colors.black87;
    final Color primaryColor =
        widget.check ? Colors.grey : widget.color.withOpacity(0.8);

    return Padding(
      padding: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: primaryColor, width: 2.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        decoration:
                            widget.check
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                        fontSize:
                            Responsive.text(context, size: TextSize.medium) *
                            1.1,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.small) * 1.5,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          widget.check = !widget.check;
                        });
                      },
                      icon: Icon(
                        widget.check
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: EdgeInsets.only(
                  right: Responsive.space(context, size: Space.large) * 2.5,
                  top: Responsive.space(context, size: Space.small),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.small),
                    vertical:
                        Responsive.space(context, size: Space.small) * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'اخر معاد للتسليم : $formattedDate',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Container(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.medium),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.description,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize:
                        Responsive.text(context, size: TextSize.medium) * 0.9,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
