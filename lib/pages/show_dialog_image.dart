import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class CarouselDialogContent extends StatelessWidget {
  const CarouselDialogContent({
    super.key,
    required this.gridIndex,
    required this.items,
    required this.onDelete,
    required this.onEdit,
  });

  final int gridIndex;
  final List<Map<String, dynamic>> items;
  final Function(int) onDelete;
  final Function(int, Map<String, dynamic>) onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Inspection Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          CarouselSlider(
            options: CarouselOptions(
              height: 200.0,
              enableInfiniteScroll: true,
              enlargeCenterPage: false,
              autoPlay: true,
            ),
            items: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final imageWidgets = item['images'].map<Widget>((imagePath) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageView(
                        imagePaths: item['images'].cast<String>(),
                        initialPage: item['images'].indexOf(imagePath),
                        keyText: item['key'],
                        valueText: item['value'],
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        File(imagePath),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(child: Text("Image not found"));
                        },
                      ),
                    ),
                  ),
                );
              }).toList();

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: Column(
                  children: [
                    // Display each image prominently
                    Expanded(
                      child: CarouselSlider(
                        items: imageWidgets,
                        options: CarouselOptions(
                          height: 100.0, // Adjusted height
                          enableInfiniteScroll: true,
                          enlargeCenterPage:
                              true, // Enlarge the center page for emphasis
                          autoPlay: true,
                          aspectRatio:
                              16 / 9, // Added aspect ratio for consistency
                          viewportFraction:
                              0.8, // Added viewport fraction for better spacing
                        ),
                      ),
                    ),

                    // Ensure the key and value have distinct style
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4.0,
                        right: 4.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "${index + 1}\n${item['key']}", // Added index here
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "${item['value']}",
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
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
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageView extends StatefulWidget {
  // Change to StatefulWidget
  final List<String> imagePaths;
  final int initialPage;
  final String keyText;
  final String valueText;

  const FullScreenImageView({
    super.key,
    required this.imagePaths,
    required this.initialPage,
    required this.keyText,
    required this.valueText,
  });

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage; // Initialize with given initialPage
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.keyText, style: TextStyle(fontSize: 16)),
            Text(widget.valueText, style: TextStyle(fontSize: 12)),
          ],
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              itemCount: widget.imagePaths.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(widget.imagePaths[index])),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              pageController: _pageController,
              scrollPhysics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              }, // Update currentPage with setState
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Text(
                '${_currentPage + 1} / ${widget.imagePaths.length}', // Display dynamic currentPage
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
