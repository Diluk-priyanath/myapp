// ignore_for_file: camel_case_types, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:open_file/open_file.dart';

void main() {
  runApp(const pic2pdf());
}

class pic2pdf extends StatelessWidget {
  const pic2pdf({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pic2PDF Converter',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PDFHomePage(),
    );
  }
}

class PDFHomePage extends StatefulWidget {
  const PDFHomePage({super.key});

  @override
  _PDFHomePageState createState() => _PDFHomePageState();
}

//load files and list

class _PDFHomePageState extends State<PDFHomePage> {
  List<File> _pdfFiles = [];

  @override
  void initState() {
    super.initState();
    _loadPDFFiles();
  }

  void _onPDFCreated(File newFile) {
    setState(() {
      _pdfFiles.add(newFile);
      _pdfFiles.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      // Add the PDF to the list
    });
  }

  void _loadPDFFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final pdfDirectory = Directory('${directory.path}/Pic2PDF Converter');
    if (await pdfDirectory.exists()) {
      setState(() {
        _pdfFiles =
            pdfDirectory.listSync().map((item) => File(item.path)).toList();
        _pdfFiles.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      });
    }
  }

  //DATE TIME FILESIZE IN HOME-----------------------------------------------------------------------------------------------------

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('hh:mm a, dd/MMM/yyyy').format(dateTime);
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Pic2PDF Converter',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 198, 4, 247),
      ),
      body: Container(
        color: Colors.grey[200],
        child: ListView.builder(
          itemCount: _pdfFiles.length,
          itemBuilder: (context, index) {
            final file = _pdfFiles[index];
            final modifiedTime = File(file.path).statSync().modified.toLocal();
            final fileSize = _getFileSize(file);
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, size: 40),
                  title: Text(file.path.split('/').last),
                  subtitle: Text(
                    '${_formatDateTime(modifiedTime)} $fileSize',
                  ),
                  onTap: () => _showFileOptions(file),
                ),
                const Divider(),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () =>
                  _handlePickImagesAndCreatePDF(context, ImageSource.gallery),
              child: const Text('Select Image From Gallery'),
            ),
            ElevatedButton(
              onPressed: () =>
                  _handlePickImagesAndCreatePDF(context, ImageSource.camera),
              child: const Text('Select Image From Camera'),
            ),
          ],
        ),
      ),
    );
  }

  //FILE OPTIONS (LIKE/ SHARE/ DELETE/ RENAME/ OPEN)-------------------------------------------------------------------------------

  void _showFileOptions(File file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open PDF'),
              onTap: () => _openPDF(file),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename PDF'),
              onTap: () => _renamePDF(file),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete PDF'),
              onTap: () => _confirmDeletePDF(file),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletePDF(File file) async {
    final delete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are You Sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (delete == true) {
      _deletePDF(file);
    }
  }

//RENAME PDF--------------------------------------------------------------------------------------------------------------------

  Future<void> _renamePDF(File file) async {
    String newName = "";
    await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename PDF'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new file name'),
          onChanged: (value) {
            newName = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newName.isNotEmpty) {
                File renamedFile =
                    file.renameSync('${file.parent.path}/$newName.pdf');
                setState(() {
                  _pdfFiles.remove(file);
                  _pdfFiles.add(renamedFile);
                  _pdfFiles.sort((a, b) =>
                      b.statSync().modified.compareTo(a.statSync().modified));
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

//OPEN PDF

  void _openPDF(File file) {
    OpenFile.open(file.path);
  }

//DELETE PDF FILES

  void _deletePDF(File file) {
    file.delete();
    setState(() {
      _pdfFiles.remove(file);
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF DELETED SUCCESSFULLY')));
  }

  //SELECT IMAGES FROM THE CAMERA------------------------------------------------------------------------------

  Future<void> _handlePickImagesAndCreatePDF(
      BuildContext context, ImageSource source) async {
    final hasCameraPermission = await _checkCameraPermission(source);

    if (hasCameraPermission) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PDFCreationPage(
            onPDFCreated: _onPDFCreated,
            source: source,
          ),
        ),
      );
    }
  }

  Future<bool> _checkCameraPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      PermissionStatus status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      if (status.isDenied || status.isPermanentlyDenied) {
        _showPermissionDeniedDialog('Camera');
        return false;
      }
    }
    return true;
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Denied'),
        content:
            Text('$permissionType permission is required to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

//CREATE PDF FROM IMAGES--------------------------------------------------------------------------

class PDFCreationPage extends StatefulWidget {
  final Function(File) onPDFCreated;
  final ImageSource source;

  const PDFCreationPage(
      {super.key, required this.onPDFCreated, required this.source});

  @override
  _PDFCreationPageState createState() => _PDFCreationPageState();
}

class _PDFCreationPageState extends State<PDFCreationPage> {
  final List<File> _images = [];
  String _pdfFileName = 'MY PDF';

  @override
  void initState() {
    super.initState();
    _pickImages(widget.source);
  }

  //PICK IMAGES FROM GALLERY AND CAMERA TO PDF---------------------------------------------------------------------

  Future<void> _pickImages(ImageSource source) async {
    final picker = ImagePicker();
    List<XFile>? pickedFiles;

    if (source == ImageSource.gallery) {
      pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _images.addAll(pickedFiles!.map((file) => File(file.path)).toList());
        });
      }
    } else if (source == ImageSource.camera) {
      XFile? pickedFile;
      bool takeAnother = true;
      while (takeAnother) {
        pickedFile = await picker.pickImage(source: ImageSource.camera);
        if (pickedFile != null) {
          setState(() {
            _images.add(File(pickedFile!.path));
          });
          takeAnother = await _showCameraOptionsDialog();
        } else {
          takeAnother = false;
        }
      }
      if (_images.isNotEmpty) {
        _showFileNameDialog();
      }
    }
  }

  Future<bool> _showCameraOptionsDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Take Another Photo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Finish'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Take Another'),
              ),
            ],
          ),
        ) ??
        false;
  }

