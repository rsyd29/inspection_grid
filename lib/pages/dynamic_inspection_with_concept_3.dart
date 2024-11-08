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
    final imageParts = [
      'assets/images/mobil_part_0_0.png',
      'assets/images/mobil_part_0_1.png',
      'assets/images/mobil_part_0_2.png',
      'assets/images/mobil_part_0_3.png',
      'assets/images/mobil_part_1_0.png',
      'assets/images/mobil_part_1_1.png',
      'assets/images/mobil_part_1_2.png',
      'assets/images/mobil_part_1_3.png',
      'assets/images/mobil_part_2_0.png',
      'assets/images/mobil_part_2_1.png',
      'assets/images/mobil_part_2_2.png',
      'assets/images/mobil_part_2_3.png',
      'assets/images/mobil_part_3_0.png',
      'assets/images/mobil_part_3_1.png',
      'assets/images/mobil_part_3_2.png',
      'assets/images/mobil_part_3_3.png',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: imageParts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                // Placeholder for click handler
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 4,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(imageParts[index]),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8.0),
                            bottomRight: Radius.circular(8.0),
                          ),
                        ),
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          'Part ${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
