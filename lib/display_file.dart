import 'dart:io';
import 'dart:typed_data';

import  'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
class DisplayFile extends StatefulWidget {
  final Uint8List fileName;
  const DisplayFile({super.key, required this.fileName});

  @override
  State<DisplayFile> createState() => _DisplayFileState();
}

class _DisplayFileState extends State<DisplayFile> {
  bool isLoading=true;
  File? file;


  @override
  void initState() {
    Future.delayed(Duration(seconds: 2),(){
      isLoading=false;
      setState(() {

      });
    });

    super.initState();
  }
  getFile()async
  {
   // await file.readAsBytes()
  }
  @override
  Widget build(BuildContext context) {
    print(widget.fileName.runtimeType);
    return  Scaffold(
      appBar: AppBar(),
      body: isLoading?CircularProgressIndicator():SfPdfViewer.memory(widget.fileName),
    );
  }
}
