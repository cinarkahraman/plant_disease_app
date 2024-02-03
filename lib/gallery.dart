import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

class MultiFunctionDemo extends StatefulWidget {
  @override
  _MultiFunctionDemoState createState() => _MultiFunctionDemoState();
}

class _MultiFunctionDemoState extends State<MultiFunctionDemo> {
  File? _cameraImage;
  File? _galleryImage;
  final picker = ImagePicker();

  var _recognitions;
  var v = "";

  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {});
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
      //  inputType: TfliteInputType.float32
    );
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _cameraImage = File(pickedFile.path);
        _galleryImage = null;
        // Yeni bir fotoğraf seçildiğinde eski tahmin sonuçlarını temizle
        _recognitions = null;
        v = "";
      } else {
        print('Fotoğraf Seçilmedi.');
      }
    });
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _galleryImage = File(pickedFile.path);
        _cameraImage = null;
        // Yeni bir fotoğraf seçildiğinde eski tahmin sonuçlarını temizle
        _recognitions = null;
        v = "";
      } else {
        print('Fotoğraf Seçilmedi.');
      }
    });
  }

  Future<void> _identifyPlant() async {
    if (_galleryImage != null || _cameraImage != null) {
      detectImage(_galleryImage ?? _cameraImage!);
    } else {
      // Galeri veya kamera üzerinden önce bir fotoğraf seçilmediğinde uyarı göster
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Uyarı"),
            content: Text("Lütfen önce bir fotoğraf seçin veya çekin."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Tamam"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> detectImage(File image) async {
    try {
      int startTime = DateTime.now().millisecondsSinceEpoch;
      var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 6,
        threshold: 0.05,
        imageMean: 127.5,
        imageStd: 127.5,
      );

      if (recognitions == null) {
        print("Model inference failed.");
        return;
      }

      setState(() {
        _recognitions = recognitions;
        v = recognitions[0]['label'].toString();
        print(_recognitions);
      });

      int endTime = DateTime.now().millisecondsSinceEpoch;
      print("Inference took ${endTime - startTime}ms");
    } catch (e) {
      print("Error during inference: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (_cameraImage != null || _galleryImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Card(
                          elevation: 5,
                          child: Image.file(
                            _cameraImage ?? _galleryImage!,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      const Text('Fotoğraf Seçilmedi.'),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickImageFromCamera,
                      icon: const Icon(Icons.camera),
                      label: const Text('Kamera ile Fotoğraf Çek'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo),
                      label: const Text('Galeriden Fotoğraf Seç'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _identifyPlant,
                      icon: const Icon(Icons.local_florist),
                      label: const Text('Bitkiyi Tanı'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_recognitions != null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        padding: const EdgeInsets.all(15),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tahminler:',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            for (var recognition in _recognitions)
                              Text(
                                '- ${recognition['label']} : ${(recognition['confidence'] * 100).toStringAsFixed(2)}%',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                          ],
                        ),
                      )
                    else
                      Container(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
