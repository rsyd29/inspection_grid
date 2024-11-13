import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inspection_grid/pages/concept_1n2_with_dynamic_damage_pages/question_component_page.dart';

import '../../generated/assets.dart';
import '../../services/secure_storage_service.dart';

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
                            return AlertDialog(
                              title: Text('Update Component'),
                              content:
                                  Text('Do you want to update this component?'),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                ),
                                TextButton(
                                  child: Text('Update'),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            QuestionComponentPage(
                                          index: i, // or the appropriate index
                                          listComponent:
                                              (listComponent['$index']
                                                      ['listComponent'] as List)
                                                  .map(
                                                    (e) => e
                                                        as Map<String, dynamic>,
                                                  )
                                                  .toList(),
                                          position: Offset(x,
                                              y), // or the appropriate position
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
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
