import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inspection_grid/pages/concept_1n2_with_dynamic_damage_pages/question_component_page.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../generated/assets.dart';
import '../../services/secure_storage_service.dart';
import '../full_screen_image_widget.dart';

class DynamicInspectionWithGridDynamic extends StatefulWidget {
  const DynamicInspectionWithGridDynamic({
    super.key,
    required this.title,
  });
  final String title;

  @override
  State<DynamicInspectionWithGridDynamic> createState() =>
      _DynamicInspectionWithGridDynamicState();
}

class _DynamicInspectionWithGridDynamicState
    extends State<DynamicInspectionWithGridDynamic> {
  // Daftar komponen dengan key sebagai index
  final List<int> listComponent = List.generate(16, (index) => index);
  Offset? offset;

  // Function to convert global to local coordinates for the InteractiveViewer
  void _handleTap(
    int componentIndex,
    Map<String, dynamic> data,
  ) async {
    if (offset != null) {
      Offset? position = offset;
      final listComponent = (data['$componentIndex']['listComponent'] as List)
          .map(
            (e) => e as Map<String, dynamic>,
          )
          .toList();
      print(
        'ListComponent $listComponent, Koordinat: (${position?.dx}, ${position?.dy})',
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuestionComponentPage(
            index: componentIndex,
            listComponent: listComponent,
            position: position,
          ),
        ),
      );
      setState(() {});
    }
  }

  SecureStorageService sss = SecureStorageServiceImpl(
    flutterSecureStorage: FlutterSecureStorage(),
  );

  // Add function to create circle widgets from objectData only for specific grid indices
  List<Widget> _buildCoordCircles(
    Map<String, dynamic> listComponent,
    Map<String, dynamic> component,
    int index,
  ) {
    List<Widget> circles = [];
    if (component.containsKey('$index')) {
      final components = (component['$index'] as List<dynamic>)
          .map(
            (e) => e as Map<String, dynamic>,
          )
          .toList();
      for (var i = 0; i < components.length; i++) {
        double x = components[i]['x'];
        double y = components[i]['y'];

        circles.add(
          LayoutBuilder(builder: (context, constraints) {
            return Stack(
              // Ensure the parent of Positioned is Stack
              children: [
                Positioned(
                  left: x,
                  top: y,
                  child: Draggable(
                    data: {'component': components[i], 'index': i},
                    feedback: Container(
                      width: 10.0,
                      height: 10.0,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    childWhenDragging: SizedBox.shrink(),
                    onDragEnd: (details) {
                      setState(() {
                        final RenderBox renderBox =
                            context.findRenderObject() as RenderBox;
                        final Offset localPosition =
                            renderBox.globalToLocal(details.offset);

                        // Calculate the new position based on Global to Local converted position
                        double newX =
                            (localPosition.dx / constraints.maxWidth) *
                                constraints.maxWidth;
                        double newY =
                            (localPosition.dy / constraints.maxHeight) *
                                constraints.maxHeight;

                        // Ensure newX, newY are within the grid cell bounds
                        newX = newX.clamp(0.0, constraints.maxWidth - 10.0);
                        newY = newY.clamp(0.0, constraints.maxHeight - 10.0);

                        // Update with new position
                        components[i]['x'] = newX;
                        components[i]['y'] = newY;

                        // Save changes
                        _saveUpdatedCoordinates(index.toString(), component);
                      });
                    },
                    child: GestureDetector(
                      onTap: () async {
                        // Show update dialog before navigating
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
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
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 16),
                                        Expanded(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: components.length,
                                            itemBuilder: (context, index) {
                                              final item = components[index];
                                              return Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                elevation: 4,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${index + 1}. ${item['componentName'].toString().replaceAll('_', ' ')}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children:
                                                            item['answers']
                                                                .map<Widget>(
                                                                    (answer) {
                                                          return Card(
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12.0),
                                                            ),
                                                            elevation: 3,
                                                            margin: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        8.0),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                GestureDetector(
                                                                  onTap: () async =>
                                                                      await Navigator
                                                                          .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              FullScreenImageView(
                                                                        images: List<
                                                                            Map<String,
                                                                                dynamic>>.from(answer['damages'].map((image) => image as Map<
                                                                            String,
                                                                            dynamic>)),
                                                                        initialPage:
                                                                            0,
                                                                        keyText:
                                                                            item['componentName'],
                                                                        valueText:
                                                                            answer['answer'],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      SizedBox(
                                                                    height:
                                                                        150.0,
                                                                    child: PhotoViewGallery
                                                                        .builder(
                                                                      itemCount:
                                                                          answer['damages']
                                                                              .length,
                                                                      builder:
                                                                          (context,
                                                                              index) {
                                                                        return PhotoViewGalleryPageOptions(
                                                                          imageProvider:
                                                                              FileImage(
                                                                            File(
                                                                              answer['damages'][index]['imagePath'],
                                                                            ),
                                                                          ),
                                                                          minScale:
                                                                              PhotoViewComputedScale.contained,
                                                                          maxScale:
                                                                              PhotoViewComputedScale.covered * 2,
                                                                        );
                                                                      },
                                                                      pageController:
                                                                          PageController(),
                                                                      scrollPhysics:
                                                                          const BouncingScrollPhysics(),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding: EdgeInsets.symmetric(
                                                                      vertical:
                                                                          8.0,
                                                                      horizontal:
                                                                          12.0),
                                                                  child: Center(
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        Text(
                                                                          '${answer['answer']}',
                                                                          style: TextStyle(
                                                                              fontSize: 14,
                                                                              fontStyle: FontStyle.italic),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                        ),
                                                                        Text(
                                                                          'Ada ${answer['damages'].length} kerusakan',
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.red,
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
                                                        alignment: Alignment
                                                            .bottomRight,
                                                        child: IconButton(
                                                          icon: Icon(
                                                              Icons.delete),
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
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
                                              backgroundColor: WidgetStateProperty
                                                  .all<Color>(Colors
                                                      .blueAccent), // Updated button style
                                              padding: WidgetStateProperty.all<
                                                      EdgeInsets>(
                                                  EdgeInsets.symmetric(
                                                      vertical: 12.0)),
                                              shape: WidgetStateProperty.all<
                                                      RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0))),
                                            ),
                                            onPressed: () async {
                                              Navigator.of(context)
                                                  .pop(); // Close the dialog
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      QuestionComponentPage(
                                                    index:
                                                        index, // or the appropriate index
                                                    listComponent: (listComponent[
                                                                    '$index'][
                                                                'listComponent']
                                                            as List)
                                                        .map(
                                                          (e) => e as Map<
                                                              String, dynamic>,
                                                        )
                                                        .toList(),
                                                    position: Offset(x,
                                                        y), // or the appropriate position
                                                  ),
                                                ),
                                              );
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
                                      icon: Icon(Icons.close,
                                          color: Colors.black),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );

                        setState(() {});
                      },
                      child: Tooltip(
                        message: components[i].toString(),
                        child: Container(
                          width: 10.0,
                          height: 10.0,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      }
    }
    return circles;
  }

  // Save updated coordinates to local storage
  void _saveUpdatedCoordinates(
      String indexKey, Map<String, dynamic> data) async {
    // Convert updated data to JSON
    String updatedDataJson = jsonEncode(data);

    // Save the updated data to secure storage
    await sss.cacheKeyWithValue(key: 'grid_dynamic', value: updatedDataJson);
    print('Coordinates for index $indexKey saved.');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sss.getKey(key: 'grid_dynamic'),
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

            return Scaffold(
              appBar: AppBar(
                title: GestureDetector(
                  onTap: () async {
                    final data = await sss.getKey(key: 'grid_dynamic');
                    print('data: $data');
                  },
                  child: Text(widget.title),
                ),
              ),
              body: Center(
                child: FutureBuilder(
                  future: _getImageSize(data['image']),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator(); // Tampilkan loading jika ukuran gambar belum didapat
                    }

                    Size imageSize = snapshot.data!;
                    double aspectRatio = imageSize.width / imageSize.height;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        double imageWidth = constraints.maxWidth;
                        double imageHeight = imageWidth / aspectRatio;
                        final TransformationController
                            transformationController =
                            TransformationController();

                        return InteractiveViewer(
                          transformationController: transformationController,
                          minScale: 0.2,
                          maxScale: 10.0,
                          child: Stack(
                            children: [
                              Image.asset(
                                data['image'],
                                width: imageWidth,
                                height: imageHeight,
                                fit: BoxFit.cover,
                              ),
                              GridView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: aspectRatio,
                                ),
                                itemCount: listComponent.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTapDown: (details) async {
                                      setState(() {
                                        offset = details.localPosition /
                                            transformationController.value
                                                .getMaxScaleOnAxis();
                                      });
                                    },
                                    onLongPress: () => _handleTap(
                                      index,
                                      data['data'],
                                    ),
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                            ),
                                            color: (objectData?.keys
                                                        .contains('$index') ??
                                                    false)
                                                ? Colors.red.withOpacity(0.5)
                                                : Colors.transparent,
                                          ),
                                        ),
                                        ..._buildCoordCircles(
                                          data['data'],
                                          objectData ?? {},
                                          index,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> getJson() async {
    final result = await DefaultAssetBundle.of(context)
        .loadString(Assets.jsonInspectionCar);
    return jsonDecode(result);
  }

  // Fungsi untuk mendapatkan ukuran asli gambar
  Future<Size> _getImageSize(String assetPath) async {
    Image image = Image.asset(assetPath);
    Completer<Size> completer = Completer();
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()));
      }),
    );
    return completer.future;
  }
}
