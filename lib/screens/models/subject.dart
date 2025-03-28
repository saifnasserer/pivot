import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class SubjectModel extends StatelessWidget {
  const SubjectModel({super.key, required this.doctor, required this.title});
  final String title;
  final String doctor;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
        // overlayColor: WidgetStateProperty.all(Colors.transparent),
        // shadowColor: WidgetStateProperty.all(Colors.transparent),
        // padding: ,
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      onPressed: () {},
      child: Padding(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: Responsive.text(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          doctor,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize:
                                Responsive.text(context, size: TextSize.small) *
                                1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: Responsive.space(context)),
                  Container(
                    width: Responsive.space(context, size: Space.large) * 3,
                    height: Responsive.space(context, size: Space.large) * 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: Responsive.space(context, size: Space.xlarge),
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
