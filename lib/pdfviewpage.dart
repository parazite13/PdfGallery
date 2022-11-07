import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import 'model.dart';

class PdfViewPage extends StatefulWidget {
  const PdfViewPage({super.key, required this.pdf});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final PdfFile pdf;

  @override
  State<PdfViewPage> createState() => PdfViewPageState();
}

class PdfViewPageState extends State<PdfViewPage> {

  PdfControllerPinch? pdfControllerOther;
  PdfController? pdfControllerWindows;

  BasePdfController getPdfController()
  {
    return (Platform.isWindows ? pdfControllerWindows : pdfControllerOther) as BasePdfController;
  }

  @override
  void initState() {
    if(Platform.isWindows)
    {
      pdfControllerWindows = PdfController(
        document: PdfDocument.openFile(widget.pdf.path),
        initialPage: 1,
      );
    }
    else
    {
      pdfControllerOther = PdfControllerPinch(
        document: PdfDocument.openFile(widget.pdf.path),
        initialPage: 1,
      );
    }
    super.initState();
  }

  @override
  void dispose() {
    pdfControllerWindows?.dispose();
    pdfControllerOther?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdf.name),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: () {
              pdfControllerWindows?.previousPage(
                curve: Curves.ease,
                duration: const Duration(milliseconds: 100),
              );
              pdfControllerOther?.previousPage(
                curve: Curves.ease,
                duration: const Duration(milliseconds: 100),
              );
            },
          ),
          PdfPageNumber(
            controller: getPdfController(),
            builder: (_, loadingState, page, pagesCount) => Container(
              alignment: Alignment.center,
              child: Text(
                '$page/${pagesCount ?? 0}',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: () {
              pdfControllerWindows?.nextPage(
                curve: Curves.ease,
                duration: const Duration(milliseconds: 100),
              );
              pdfControllerOther?.nextPage(
                curve: Curves.ease,
                duration: const Duration(milliseconds: 100),
              );
            },
          ),
        ],
      ),
      body: Platform.isWindows ? PdfView(
          builders: PdfViewBuilders<DefaultBuilderOptions>(
            options: const DefaultBuilderOptions(),
            documentLoaderBuilder: (_) =>  const Center(child: CircularProgressIndicator()),
            pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
          ),
          controller: pdfControllerWindows as PdfController,
          scrollDirection: Axis.vertical,
      ) : PdfViewPinch(
          controller: pdfControllerOther as PdfControllerPinch
      ),
    );
  }
}