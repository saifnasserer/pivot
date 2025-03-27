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
    return Padding(
      padding: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color:
              widget.check
                  ? Colors.grey.withOpacity(0.2)
                  : widget.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
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
                        color: widget.check ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.small) * 1.5,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          widget.check
                              ? Colors.grey.withOpacity(0.8)
                              : widget.color.withOpacity(0.8),
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
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: EdgeInsets.only(
                  right: Responsive.space(context, size: Space.large) * 2.5,
                ),
                child: Text(
                  'اخر معاد للتسليم : ${formattedDate}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.large)),
              Text(
                widget.description,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize:
                      Responsive.text(context, size: TextSize.medium) * .9,
                  color: widget.check ? Colors.grey : Colors.black,
                  // fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
