import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inspection_grid/pages/concept_3_pages/question_damaged_component_page.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../generated/assets.dart';
import '../../services/secure_storage_service.dart';
import '../full_screen_image_widget.dart';

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
        title: GestureDetector(
          onTap: () async {
            final data = await sss.getKey(key: 'thumbnail');
            print('data: $data');
          },
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
          ),
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
                        if (showBadge ?? false) {
                          List<Map<String, dynamic>> data =
                              ((objectData?['${part['partId']}'] as List?) ??
                                      [])
                                  .map<Map<String, dynamic>>(
                                      (e) => e as Map<String, dynamic>)
                                  .toList();

                          showDamageDetailsDialog(
                            context,
                            part,
                            data,
                          );
                        } else {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  QuestionDamagedComponentPage(
                                part: part,
                              ),
                            ),
                          );
                          setState(() {});
                        }
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

  void showDamageDetailsDialog(
    BuildContext context,
    Map<String, dynamic> part,
    List<Map<String, dynamic>> items,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        String partId = part['partId'].toString();
        return DialogDamageDetails(
          partId: partId,
          items: items,
          onDelete: (componentId) async {
            setState(() {
              items.removeWhere(
                (element) => element['componentId'].toString() == componentId,
              );
            });

            final thumbnailData = await sss.getKey(key: 'thumbnail');
            if (thumbnailData == null) {
              return;
            }

            Map<String, dynamic> objectData = jsonDecode(thumbnailData);

            if (objectData.containsKey(partId)) {
              List<dynamic> components = objectData[partId];
              components.removeWhere((component) {
                bool data = component['componentId'].toString() == componentId;
                return data;
              });
              if (components.isEmpty) {
                objectData.remove(partId);
              } else {
                objectData[partId] = components;
              }

              await sss.cacheKeyWithValue(
                key: 'thumbnail',
                value: jsonEncode(objectData),
              );
            }
          },
          onAdd: () async {
            Navigator.of(context).pop();
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => QuestionDamagedComponentPage(
                  part: part,
                ),
              ),
            );
            setState(() {});
          },
        );
      },
    );

    setState(() {});
  }

  Future<Map<String, dynamic>> getJson() async {
    final result =
        await DefaultAssetBundle.of(context).loadString(Assets.jsonInspection2);
    return jsonDecode(result);
  }
}

class DialogDamageDetails extends StatefulWidget {
  const DialogDamageDetails({
    super.key,
    required this.partId,
    required this.items,
    required this.onDelete,
    required this.onAdd,
  });

  final String partId;
  final List<Map<String, dynamic>> items;
  final Function(String componentId) onDelete;
  final Function onAdd;

  @override
  State<DialogDamageDetails> createState() => _DialogDamageDetailsState();
}

class _DialogDamageDetailsState extends State<DialogDamageDetails> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Komponen Detail Inspeksi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ${item['componentName'].toString().replaceAll('_', ' ')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: item['damageOptions']
                                    .map<Widget>((damageOption) {
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    elevation: 3,
                                    margin: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FullScreenImageView(
                                                images: List<
                                                        Map<String,
                                                            dynamic>>.from(
                                                    damageOption['damages'].map(
                                                        (image) => image as Map<
                                                            String, dynamic>)),
                                                initialPage: 0,
                                                keyText: item['componentName'],
                                                valueText:
                                                    damageOption['damageType'],
                                              ),
                                            ),
                                          ),
                                          child: SizedBox(
                                            height: 150.0,
                                            child: PhotoViewGallery.builder(
                                              itemCount: damageOption['damages']
                                                  .length,
                                              builder: (context, index) {
                                                return PhotoViewGalleryPageOptions(
                                                  imageProvider: FileImage(
                                                    File(
                                                      damageOption['damages']
                                                          [index]['imagePath'],
                                                    ),
                                                  ),
                                                  minScale:
                                                      PhotoViewComputedScale
                                                          .contained,
                                                  maxScale:
                                                      PhotoViewComputedScale
                                                              .covered *
                                                          2,
                                                );
                                              },
                                              pageController: PageController(),
                                              scrollPhysics:
                                                  const BouncingScrollPhysics(),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.0, horizontal: 12.0),
                                          child: Center(
                                            child: Column(
                                              children: [
                                                Text(
                                                  '${damageOption['damageType']}',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontStyle:
                                                          FontStyle.italic),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  'Ada ${damageOption['damages'].length} kerusakan',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 8),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    widget.onDelete(
                                      item['componentId'].toString(),
                                    );
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          Colors.blueAccent), // Updated button style
                      padding: WidgetStateProperty.all<EdgeInsets>(
                          EdgeInsets.symmetric(vertical: 12.0)),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0))),
                    ),
                    onPressed: () {
                      widget.onAdd();
                    },
                    child: Text(
                      'Tambah Inspeksi Komponen',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
