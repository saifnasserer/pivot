import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class LectureCardModel extends StatefulWidget {
  const LectureCardModel({
    super.key,
    required this.title,
    required this.description,
    required this.section,
  });
  final String title;
  final String description;
  final bool section;
  @override
  State<LectureCardModel> createState() => _LectureCardModelState();
}

class _LectureCardModelState extends State<LectureCardModel> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * .5,
        decoration: BoxDecoration(
          color:
              widget.section
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
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
                        decoration: TextDecoration.none,
                        fontSize:
                            Responsive.text(context, size: TextSize.medium) *
                            1.1,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.small) * 1.5,
                  ),
                ],
              ),

              SizedBox(height: Responsive.space(context, size: Space.large)),
              Text(
                widget.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize:
                      Responsive.text(context, size: TextSize.medium) * .9,
                  color: Colors.black,
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
