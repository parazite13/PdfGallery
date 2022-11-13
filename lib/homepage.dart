import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import 'model.dart';
import 'pdfviewpage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  List<PdfCategory> pdfCategories = <PdfCategory>[];

  PdfCategory? selectedCategory;
  PdfFile? selectedFile;

  @override
  void initState() {
    getPdfCategories();
    super.initState();
  }

  void getPdfCategories() async
  {
    var pdfCategories = <PdfCategory>[];
    Directory directory;
    if(Platform.isWindows)
    {
      directory = Directory(path.join((await getApplicationDocumentsDirectory()).path, "PdfGallery"));
      directory.create();
    }
    else
    {
      directory = await getExternalStorageDirectory() as Directory;
    }

    final List<FileSystemEntity> entities = await directory.list().toList();
    for(var entity in entities)
    {
      if(entity is Directory)
      {
        final pdfCategory = PdfCategory();
        pdfCategory.name = entity.path.split(Platform.pathSeparator).last;
        pdfCategory.path = entity.path;
        final List<FileSystemEntity> subEntities = await entity.list().toList();
        for(var subEntity in subEntities)
        {
          if(subEntity is File)
          {
            if(subEntity.path.endsWith(".pdf"))
            {
              final pdfFile = PdfFile();
              pdfFile.name = subEntity.path.split(Platform.pathSeparator).last.split(".").first;
              pdfFile.path = subEntity.path;
              pdfCategory.files.add(pdfFile);
            }
          }
        }
        pdfCategories.add(pdfCategory);
      }
    }

    setState(() {
      this.pdfCategories = pdfCategories;
    });
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title)
      ),
      drawer: Drawer(
          child: ListView(
            children: pdfCategories.map((e) => ListTile(
              title: Text(e.name),
              onTap: () => {
                setState(() => {
                  selectedFile = selectedCategory?.files[0],
                  selectedCategory = e,
                })
              },
            )).toList(),
          )
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Center(
                child: Text(
                  selectedCategory == null ? "" : selectedCategory!.name,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
              )
            )
          ),
          Expanded(
            flex: 1,
            child: selectedCategory == null ? const Center(child: Text("Select a category")) : CarouselSlider.builder(
              itemCount: selectedCategory?.files.length,
              options: CarouselOptions(
                height: double.maxFinite,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
                enlargeCenterPage: true,
                onPageChanged: (index, reason) {
                  setState(() {
                    selectedFile = selectedCategory?.files[index];
                  });
                },
              ),
              itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
                Card(
                  color: Colors.white54,
                  elevation: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          selectedCategory!.files[itemIndex].name,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      selectedCategory?.files[itemIndex].bytes == null ?
                      FutureBuilder(
                          future: PdfDocument.openFile(selectedCategory!.files[itemIndex].path)
                              .then((document) => document.getPage(1))
                              .then((page) => page.render(width: page.width / 2, height: page.height / 2)),
                          builder: (context, snapshot) {
                            if(selectedCategory?.files[itemIndex].bytes == null && snapshot.connectionState == ConnectionState.done && snapshot.hasData)
                            {
                              selectedCategory?.files[itemIndex].bytes = snapshot.data?.bytes;
                            }
                            if(selectedCategory?.files[itemIndex].bytes != null)
                            {
                              return Expanded(
                                  flex: 1,
                                  child: Image.memory(selectedCategory!.files[itemIndex].bytes as Uint8List)
                              );
                            }
                            return const Center(
                                child: CircularProgressIndicator()
                            );
                          }
                      ) :
                      Expanded(
                        flex: 1,
                        child: Image.memory(selectedCategory!.files[itemIndex].bytes as Uint8List)
                      ),
                      ButtonBarTheme ( // make buttons use the appropriate styles for cards
                        data: const ButtonBarThemeData(),
                        child: ButtonBar(
                          alignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text('Open'),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => PdfViewPage(pdf: selectedCategory!.files[itemIndex])));
                              },
                            ),
                            TextButton(
                              child: const Text('Share'),
                              onPressed: () {
                                Share.shareXFiles([XFile(selectedCategory!.files[itemIndex].path)], text: selectedCategory!.files[itemIndex].name);
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  )
              ),
            ),
          )
        ]
      ),
    );
  }
}