import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled4/display_file.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLite Demo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Read Flie PDF '),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                dbHelper.uploadPDF();
              },
              child: Text('تحميل الملف  وتخزينه في قواعد البيانات المحلية'),
            ),
            ElevatedButton(
              onPressed: ()async {
                Reference storageRef =FirebaseStorage.instance.ref();
                final dir=await getExternalStorageDirectory();
                try{
                  File file2=File('${dir!.path}f.pdf');
                  await file2.writeAsBytes(data!);
                  String filename=
                      DateTime.now().millisecondsSinceEpoch.toString();
                  Reference fileRef=storageRef.child('file/$filename.pdf');
                  await fileRef.putFile(file2);
                }catch(e){
                  print(e);
                }
              },
              child: Text('تخزين الملف في firebase'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DisplayPage()),
                );
              },
              child: Text('عرض ملف pdf'),
            ),
          ],
        ),
      ),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await initDatabase();
    return _database;
  }

  DatabaseHelper.internal();

  Future<Database> initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + '/database.db';

    final database = await openDatabase(
        path, version: 1, onCreate: _createDatabase);
    return database;
  }

  void _createDatabase(Database db, int version) async {
    await db.execute(
        'CREATE TABLE pdf_table (id INTEGER PRIMARY KEY, file_name TEXT, file_bytes BLOB)');

  }

  Future<void> uploadPDF() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final filePath = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['pdf']);
      if (filePath != null) {
        final fileBytes = File(filePath.files.single.path!).readAsBytesSync();
        print('type is ${fileBytes.runtimeType}');

        final database = await _instance.database;
        final fileInfo = FileInfo(
          fileName: path.basename(filePath.files.single.path!),
          fileBytes: fileBytes,
        );

        await database!.insert('pdf_table', fileInfo.toMap());
        print('تم تحميل ملف PDF وحفظه في قاعدة البيانات.');
      }
    } else {
      print('تم رفض الوصول للتخزين الخارجي.');
    }
  }


}

class FileInfo {
  final String fileName;
  final Uint8List fileBytes;

  FileInfo({
    required this.fileName,
    required this.fileBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'file_name': fileName,
      'file_bytes': fileBytes,
    };
  }
}

class DisplayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Display Page'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getDataFromDatabase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<Map<String, dynamic>> data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {

                return ListTile(
                  onTap: ()
                  {

                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => DisplayFile(fileName: data[index]['file_bytes']),));
                  },
                  title: Text('Data ${data[index]['id']}'),
                  subtitle: Text(data[index]['file_name']),

                );
              },
            );
          }
        },
      ),
    );
  }

 Future<List<Map<String, dynamic>>> getDataFromDatabase() async {
     try {
       final directory = await getApplicationDocumentsDirectory();
       final path = directory.path + '/database.db';
       Database database = await openDatabase(
        path,
       );

       var data = await database.query(

         'pdf_table'
           );
       return data;
     } catch (e) {

       print(e);
       return  [];
     }
   }}