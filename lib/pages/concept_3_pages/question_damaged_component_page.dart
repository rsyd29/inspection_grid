import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';

import '../../services/pick_image_service.dart';
import '../../services/secure_storage_service.dart';
import '../full_screen_image_widget.dart';

class QuestionDamagedComponentPage extends StatefulWidget {
  const QuestionDamagedComponentPage({
    super.key,
    required this.part,
  });
  final Map<String, dynamic> part;

  @override
  State<QuestionDamagedComponentPage> createState() =>
      _QuestionDamagedComponentPageState();
}

class _QuestionDamagedComponentPageState
    extends State<QuestionDamagedComponentPage> {
  List<Map<String, dynamic>> selectedDamages = [];
  Map<String, MultiImagePickerController> damageImagesControllers = {};
  late MultiImagePickerController controller;

  void _updateImages() {
    setState(() {});
  }

  // Instantiate SecureStorageService
  final SecureStorageService secureStorageService = SecureStorageServiceImpl(
    flutterSecureStorage: FlutterSecureStorage(),
  );

  MultiImagePickerController getOrCreateController(
      Map<String, dynamic> damage) {
    if (!damageImagesControllers.containsKey(damage['damageType'])) {
      // Create a new controller with the specified maximum number of images allowed
      damageImagesControllers[damage['damageType']] =
          MultiImagePickerController(
        picker: (allowMultiple) async {
          final pickedImages = await pickImagesUsingImagePicker(allowMultiple);
          return pickedImages;
        },
        maxImages: damage['limit'], // Set maxImages upon creation
      );
      damageImagesControllers[damage['damageType']]?.addListener(_updateImages);
    }
    // Return existing or newly created controller
    return damageImagesControllers[damage['damageType']]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () async {
            final data = await secureStorageService.getKey(key: 'thumbnail');
            print(data);
          },
          child: Text(
            widget.part['partName'],
          ),
        ),
      ),
      body: ListView(
        children: [
          ...(widget.part['components'] as List).map(
            (e) => ExpansionTile(
              title: Text(
                e['componentName'],
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text((e['damageOptions'] as List)
                  .map(
                    (e) => e['damageType'],
                  )
                  .toList()
                  .toString()),
              children: [
                ...(e['damageOptions'] as List).map(
                  (damage) => Column(
                    children: [
                      CheckboxListTile(
                        title: Text(
                          '${damage['damageType']}',
                        ),
                        subtitle: Text(
                          'maksimal ${damage['limit']} gambar kerusakan',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                        value: selectedDamages.contains(damage),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedDamages.add(damage);
                              damageImagesControllers[damage['damageType']] =
                                  getOrCreateController(damage);
                            } else {
                              selectedDamages.remove(damage);
                              damageImagesControllers
                                  .remove(damage['damageType']);
                            }
                          });
                        },
                      ),
                      if (selectedDamages.contains(damage))
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.2,
                          child: MultiImagePickerView(
                            controller:
                                damageImagesControllers[damage['damageType']] ??
                                    getOrCreateController(damage),
                            draggable: true,
                            longPressDelayMilliseconds: 250,
                            onDragBoxDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .shadow
                                      .withOpacity(0.5),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            shrinkWrap: false,
                            padding: const EdgeInsets.all(0),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 170,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                            builder: (context, imageFile) {
                              return (imageFile.path == null)
                                  ? Text('Not have path')
                                  : Stack(
                                      children: [
                                        Positioned.fill(
                                          child: GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    FullScreenImageView(
                                                  imagePaths: [imageFile.path!],
                                                  initialPage: 0,
                                                  keyText: e['componentName'],
                                                  valueText:
                                                      damage['damageType'],
                                                ),
                                              ),
                                            ),
                                            child: ImageFileView(
                                              imageFile: imageFile,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              fit: BoxFit.cover,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              errorBuilder:
                                                  (BuildContext context,
                                                      Object error,
                                                      StackTrace? trace) {
                                                return Text(
                                                  error.toString(),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: DraggableItemInkWell(
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            onPressed: () =>
                                                getOrCreateController(damage)
                                                    .removeImage(imageFile),
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                    .withOpacity(0.4),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.delete_forever_rounded,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    );
                            },
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.1,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: _saveDataToLocalStorage, // Define this method to save data
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor, // Background color
            padding: EdgeInsets.symmetric(vertical: 15.0), // Padding
          ),
          child: Text(
            'Simpan Data', // Button text
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.white,
            ), // Text style
          ),
        ),
      ),
    );
  }

  void _saveDataToLocalStorage() async {
    try {
      // Create the final data structure
      Map<String, List<Map<String, dynamic>>> dataToSave = {};

      for (var component in widget.part['components']) {
        List<Map<String, dynamic>> damageData = [];

        for (var damageOption in component['damageOptions']) {
          if (selectedDamages.contains(damageOption)) {
            List<String> damageImages =
                damageImagesControllers[damageOption['damageType']]
                        ?.images
                        .map((img) => img.path!)
                        .toList() ??
                    [];

            damageData.add({
              'damageType': damageOption['damageType'],
              'damageImages': damageImages,
            });
          }
        }

        if (damageData.isNotEmpty) {
          dataToSave[component['componentId'].toString()] = [
            {
              'componentId': component['componentId'],
              'componentName': component['componentName'],
              'damages': damageData,
              'x': component['x'],
              'y': component['y'],
            }
          ];
        }
      }

      // Convert to JSON string
      String jsonData = jsonEncode(dataToSave);

      // Save JSON data
      bool isSuccess = await secureStorageService.cacheKeyWithValue(
        key: 'thumbnail',
        value: jsonData,
      );

      if (isSuccess) {
        print('Data saved successfully');
        Navigator.of(context).pop();
      } else {
        print('Failed to save data');
      }
    } catch (e) {
      print('Error saving data: $e');
    }
  }
}
