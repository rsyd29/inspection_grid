import 'package:flutter/material.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';

import '../../services/pick_image_service.dart';

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
        title: Text(
          widget.part['partName'],
        ),
      ),
      body: ListView(
        children: (widget.part['components'] as List)
            .map(
              (e) => Column(
                children: [
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(6),
                              left: Radius.circular(6),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              e['componentName'],
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        ...(e['damageOptions'] as List).map(
                          (damage) => Column(
                            children: [
                              CheckboxListTile(
                                title: Text(
                                  '${damage['damageType']}',
                                ),
                                subtitle: Text(
                                  'maksimal gambar ${damage['limit']} kerusakan',
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                                value: selectedDamages.contains(damage),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      selectedDamages.add(damage);
                                      damageImagesControllers[
                                              damage['damageType']] =
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
                                  height:
                                      MediaQuery.of(context).size.height * 0.2,
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
                                      return Stack(
                                        children: [
                                          Positioned.fill(
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
                  Divider(),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
