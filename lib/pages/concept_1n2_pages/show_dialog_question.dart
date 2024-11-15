import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inspection_grid/services/pick_image_service.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';

import '../../generated/assets.dart';
import '../../services/merged_object_service.dart';
import '../../services/secure_storage_service.dart';
import '../full_screen_image_widget.dart';

class ShowDialogQuestion extends StatefulWidget {
  final int index;
  final String? cache;
  final Map<String, dynamic>? item;

  const ShowDialogQuestion({
    super.key,
    required this.index,
    required this.cache,
    this.item,
  });

  @override
  State<ShowDialogQuestion> createState() => _ShowDialogQuestionState();
}

class _ShowDialogQuestionState extends State<ShowDialogQuestion> {
  Map<String, dynamic>? keyObject;
  List<(String, int)> selectedDamages = [];
  Map<String, MultiImagePickerController> damageImagesControllers = {};
  String? selectedValue;
  late MultiImagePickerController controller;
  Map<String, String> imageNotes = {};

  _ShowDialogQuestionState()
      : controller = MultiImagePickerController(
          picker: (allowMultiple) async {
            final pickedImages =
                await pickImagesUsingImagePicker(allowMultiple);
            return pickedImages;
          },
          maxImages: 1,
        ) {
    controller.addListener(_updateImages);
  }

