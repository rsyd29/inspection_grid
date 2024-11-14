import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';

import '../../services/pick_image_service.dart';
import '../../services/secure_storage_service.dart';
import '../full_screen_image_widget.dart';

class QuestionComponentPage extends StatefulWidget {
  const QuestionComponentPage({
    super.key,
    required this.index,
    required this.listComponent,
    required this.position,
  });
  final int index;
  final List<Map<String, dynamic>> listComponent;
  final Offset? position;

  @override
  State<QuestionComponentPage> createState() => _QuestionComponentPageState();
}

class _QuestionComponentPageState extends State<QuestionComponentPage> {
  List<String> selectedDamages = [];
  Map<String, MultiImagePickerController> damageImagesControllers = {};
  Map<String, String> imageNotes = {};
  late MultiImagePickerController controller;
  // Instantiate SecureStorageService
  final SecureStorageService secureStorageService = SecureStorageServiceImpl(
    flutterSecureStorage: FlutterSecureStorage(),
  );

  void _updateImages() {
    setState(() {});
  }

  MultiImagePickerController getOrCreateController(
    Map<String, dynamic> answer,
  ) {
    if (!damageImagesControllers.containsKey(answer['answer'])) {
      // Create a new controller with the specified maximum number of images allowed
      damageImagesControllers[answer['answer']] = MultiImagePickerController(
        picker: (allowMultiple) async {
          final pickedImages = await pickImagesUsingImagePicker(allowMultiple);
          return pickedImages;
        },
        maxImages: answer['limit'], // Set maxImages upon creation
      );
      damageImagesControllers[answer['answer']]?.addListener(_updateImages);
    }
    // Return existing or newly created controller
    return damageImagesControllers[answer['answer']]!;
  }

