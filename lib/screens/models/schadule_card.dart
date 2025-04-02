import 'package:flutter/material.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/responsive.dart';

class SchaduleCard extends StatelessWidget {
  final ScheduleItem item;
  final VoidCallback handleDelete;
  const SchaduleCard({
    super.key,
    required this.item,
    required this.handleDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        item.type == ScheduleItemType.lecture
            ? Colors.blue.shade50
            : Colors.orange.shade50;
    final IconData typeIcon =
        item.type == ScheduleItemType.lecture
            ? Icons.menu_book_rounded
            : Icons.groups_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.space(context)),
      padding: EdgeInsets.all(Responsive.space(context)),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Responsive.space(context) * 0.8),
        color: cardColor,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                typeIcon,
                size: Responsive.text(context) * 1.1,
                color:
                    item.type == ScheduleItemType.lecture
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
              ),
              SizedBox(width: Responsive.space(context) * 0.5),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded),
                iconSize: Responsive.text(context) * 1.1,
                onPressed: () {
                  handleDelete();
                },
              ),
              SizedBox(width: Responsive.space(context) * 0.5),
              Expanded(
                child: Text(
                  item.title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: Responsive.text(context) * 1.1,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context) * 0.75),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Expanded(
              //   child: IconButton(
              //     icon: Icon(Icons.delete),
              //     onPressed: () {
              //       handleDelete();
              //     },
              //   ),
              // ),
              // SizedBox(
              //   width: Responsive.space(context, size: Space.xlarge) * 6.5,
              // ),
              Text(
                item.location,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: Responsive.text(context) * 0.95,
                ),
              ),
              SizedBox(width: Responsive.space(context) * 0.3),
              Icon(
                Icons.location_on_outlined,
                size: Responsive.text(context),
                color: Colors.black54,
              ),
              SizedBox(width: Responsive.space(context)),
              Text(
                item.time,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: Responsive.text(context) * 0.95,
                ),
              ),
              SizedBox(width: Responsive.space(context) * 0.3),
              Icon(
                Icons.access_time_outlined,
                size: Responsive.text(context),
                color: Colors.black54,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
