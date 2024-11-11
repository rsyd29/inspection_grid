import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class FullScreenImageView extends StatefulWidget {
  // Change to StatefulWidget
  final List<Map<String, dynamic>> images;
  final int initialPage;
  final String keyText;
  final String valueText;

  const FullScreenImageView({
    super.key,
    required this.images,
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
        actions: [
          Text('${_currentPage + 1} / ${widget.images.length}'),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              itemCount: widget.images.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(
                    File(
                      widget.images[index]['imagePath'] ??
                          widget.images[index]['path'],
                    ),
                  ),
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
              left: 0,
              child: GestureDetector(
                onTap: _showLongTextDialog,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan:', // Optional Label
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width -
                              16, // Adjust width
                        ),
                        child: Text(
                          widget.images[_currentPage]['note'] ?? '',
                          maxLines: 2, // Limit to number of visible lines
                          overflow:
                              TextOverflow.ellipsis, // Ellipsis for overflow
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLongTextDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Catatan'),
          content: SingleChildScrollView(
            child: Text(widget.images[_currentPage]['note'] ?? ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
