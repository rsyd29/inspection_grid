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

  // Function to convert global to local coordinates for the InteractiveViewer
  void _handleTap(
    TapDownDetails details,
    double scaleFactor,
    int componentIndex,
    Map<String, dynamic> data,
  ) async {
    final Offset position = details.localPosition / scaleFactor;

    final listComponent = (data['$componentIndex']['listComponent'] as List)
        .map(
          (e) => e as Map<String, dynamic>,
        )
        .toList();
    print(
      'ListComponent $listComponent, Koordinat: (${position.dx}, ${position.dy})',
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

  SecureStorageService sss = SecureStorageServiceImpl(
    flutterSecureStorage: FlutterSecureStorage(),
  );

  // Add function to create circle widgets from objectData only for specific grid indices
  List<Widget> _buildCoordCircles(
    Map<String, dynamic> data,
    int index, // Adjust the function to accept a single index.
  ) {
    List<Widget> circles = [];
    if (data.containsKey('$index')) {
      final components = data['$index'] as List<dynamic>;
      for (var component in components) {
        double x = component['x'];
        double y = component['y'];

        circles.add(Positioned(
          left: x, // Position adjusted within grid cell
          top: y,
          child: Container(
            width: 10.0,
            height: 10.0,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ));
      }
    }
    return circles;
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
                          boundaryMargin: EdgeInsets.all(20),
                          minScale: 1.0,
                          maxScale: 3.0,
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
                                    onTapDown: (TapDownDetails details) =>
                                        _handleTap(
                                      details,
                                      transformationController.value
                                          .getMaxScaleOnAxis(),
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
                                            color: Colors.transparent,
                                          ),
                                        ),
                                        ..._buildCoordCircles(
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
