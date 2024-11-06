import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inspection_grid/pages/show_dialog_question.dart';
import 'package:inspection_grid/services/secure_storage_service.dart';

import 'show_dialog_image.dart';

class DynamicInspectionWithGrid extends StatefulWidget {
  const DynamicInspectionWithGrid({super.key});

  @override
  State<DynamicInspectionWithGrid> createState() =>
      _DynamicInspectionWithGridState();
}

class _DynamicInspectionWithGridState extends State<DynamicInspectionWithGrid> {
  final int itemCount = 16; // Jumlah total cell dalam grid
  List<bool> gridStatus = []; // Status setiap cell dalam grid
  dynamic resultJson;
  Map<String, dynamic>? valueJson;

  SecureStorageService sss = SecureStorageServiceImpl(
    flutterSecureStorage: FlutterSecureStorage(),
  );

  @override
  void initState() {
    super.initState();
    gridStatus = List.filled(itemCount, false); // Inisialisasi status grid
  }

  void showCarouselDialog(
    BuildContext context,
    String key,
    List<Map<String, dynamic>> items,
    String? cache,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: CarouselDialogContent(
            items: items,
            onDelete: (p0) async {
              setState(() {
                items.removeAt(p0);
              });

              // Merge cached data with new changes
              Map<String, dynamic>? dataCache =
                  cache == null ? {} : jsonDecode(cache);

              if (items.isEmpty) {
                dataCache?.remove(key);
              } else {
                Map<String, dynamic>? dataSaving = {
                  key: items,
                };

                dataCache = {
                  ...?dataCache,
                  ...dataSaving,
                };
              }

              Navigator.of(context).pop();

              final cacheKey = await sss.cacheKeyWithValue(
                key: 'task',
                value: jsonEncode(dataCache),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sss.getKey(key: 'task'),
      builder: (context, snapshot) {
        final cache = snapshot.data;
        Map<String, dynamic>? objectData =
            cache == null ? {} : jsonDecode(cache);
        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () async {
                await sss.getKey(key: 'task');
              },
              child: Text("Dynamic Inspection with Grid"),
            ),
          ),
          body: Center(
            child: FutureBuilder<Size>(
              // Ambil ukuran asli gambar
              future: _getImageSize('assets/images/mobil.png'),
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

                    return Stack(
                      children: [
                        // Gambar yang disesuaikan dengan aspect ratio dinamis
                        Image.asset(
                          'assets/images/mobil.png',
                          width: imageWidth,
                          height: imageHeight,
                          fit: BoxFit.cover,
                        ),
                        ...objectData?.entries.expand((entry) {
                              List<dynamic> positions = entry.value;
                              return positions.map<Widget>((position) {
                                int x = position['x'];
                                int y = position['y'];
                                return Positioned(
                                  left: x.toDouble(),
                                  top: y.toDouble(),
                                  child: Container(
                                    width: 10.0,
                                    height: 10.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                    ),
                                  ),
                                );
                              });
                            }) ??
                            [],
                        GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4, // Jumlah kolom
                            childAspectRatio: aspectRatio,
                          ),
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) => ShowDialogQuestion(
                                    index: index,
                                    cache: cache,
                                  ),
                                );
                                setState(() {});
                              },
                              onLongPress:
                                  (objectData?.keys.contains('$index') ?? false)
                                      ? () {
                                          List<Map<String, dynamic>> data =
                                              (objectData?['$index'] as List)
                                                  .map<Map<String, dynamic>>(
                                                    (e) => e
                                                        as Map<String, dynamic>,
                                                  )
                                                  .toList();
                                          final items = data;
                                          showCarouselDialog(
                                            context,
                                            '$index',
                                            items,
                                            cache,
                                          );
                                        }
                                      : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  color: (objectData?.keys.contains('$index') ??
                                          false)
                                      ? Colors.red.withOpacity(0.5)
                                      : Colors.transparent,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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
