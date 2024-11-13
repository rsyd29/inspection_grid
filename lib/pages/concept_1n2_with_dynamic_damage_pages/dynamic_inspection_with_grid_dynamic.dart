import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../generated/assets.dart';

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

  // Fungsi untuk mendapatkan koordinat dari tap
  void _onTapDown(TapDownDetails details, int componentIndex) {
    final Offset position = details.localPosition;
    print(
        'Komponen $componentIndex, Koordinat: (${position.dx}, ${position.dy})');
  }

  // Function to convert global to local coordinates for the InteractiveViewer
  void _handleTap(
    TapDownDetails details,
    double scaleFactor,
    int componentIndex,
    Map<String, dynamic> data,
  ) {
    final Offset position = details.localPosition / scaleFactor;

    final listComponent = data['$componentIndex'];
    print(
      'ListComponent $listComponent, Koordinat: (${position.dx}, ${position.dy})',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getJson(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(), // Centered loading indicator
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
            title: Text(widget.title),
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
                    final TransformationController transformationController =
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.5),
                                    ),
                                    color: Colors.transparent,
                                  ),
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
