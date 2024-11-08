import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'full_screen_image_widget.dart';

class CarouselDialogContent extends StatelessWidget {
  const CarouselDialogContent({
    super.key,
    required this.cache,
    required this.gridIndex,
    required this.items,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd,
  });

  final String? cache;
  final int gridIndex;
  final List<Map<String, dynamic>> items;
  final Function(int) onDelete;
  final Function(int, Map<String, dynamic>) onEdit;
  final Function() onAdd;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Inspection Details Component',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              /*
              CarouselSlider(
                options: CarouselOptions(
                  height: 300.0,
                  enableInfiniteScroll: true,
                  enlargeCenterPage: false,
                  autoPlay: true,
                ),
                // ... existing code ...

                items: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  // Update to handle `values` list
                  final valueWidgets = item['values'].map<Widget>((valueItem) {
                    return Column(
                      children: [
                        // Use CarouselSlider for images
                        Container(
                          height: 150.0,
                          child: CarouselSlider.builder(
                            itemCount: valueItem['images'].length,
                            itemBuilder: (context, imageIndex, realIndex) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.file(
                                  File(valueItem['images'][imageIndex]),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(child: Text("Image not found"));
                                  },
                                ),
                              );
                            },
                            options: CarouselOptions(
                              enableInfiniteScroll: true,
                              enlargeCenterPage: true,
                              autoPlay: true,
                            ),
                          ),
                        ),
                        // ... unchanged code ...
                      ],
                    );
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageView(
                            imagePaths: [valueItem['images']], // Updated field
                            initialPage: 0,
                            keyText: item['key'],
                            valueText: valueItem['answer'],
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(valueItem['images']), // Single image path
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(child: Text("Image not found"));
                            },
                          ),
                        ),
                      ),
                    );

                    return Column(
                      children: [
                        // Single Image for each value item
                        Expanded(
                          child:
                              imageWidgets, // Directly use imageWidgets widget
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "${valueItem['answer']}",
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }).toList();

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "${item['key']}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Combine all images with answers into a carousel
                        Expanded(
                          child: CarouselSlider(
                            items: valueWidgets,
                            options: CarouselOptions(
                              height: 200.0,
                              enableInfiniteScroll: true,
                              enlargeCenterPage: false,
                              autoPlay: true,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                onEdit(gridIndex, item);
                              },
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                onDelete(index);
                              },
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
               */
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
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
                              '${index + 1}. ${item['key'].toString().replaceAll('_', ' ')}',
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
                              children: item['values'].map<Widget>((valueItem) {
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
                                              imagePaths: List<String>.from(
                                                  valueItem['images']),
                                              initialPage: 0,
                                              keyText: item['key'],
                                              valueText: valueItem['answer'],
                                            ),
                                          ),
                                        ),
                                        child: SizedBox(
                                          height: 150.0,
                                          child: PhotoViewGallery.builder(
                                            itemCount:
                                                valueItem['images'].length,
                                            builder: (context, index) {
                                              return PhotoViewGalleryPageOptions(
                                                imageProvider: FileImage(File(
                                                    valueItem['images']
                                                        [index])),
                                                minScale: PhotoViewComputedScale
                                                    .contained,
                                                maxScale: PhotoViewComputedScale
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
                                                '${valueItem['answer']}',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontStyle:
                                                        FontStyle.italic),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                'Ada ${valueItem['images'].length} kerusakan',
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    onEdit(gridIndex, item);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    onDelete(index);
                                  },
                                ),
                              ],
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
                    onAdd();
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
    );
  }
}