//ENTER FILE NAME___________________________________________________________________________________________________________________

  Future<void> _showFileNameDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'File name'),
          onChanged: (value) {
            _pdfFileName = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createPDF();
            },
            child: const Text('Create PDF'),
          ),
        ],
      ),
    );
  }

//CONVERT IMAGES TO PDF (FINAL OUTPUT)___________________________________________________________________________________

  Future<void> _createPDF() async {
    final pdf = pw.Document();
    for (var image in _images) {
      final imageFile = pw.MemoryImage(image.readAsBytesSync());
      pdf.addPage(pw.Page(
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(imageFile, fit: pw.BoxFit.contain));
        },
        margin: const pw.EdgeInsets.all(0),
      ));
    }

    final output = await getApplicationDocumentsDirectory();
    final pdfDirectory = Directory('${output.path}/PIC2PDF Converter');
    if (!(await pdfDirectory.exists())) {
      await pdfDirectory.create();
    }

    final file = File('${pdfDirectory.path}/$_pdfFileName.pdf');
    await file.writeAsBytes(await pdf.save());

    widget.onPDFCreated(file);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF CREATED SUCCESSFULLY')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create PDF'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _images.isEmpty
                ? const Center(child: Text('No images selected'))
                : GridView.builder(
                    itemCount: _images.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Image.file(_images[index], fit: BoxFit.cover),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(
                                  Icons.delete), // Changed Icon to Icons.delete
                              onPressed: () {
                                setState(() {
                                  _images.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }, // Added closing curly brace and semicolon
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add), // Added const keyword
                  label: const Text('Add more images'), // Added const keyword
                  onPressed: () => _addMoreImages(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons
                      .picture_as_pdf), // Changed icon to Icons.picture_as_pdf
                  label: const Text('Create pdf'), // Added const keyword
                  onPressed: () => _showFileNameDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

//ADD MORE IMAGES USING GALLERY AND CAMERA___________________________________________________________________________________

  Future<void> _addMoreImages() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Select from Gallery'),
            onTap: () {
              Navigator.of(context).pop();
              _pickImages(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a Photo'),
            onTap: () {
              Navigator.of(context).pop();
              _pickImages(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }
}
