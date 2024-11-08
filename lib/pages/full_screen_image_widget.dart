import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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
                '${_currentPage + 1} / ${widget.imagePaths.length}',
                // Display dynamic currentPage
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
