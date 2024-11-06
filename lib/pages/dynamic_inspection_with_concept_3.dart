import 'package:flutter/material.dart';

class DynamicInspectionWithConcept3 extends StatefulWidget {
  const DynamicInspectionWithConcept3({
    super.key,
    required this.title,
  });
  final String title;

  @override
  State<DynamicInspectionWithConcept3> createState() =>
      _DynamicInspectionWithConcept3State();
}

class _DynamicInspectionWithConcept3State
    extends State<DynamicInspectionWithConcept3> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
    );
  }
}
