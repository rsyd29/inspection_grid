import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inspection_grid/pages/concept_3_pages/question_damaged_component_page.dart';

import '../../generated/assets.dart';
import '../../services/secure_storage_service.dart';

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
  SecureStorageService sss = SecureStorageServiceImpl(
    flutterSecureStorage: FlutterSecureStorage(),
  );

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
      body: FutureBuilder(
        future: sss.getKey(key: 'thumbnail'),
        builder: (context, snapshot) {
          final cache = snapshot.data;
          Map<String, dynamic>? objectData =
              cache == null ? {} : jsonDecode(cache);

          return FutureBuilder(
            future: getJson(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child:
                      CircularProgressIndicator(), // Centered loading indicator
                );
              }
              final data = snapshot.data;

              if (data == null) {
                return Text(
                  'No Data Available',
                  style: TextStyle(color: Colors.black),
                ); // Styled text
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  itemCount: data['parts'].length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                  ),
                  itemBuilder: (context, index) {
                    final part = data['parts'][index];
                    final showBadge =
                        objectData?.keys.contains(part['partId'].toString());
                    return InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QuestionDamagedComponentPage(
                              part: part,
                            ),
                          ),
                        );
                        setState(() {});
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
                                  image: AssetImage(part['partUrl']),
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
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(8.0),
                                    bottomRight: Radius.circular(8.0),
                                  ),
                                ),
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  part['partName'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            if (showBadge ?? false)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2.0),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getJson() async {
    final result =
        await DefaultAssetBundle.of(context).loadString(Assets.jsonInspection2);
    return jsonDecode(result);
  }
}