  void _loadDataFromLocalStorage() async {
    try {
      final storedData = await secureStorageService.getKey(key: 'grid_dynamic');
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
        damageImagesControllers = {};
        imageNotes = {};

        final componentsForIndex = data[widget.index.toString()];
        if (componentsForIndex != null) {
          List<Map<String, dynamic>> listComponents =
              List<Map<String, dynamic>>.from(componentsForIndex);
          for (var componentVariable in widget.listComponent) {
            for (var componentLocal in listComponents) {
              Offset positionLocal =
                  Offset(componentLocal['x'], componentLocal['y']);
              if (positionLocal == widget.position) {
                for (var answerLocal in componentLocal['answers']) {
                  for (var answerVariable in componentVariable['answers']) {
                    if (answerLocal['answer'] == answerVariable['answer']) {
                      selectedDamages.add(jsonEncode({
                        'section': componentVariable['section'],
                        'componentName': componentVariable['componentName'],
                        'answer': answerVariable,
                      }));

                      MultiImagePickerController controller =
                          getOrCreateController(answerVariable);

                      List<String> imagePaths = [];
                      if (answerLocal['damages'] != null) {
                        for (var damage in answerLocal['damages']) {
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

        setState(() {}); // Update UI with loaded data
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Pertanyaan Komponen'),
            Text('${widget.position}'),
          ],
        ),
      ),
      body: ListView(
        children: [
          ...((widget.listComponent as List).map(
            (e) => ExpansionTile(
              title: Text(
                '${e['section']}\n${e['componentName']}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text((e['answers'] as List)
                  .where((e) => e['answer'] != 'BAIK')
                  .map(
                    (e) => e['answer'],
                  )
                  .toList()
                  .toString()),
              children: [
                ...(e['answers'] as List)
                    .where((e) => e['answer'] != 'BAIK')
                    .map(
                      (answer) => Column(
                        children: [
                          CheckboxListTile(
                            title: Text(
                              '${answer['answer']}',
                            ),
                            subtitle: Text(
                              'maksimal ${answer['limit']} gambar kerusakan',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                            value: (selectedDamages.contains(jsonEncode({
                              'section': e['section'],
                              'componentName': e['componentName'],
                              'answer': answer,
                            }))),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  selectedDamages.add(jsonEncode({
                                    'section': e['section'],
                                    'componentName': e['componentName'],
                                    'answer': answer,
                                  }));
                                  damageImagesControllers[answer['answer']] =
                                      getOrCreateController(answer);
                                } else {
                                  selectedDamages.remove(jsonEncode({
                                    'section': e['section'],
                                    'componentName': e['componentName'],
                                    'answer': answer,
                                  }));
                                  damageImagesControllers
                                      .remove(answer['answer']);
                                }
                              });
                            },
                          ),
                          if (selectedDamages.contains(jsonEncode({
                            'section': e['section'],
                            'componentName': e['componentName'],
                            'answer': answer,
                          })))
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2,
                              child: MultiImagePickerView(
                                controller:
                                    damageImagesControllers[answer['answer']] ??
                                        getOrCreateController(answer),
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
                                                          'path':
                                                              imageFile.path!,
                                                          'note': imageNotes[
                                                              imageFile.path],
                                                        },
                                                      ],
                                                      initialPage: 0,
                                                      keyText:
                                                          e['componentName'],
                                                      valueText:
                                                          answer['answer'],
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
                                                            answer)
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
                                                                Navigator.of(
                                                                        ctx)
                                                                    .pop(),
                                                            child:
                                                                Text('Cancel'),
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
                            ),
                        ],
                      ),
                    )
              ],
            ),
          )),
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

  List<String> _missingImagesInformation() {
    List<String> missingInformations = [];

    for (var listComponent in widget.listComponent) {
      for (var answer in listComponent['answers']) {
        if (selectedDamages.contains(jsonEncode({
          'section': listComponent['section'],
          'componentName': listComponent['componentName'],
          'answer': answer,
        }))) {
          var controller = damageImagesControllers[answer['answer']];
          if (controller == null || controller.images.isEmpty) {
            missingInformations
                .add('${listComponent['componentName']} - ${answer['answer']}');
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
      final storedData = await secureStorageService.getKey(key: 'grid_dynamic');
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

      for (var listComponent in widget.listComponent) {
        List<Map<String, dynamic>> damageData = [];

        for (var answer in listComponent['answers']) {
          if (selectedDamages.contains(jsonEncode({
            'section': listComponent['section'],
            'componentName': listComponent['componentName'],
            'answer': answer,
          }))) {
            List<Map<String, dynamic>> damageDetails = [];
            var controller = damageImagesControllers[answer['answer']];
            if (controller != null) {
              for (var img in controller.images) {
                damageDetails.add({
                  'imagePath': img.path,
                  'note': imageNotes[img.path] ?? '',
                });
              }
            }

            damageData.add({
              'answer': answer['answer'],
              'damages': damageDetails,
            });
          }
        }

        if (damageData.isNotEmpty) {
          dataToSave.update(
            widget.index.toString(),
            (existing) {
              // Check for existing listComponent entry and update
              // final index = existing.indexWhere((map) {
              //   final data =
              //       map['componentName'] == listComponent['componentName'];
              //   return data;
              // });
              // if (index >= 0) {
              //   existing[index]['answers'] = damageData;
              //   return existing;
              // } else {
              // Add new listComponent entry
              return [
                ...existing,
                {
                  'section': listComponent['section'],
                  'componentName': listComponent['componentName'],
                  'answers': damageData,
                  'x': widget.position?.dx,
                  'y': widget.position?.dy,
                }
              ];
              // }
            },
            // Add new part entry if it doesn't exist
            ifAbsent: () => [
              {
                'section': listComponent['section'],
                'componentName': listComponent['componentName'],
                'answers': damageData,
                'x': widget.position?.dx,
                'y': widget.position?.dy,
              }
            ],
          );
        }
      }

      // Convert to JSON string
      String jsonData = jsonEncode(dataToSave);

      // Save JSON data
      bool isSuccess = await secureStorageService.cacheKeyWithValue(
        key: 'grid_dynamic',
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
