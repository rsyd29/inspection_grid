import 'package:flutter/material.dart';
import 'package:inspection_grid/pages/concept_3_pages/dynamic_inspection_with_concept_3.dart';
import 'package:inspection_grid/pages/dynamic_inspection_with_grid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Page Inspection With',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Page Inspection With'),
          centerTitle: true,
        ),
        body: Center(
          child: Builder(
            builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /*
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const DynamicInspectionWithRowColumn()),
                    );
                  },
                  child: Text(
                    'Page Inspection with Row and Column',
                  ),
                ),
                 */
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DynamicInspectionWithGrid(
                          title: 'Grid\n(Konsep 1 + Konsep 2)',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Grid\n(Konsep 1 + Konsep 2)',
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const DynamicInspectionWithConcept3(
                          title: 'Thumbnail\n(Konsep 3)',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Thumbnail\n(Konsep 3)\nOn Progress',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
