import 'dart:async';

import 'package:flutter/material.dart';

class DynamicInspectionWithRowColumn extends StatefulWidget {
  const DynamicInspectionWithRowColumn({super.key});

  @override
  State<DynamicInspectionWithRowColumn> createState() =>
      _DynamicInspectionWithRowColumnState();
}

class _DynamicInspectionWithRowColumnState
    extends State<DynamicInspectionWithRowColumn> {
  List<List<bool>> gridStatus = [];
  final int rowCount = 4; // Jumlah baris grid
  final int colCount = 4; // Jumlah kolom grid

  @override
  void initState() {
    super.initState();
    gridStatus = List.generate(rowCount, (_) => List.filled(colCount, false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dynamic Inspection with Row and Column")),
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

                // Hitung ukuran grid
                double gridWidth = imageWidth / colCount;
                double gridHeight = imageHeight / rowCount;

                return Stack(
                  children: [
                    // Gambar yang disesuaikan dengan aspect ratio dinamis
                    Image.asset(
                      'assets/images/mobil.png',
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.cover,
                    ),
                    // Grid overlay di atas gambar
                    for (int row = 0; row < rowCount; row++)
                      for (int col = 0; col < colCount; col++)
                        Positioned(
                          left: col * gridWidth,
                          top: row * gridHeight,
                          width: gridWidth,
                          height: gridHeight,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                gridStatus[row][col] = !gridStatus[row][col];
                              });
                              print('row: $row');
                              print('col: $col');
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.5)),
                                color: gridStatus[row][col]
                                    ? Colors.red.withOpacity(0.5)
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Fungsi untuk mendapatkan ukuran asli gambar
  Future<Size> _getImageSize(String assetPath) async {
    Image image = Image.asset(assetPath);
    Completer<Size> completer = Completer();
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          completer.complete(
            Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            ),
          );
        },
      ),
    );
    return completer.future;
  }
}