  void _updateImages() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _initializeFromWidgetItem();
    }
  }

  @override
  void dispose() {
    for (var controller in damageImagesControllers.values) {
      controller.removeListener(_updateImages);
    }
    super.dispose();
  }

  void _initializeFromWidgetItem() async {
    var jsonData = await getJson();
    setState(() {
      selectedValue = widget.item?['key'];
      keyObject = widget.item == null
          ? null
          : {
              'key': widget.item?['key'],
              'x': widget.item?['x'],
              'y': widget.item?['y'],
            };

      // Set initial selected damages
      var valuesList = widget.item?['values'] ?? [];
      selectedDamages = [];
      for (var i = 0; i < valuesList.length; i++) {
        var item = valuesList[i];

        if (item is Map<String, dynamic>) {
          final listComponent =
              jsonData['${widget.index}']['listComponent'] as List;
          final component = listComponent.firstWhere(
            (element) => element['key'] == widget.item?['key'],
            orElse: () => null,
          );

          final answers = component?['answers'] as List?;
          final answerObject = answers?.firstWhere(
            (element) => element['answer'] == item['answer'],
            orElse: () => null,
          );

          if (answerObject != null) {
            selectedDamages
                .add((item['answer'] as String, answerObject['limit'] as int));
          }
        }
      }

      for (var damage in selectedDamages) {
        final controller = getOrCreateController(damage.$1, damage.$2);
        final imagePaths = [];

        for (var i = 0; i < valuesList.length; i++) {
          var value = valuesList[i];
          if (value is Map<String, dynamic> && value['answer'] == damage.$1) {
            if (value['images'] is String) {
              imagePaths.add(value['images']);
            } else if (value['images'] is List<dynamic>) {
              List<dynamic> imageList = value['images'] as List<dynamic>;
              imagePaths.addAll(imageList
                  .map((image) {
                    if (image is Map<String, dynamic>) {
                      String path = image['path'];
                      String note = image['note'];
                      imageNotes[path] = note;
                      return path;
                    }
                    return null;
                  })
                  .whereType<String>()
                  .toList());
            }
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
    });
  }

  // Use the damage as a key to access the respective controller
  MultiImagePickerController getOrCreateController(String damage, int limit) {
    if (!damageImagesControllers.containsKey(damage)) {
      // Create a new controller with the specified maximum number of images allowed
      damageImagesControllers[damage] = MultiImagePickerController(
        picker: (allowMultiple) async {
          final pickedImages = await pickImagesUsingImagePicker(allowMultiple);
          return pickedImages;
        },
        maxImages: limit, // Set maxImages upon creation
      );
      damageImagesControllers[damage]?.addListener(_updateImages);
    }
    // Return existing or newly created controller
    return damageImagesControllers[damage]!;
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return FutureBuilder(
      future: getJson(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(), // Centered loading indicator
          );
        }
        final data = snapshot.data?['${widget.index}'];

        if (data == null) {
          return Text(
            'No Data Available',
            style: TextStyle(color: Colors.black),
          ); // Styled text
        }
        return Material(
          color: Colors.grey[100], // Background color
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Pertanyaan Component'.toUpperCase(),
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  DropdownButtonFormField(
                    value: selectedValue,
                    isExpanded: true,
                    style: TextStyle(color: Colors.black),
                    // Improved typography
                    decoration: InputDecoration(
                      helperText: 'Silahkan pilih component terlebih dahulu.',
                    ),
                    items: (data['listComponent'] as List)
                        .map<DropdownMenuItem<String>>(
                          (e) => DropdownMenuItem(
                            value: e['key'],
                            child: Text(
                              '${e['section']} - ${e['key']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        keyObject = (data['listComponent'] as List).firstWhere(
                          (element) => element['key'] == value,
                          orElse: () => {'key': value}, // Added fallback
                        );
                        selectedDamages.clear();
                      });
                    },
                  ),
                  Visibility(
                    visible: keyObject != null,
                    child: Column(
                      children: [
                        Divider(),
                        ...((data['listComponent'] as List)
                                    .where(
                                      (element) =>
                                          element['key'] == keyObject?['key'],
                                    )
                                    .toList()
                                    .firstOrNull?['answers'] ??
                                [])
                            .where((e) => e['answer'] != 'BAIK')
                            .map<Widget>(
                              (e) => CheckboxListTile(
                                title: Text(e['answer']),
                                value: selectedDamages
                                    .contains((e['answer'], e['limit'])),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      selectedDamages.add((
                                        e['answer'] as String,
                                        e['limit'] as int
                                      ));
                                      damageImagesControllers[e['answer']] =
                                          getOrCreateController(
                                        e['answer'],
                                        e['limit'],
                                      );
                                    } else {
                                      selectedDamages.remove((
                                        e['answer'] as String,
                                        e['limit'] as int
                                      ));
                                      damageImagesControllers
                                          .remove(e['answer']);
                                    }
                                  });
                                },
                              ),
                            )
                      ],
                    ),
                  ),
                  Visibility(
                    visible: selectedDamages.isNotEmpty,
                    child: Column(
                      children: [
                        Divider(),
                        ...selectedDamages.map(
                          (damage) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Images for damage: $damage'),
                              SizedBox(
                                  width: double.infinity,
                                  height: height * 0.2,
                                  child: MultiImagePickerView(
                                    controller: getOrCreateController(
                                        damage.$1, damage.$2),
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
                                      return Stack(
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
                                                      }
                                                    ],
                                                    initialPage: 0,
                                                    keyText: keyObject?['key'],
                                                    valueText: damage.$1,
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
                                                  getOrCreateController(
                                                          damage.$1, damage.$2)
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
                                                  Icons.delete_forever_rounded,
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
                                  )),
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Visibility(
                    visible: damageImagesControllers.isNotEmpty,
                    child: Column(
                      children: [
                        Divider(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                  Colors.blueAccent), // Updated button style
                              padding: WidgetStateProperty.all<EdgeInsets>(
                                  EdgeInsets.symmetric(vertical: 12.0)),
                              shape: WidgetStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.0))),
                            ),
                            onPressed: _saveDataToLocalStorage,
                            child: Text(
                              'Simpan',
                              style: TextStyle(color: Colors.white),
                            ), // Updated button text style
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveDataToLocalStorage() async {
    try {
      bool hasIncompleteUploads = false;
      StringBuffer incompleteDetails = StringBuffer();
      int counter = 1;

      // Check for incomplete image uploads
      for (var damage in selectedDamages) {
        var controller = damageImagesControllers[damage.$1];
        if (controller == null || controller.images.isEmpty) {
          hasIncompleteUploads = true;

          // Append missing information ('key' and 'answer')
          incompleteDetails
              .writeln('${counter++}. ${keyObject?['key']} - ${damage.$1}');
        }
      }

      if (hasIncompleteUploads) {
        // Show dialog with missing information
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(
                'The following entries are missing images:\n\n$incompleteDetails'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return; // Stop further execution
      }

      Map<String, dynamic> dataCache =
          widget.cache == null ? {} : jsonDecode(widget.cache!);

      List<Map<String, dynamic>?> existingEntries =
          (dataCache['${widget.index}'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

      for (var damage in selectedDamages) {
        List<Map<String, dynamic>> imageDetails = [];
        var controller = damageImagesControllers[damage.$1];
        if (controller != null) {
          for (var img in controller.images) {
            imageDetails.add({
              'path': img.path,
              'note': imageNotes[img.path] ?? '',
            });
          }
        }

        Map<String, dynamic> damageEntry = {
          'answer': damage.$1,
          'images': imageDetails,
        };

        var entryIndex = existingEntries.indexWhere(
          (entry) => entry?['key'] == keyObject?['key'],
        );

        if (entryIndex != -1) {
          var valuesList = (existingEntries[entryIndex]?['values'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          var existingDamageIndex = valuesList.indexWhere(
            (item) => item['answer'] == damage.$1,
          );

          if (existingDamageIndex != -1) {
            // Update image for existing damage
            valuesList[existingDamageIndex]['images'] = damageEntry['images'];
          } else {
            // Add new damageEntry if it doesn't exist
            valuesList.add(damageEntry);
          }

          existingEntries[entryIndex]?['values'] = valuesList;
        } else {
          // If key is not found, you can choose to handle this
          // situation separately or keep the logic as needed.
          existingEntries.add({
            'key': keyObject?['key'],
            'values': [damageEntry],
            'x': keyObject?['x'],
            'y': keyObject?['y'],
          });
        }
      }

      dataCache['${widget.index}'] = existingEntries;

      Map<String, dynamic> dataMergedObject = mergeObjects(dataCache, {});

      Navigator.pop(context);

      SecureStorageService sss = SecureStorageServiceImpl(
        flutterSecureStorage: FlutterSecureStorage(),
      );

      final cacheKey = await sss.cacheKeyWithValue(
        key: 'task',
        value: jsonEncode(dataMergedObject),
      );

      print('data: $dataMergedObject');
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
    }
  }

  Future<Map<String, dynamic>> getJson() async {
    final result =
        await DefaultAssetBundle.of(context).loadString(Assets.jsonInspection);
    return jsonDecode(result);
  }
}
