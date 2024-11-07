import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inspection_grid/services/pick_image_service.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';

import '../generated/assets.dart';
import '../services/merged_object_service.dart';
import '../services/secure_storage_service.dart';

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
  List<String> selectedDamages = [];
  Map<String, MultiImagePickerController> damageImagesControllers = {};
  String? selectedValue;
  late MultiImagePickerController controller;

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
      setState(() {
        selectedValue = widget.item?['key'];
        keyObject = (widget.item != null)
            ? {
                'key': widget.item?['key'],
                'x': widget.item?['x'],
                'y': widget.item?['y'],
              }
            : null;

        // Set initial selected damages
        var valuesList = widget.item?['values'] ?? [];
        selectedDamages = [
          for (var item in valuesList)
            if (item is Map<String, dynamic>) item['answer'] as String
        ];

        for (var damage in selectedDamages) {
          final controller = getOrCreateController(damage);
          final imagePaths = [
            for (var value in valuesList)
              if (value is Map<String, dynamic> && value['answer'] == damage)
                ...(value['image'] is String
                    ? [value['image']]
                    : value['image'] as List<String>? ?? [])
          ];

          for (var path in imagePaths) {
            final fileName = path.split('/').last;
            final fileExtension = fileName.split('.').last;

            controller.updateImages(
              [
                ImageFile(
                  path.hashCode.toString(),
                  name: fileName,
                  extension: fileExtension,
                  path: path,
                ),
              ],
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in damageImagesControllers.values) {
      controller.removeListener(_updateImages);
    }
    super.dispose();
  }

  // Use the damage as a key to access the respective controller
  MultiImagePickerController getOrCreateController(String damage) {
    if (!damageImagesControllers.containsKey(damage)) {
      damageImagesControllers[damage] = MultiImagePickerController(
        picker: (allowMultiple) async {
          final pickedImages = await pickImagesUsingImagePicker(allowMultiple);
          return pickedImages;
        },
        maxImages: 1,
      );
      damageImagesControllers[damage]?.addListener(_updateImages);
    }
    return damageImagesControllers[damage]!;
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return FutureBuilder(
      future: getJson(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(); // Tampilkan loading jika ukuran gambar belum didapat
        }
        final data = snapshot.data?['${widget.index}'];

        if (data == null) return Text('No Data Available');
        return Material(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Pertanyaan Component'.toUpperCase()),
                  ),
                  DropdownButtonFormField(
                    value: selectedValue,
                    isExpanded: true,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: Colors.black,
                    ),
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
                      });
                    },
                  ),
                  Visibility(
                    visible: keyObject != null,
                    child: Column(
                      children: ((data['listComponent'] as List)
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
                              value: selectedDamages.contains(e['answer']),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    selectedDamages.add(e['answer']);
                                    damageImagesControllers[e['answer']] =
                                        getOrCreateController(e['answer']);
                                  } else {
                                    selectedDamages.remove(e['answer']);
                                    damageImagesControllers.remove(e['answer']);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Visibility(
                    visible: selectedDamages.isNotEmpty,
                    child: Column(
                      children: selectedDamages
                          .map(
                            (damage) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Images for damage: $damage'),
                                SizedBox(
                                    width: double.infinity,
                                    height: height * 0.2,
                                    child: MultiImagePickerView(
                                      controller: getOrCreateController(damage),
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
                                        return Stack(children: [
                                          Positioned.fill(
                                            child: ImageFileView(
                                              imageFile: imageFile,
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
                                                  Icons.delete_forever_rounded,
                                                  size: 18,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                                ),
                                              ),
                                            ),
                                          )
                                        ]);
                                      },
                                    )),
                                const SizedBox(
                                  height: 10,
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Visibility(
                    visible: damageImagesControllers.isNotEmpty,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Map<String, dynamic> dataCache = widget.cache == null
                              ? {}
                              : jsonDecode(widget.cache!);

                          // Extract existing data for the current index, if any
                          List<Map<String, dynamic>> existingEntries =
                              (dataCache['${widget.index}'] as List<dynamic>?)
                                      ?.cast<Map<String, dynamic>>() ??
                                  [];

                          // Inside ElevatedButton onPressed:
                          for (var damage in selectedDamages) {
                            Map<String, dynamic> damageEntry = {
                              'answer': damage,
                              'image': damageImagesControllers[damage]
                                  ?.images
                                  .firstOrNull
                                  ?.path,
                            };

                            var entryIndex = existingEntries.indexWhere(
                              (entry) => entry['key'] == keyObject?['key'],
                            );

                            if (entryIndex != -1) {
                              // Update existing entry
                              var valuesList = (existingEntries[entryIndex]
                                      ['values'] as List)
                                  .map((item) => item as Map<String, dynamic>)
                                  .toList();
                              var existingDamageIndex = valuesList.indexWhere(
                                (item) => item['answer'] == damage,
                              );

                              if (existingDamageIndex != -1) {
                                // Update image for existing damage
                                valuesList[existingDamageIndex]['image'] =
                                    damageEntry['image'];
                              } else {
                                // Add new damageEntry if it doesn't exist
                                valuesList.add(damageEntry);
                              }

                              existingEntries[entryIndex]['values'] =
                                  valuesList;
                            } else {
                              // Add new entry if key is not found
                              existingEntries.add({
                                'key': keyObject?['key'],
                                'values': [damageEntry],
                                'x': keyObject?['x'],
                                'y': keyObject?['y'],
                              });
                            }
                          }

                          // Save updated entries back to dataCache
                          dataCache['${widget.index}'] = existingEntries;

                          Map<String, dynamic> dataMergedObject =
                              mergeObjects(dataCache, {});

                          Navigator.pop(context);

                          SecureStorageService sss = SecureStorageServiceImpl(
                            flutterSecureStorage: FlutterSecureStorage(),
                          );

                          final cacheKey = await sss.cacheKeyWithValue(
                            key: 'task',
                            value: jsonEncode(dataMergedObject),
                          );

                          print('data: $dataMergedObject');
                        },
                        child: Text('Simpan'),
                      ),
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

  Future<Map<String, dynamic>> getJson() async {
    final result =
        await DefaultAssetBundle.of(context).loadString(Assets.jsonInspection);
    return jsonDecode(result);
  }
}
