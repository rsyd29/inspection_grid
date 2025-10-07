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
  List<String> selectedDamages = [];
  Map<String, MultiImagePickerController> damageImagesControllers = {};
  Map<String, String> imageNotes = {};
  late MultiImagePickerController controller;

  void _updateImages() {
    setState(() {});
  }

  // Instantiate SecureStorageService
  final SecureStorageService secureStorageService = SecureStorageServiceImpl(
    flutterSecureStorage: FlutterSecureStorage(),
  );

  MultiImagePickerController getOrCreateController(
    Map<String, dynamic> damage,
  ) {
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

  void _loadDataFromLocalStorage() async {
    try {
      final storedData = await secureStorageService.getKey(key: 'thumbnail');
      if (storedData != null) {
        final Map<String, dynamic> rawData = jsonDecode(storedData);
        final data =
            rawData.map<String, List<Map<String, dynamic>>>((key, value) {
          return MapEntry(
            key,
            List<Map<String, dynamic>>.from(value),
          );
        });

        selectedDamages = [];
        for (var component in widget.part['components']) {
          String componentIdStr = component['componentId'].toString();
          String partIdStr = widget.part['partId'].toString();
          if (data.containsKey(partIdStr)) {
            for (var damageOptionData in data[partIdStr]!) {
              if (componentIdStr ==
                  damageOptionData['componentId'].toString()) {
                // Check componentId
                for (var damageData in damageOptionData['damageOptions']) {
                  for (var damageOption in component['damageOptions']) {
                    if (damageOption['damageType'] ==
                        damageData['damageType']) {
                      selectedDamages.add(jsonEncode({
                        'componentName': component['componentName'],
                        'damageOption': damageOption,
                      }));
                      MultiImagePickerController controller =
                          getOrCreateController(damageOption);

                      final imagePaths = [];
                      // Initialize MultiImagePickerView from `damages`
                      if (damageData['damages'] != null) {
                        for (var damage in damageData['damages']) {
                          String path = damage['imagePath'];
                          imageNotes[path] = damage['note'] ?? '';
                          imagePaths.add(path);
                        }
                      }

                      final imageFiles = imagePaths.map((path) {
                        final fileName = path.split('/').last;
                        final fileExtension = fileName.split('.').last;

                        return ImageFile(
                          path.hashCode.toString(),
                          name: fileName,
                          extension: fileExtension,
                          path: path,
                        );
                      }).toList();

                      controller.updateImages(imageFiles);
                    }
                  }
                }
              }
            }
          }
        }

        print(selectedDamages.toString());
        setState(() {});
      }
    } catch (e, s) {
      print('Error loading data: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDataFromLocalStorage();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
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
                          value: (selectedDamages.contains(jsonEncode({
                            'componentName': e['componentName'],
                            'damageOption': damage,
                          }))),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedDamages.add(jsonEncode({
                                  'componentName': e['componentName'],
                                  'damageOption': damage
                                }));
                                damageImagesControllers[damage['damageType']] =
                                    getOrCreateController(damage);
                              } else {
                                selectedDamages.remove(jsonEncode({
                                  'componentName': e['componentName'],
                                  'damageOption': damage,
                                }));
                                damageImagesControllers
                                    .remove(damage['damageType']);
                              }
                            });
                          },
                        ),
                        if (selectedDamages.contains(jsonEncode({
                          'componentName': e['componentName'],
                          'damageOption': damage,
                        })))
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.2,
                            child: MultiImagePickerView(
                              controller: damageImagesControllers[
                                      damage['damageType']] ??
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
                                                    images: [
                                                      {
                                                        'path': imageFile.path!,
                                                        'note': imageNotes[
                                                            imageFile.path],
                                                      },
                                                    ],
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
                                                backgroundColor:
                                                    Theme.of(context)
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
                                                padding:
                                                    const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                      .withOpacity(0.4),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 18,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 4,
                                            right: 4,
                                            child: InkWell(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) {
                                                    String note = imageNotes[
                                                            imageFile.path] ??
                                                        "";
                                                    return AlertDialog(
                                                      title: Text(
                                                          'Tambah Catatan'),
                                                      content: TextField(
                                                        controller:
                                                            TextEditingController(
                                                                text: note),
                                                        onChanged: (value) {
                                                          imageNotes[imageFile
                                                              .path!] = value;
                                                        },
                                                        decoration:
                                                            InputDecoration(
                                                          hintText:
                                                              "Masukkan catatan disini.",
                                                        ),
                                                        maxLines:
                                                            null, // Allows multiple lines of input
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(ctx)
                                                                  .pop(),
                                                          child: Text('Cancel'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            // Save the note
                                                            Navigator.of(ctx)
                                                                .pop();
                                                          },
                                                          child: Text('Save'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      LinearGradient(colors: [
                                                    Colors.blueAccent,
                                                    Colors.blue,
                                                  ]),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.blue
                                                          .withOpacity(0.5),
                                                      spreadRadius: 2,
                                                      blurRadius: 5,
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.note_add_rounded,
                                                  size: 24,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
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
            onPressed:
                _saveDataToLocalStorage, // Define this method to save data
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).primaryColor, // Background color
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
      ),
    );
  }

  List<String> _missingImagesInformation() {
    List<String> missingInformations = [];

    for (var component in widget.part['components']) {
      for (var damageOption in component['damageOptions']) {
        if (selectedDamages.contains(jsonEncode({
          'componentName': component['componentName'],
          'damageOption': damageOption,
        }))) {
          var controller = damageImagesControllers[damageOption['damageType']];
          if (controller == null || controller.images.isEmpty) {
            missingInformations.add(
                '${component['componentName']} - ${damageOption['damageType']}');
          }
        }
      }
    }

    return missingInformations;
  }

  void _saveDataToLocalStorage() async {
    try {
      final missingInformations = _missingImagesInformation();

      if (missingInformations.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Please upload at least one image for the following items:'),
                ...missingInformations.asMap().entries.map((entry) {
                  int index = entry.key;
                  String info = entry.value;
                  return Text('${index + 1}. $info');
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Retrieve existing data from local storage
      final storedData = await secureStorageService.getKey(key: 'thumbnail');
      Map<String, List<Map<String, dynamic>>> dataToSave = {};

      if (storedData != null) {
        dataToSave = (jsonDecode(storedData) as Map<String, dynamic>)
            .map<String, List<Map<String, dynamic>>>((key, value) {
          return MapEntry(
            key,
            List<Map<String, dynamic>>.from(value),
          );
        });
      }

      for (var component in widget.part['components']) {
        List<Map<String, dynamic>> damageData = [];

        for (var damageOption in component['damageOptions']) {
          if (selectedDamages.contains(jsonEncode({
            'componentName': component['componentName'],
            'damageOption': damageOption,
          }))) {
            List<Map<String, dynamic>> damageDetails = [];
            var controller =
                damageImagesControllers[damageOption['damageType']];
            if (controller != null) {
              for (var img in controller.images) {
                damageDetails.add({
                  'imagePath': img.path,
                  'note': imageNotes[img.path] ?? '',
                });
              }
            }

            damageData.add({
              'damageType': damageOption['damageType'],
              'damages': damageDetails,
            });
          }
        }

        if (damageData.isNotEmpty) {
          dataToSave.update(
            widget.part['partId'].toString(),
            (existing) {
              // Check for existing component entry and update
              final index = existing.indexWhere(
                  (map) => map['componentId'] == component['componentId']);
              if (index >= 0) {
                existing[index]['damageOptions'] = damageData;
                return existing;
              } else {
                // Add new component entry
                return [
                  ...existing,
                  {
                    'componentId': component['componentId'],
                    'componentName': component['componentName'],
                    'damageOptions': damageData,
                    'x': component['x'],
                    'y': component['y'],
                  }
                ];
              }
            },
            // Add new part entry if it doesn't exist
            ifAbsent: () => [
              {
                'componentId': component['componentId'],
                'componentName': component['componentName'],
                'damageOptions': damageData,
                'x': component['x'],
                'y': component['y'],
              }
            ],
          );
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
