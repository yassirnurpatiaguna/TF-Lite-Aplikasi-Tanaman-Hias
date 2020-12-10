import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(MaterialApp(
      home: DetectMain(),
      debugShowCheckedModeBanner: false,
    ));

class DetectMain extends StatefulWidget {
  @override
  _DetectMainState createState() => new _DetectMainState();
}

class _DetectMainState extends State<DetectMain> {
  File _image;
  double _imageWidth;
  double _imageHeight;
  var _recognitions;

  loadModel() async {
    Tflite.close();
    try {
      String res;
      res = await Tflite.loadModel(
          model: "assets/tanamanhias.tflite",
          labels: "assets/tanamanhias.txt",
          useGpuDelegate: true);
      print(res);
    } on PlatformException {
      print("Gagal meload model");
    }
  }

  // run prediction using TFLite on given image
  Future predict(File image) async {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    var recognitions = await Tflite.runModelOnImage(
        path: image.path, // required
        imageMean: 0.0, // defaults to 117.0
        imageStd: 255.0, // defaults to 1.0
        numResults: 2, // defaults to 5
        threshold: 0.2, // defaults to 0.1
        asynch: true // defaults to true
        );

    print(recognitions);

    setState(() {
      _recognitions = recognitions;
    });
    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }

  // send image to predict method selected from gallery or camera
  sendImage(File image) async {
    if (image == null) return;
    await predict(image);

    // get the width and height of selected image
    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
            _image = image;
          });
        })));
  }

  // select image from gallery
  selectFromGallery() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {});
    sendImage(image);
  }

  // select image from camera
  selectFromCamera() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() {});
    sendImage(image);
  }

  //info app

  @override
  void initState() {
    super.initState();

    loadModel().then((val) {
      setState(() {});
    });
  }

  Widget printValue(rcg) {
    if (rcg == null) {
      return Text('',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700));
    } else if (rcg.isEmpty) {
      return Center(
        child: Text("Tidak dapat mengenali",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Center(
        child: Text(
          "Tanaman  " + _recognitions[0]['label'].toString().toUpperCase(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // gets called every time the widget need to re-render or build
  @override
  Widget build(BuildContext context) {
    // get the width and height of current screen the app is running on
    Size size = MediaQuery.of(context).size;

    // initialize two variables that will represent final width and height of the segmentation
    // and image preview on screen
    double finalW;
    double finalH;

    // when the app is first launch usually image width and height will be null
    // therefore for default value screen width and height is given
    if (_imageWidth == null && _imageHeight == null) {
      finalW = size.width;
      finalH = size.height;
    } else {
      // ratio width and ratio height will given ratio to
//      // scale up or down the preview image
      double ratioW = size.width / _imageWidth;
      double ratioH = size.height / _imageHeight;

      // final width and height after the ratio scaling is applied
      finalW = _imageWidth * ratioW * .85;
      finalH = _imageHeight * ratioH * .50;
    }

//    List<Widget> stackChildren = [];

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
        title: Text(
          "Klasifikasi Tanaman Hias",
          style: GoogleFonts.marvel(
              textStyle: Theme.of(context).textTheme.headline1,
              fontWeight: FontWeight.w700,
              fontSize: 25,
              color: Colors.white,
              fontStyle: FontStyle.normal),
        ),
        backgroundColor: Colors.lightBlueAccent,
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(0, 30, 0, 30),
            child: printValue(_recognitions),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 30, 0, 30),
            child: _image == null
                ? Center(
                    child: Text(
                      "Belum ada gambar \n \n"
                      "\n"
                      " Silahkan pilih gambar dari galeri atau dapat mengambil foto menggunakan kamera",
                      style: GoogleFonts.marvel(
                          textStyle: Theme.of(context).textTheme.caption,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          fontStyle: FontStyle.normal),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Center(
                    child: Image.file(_image,
                        fit: BoxFit.fill, width: finalW, height: finalH)),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.lightBlue,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
                color: Colors.white,
                icon: FaIcon(FontAwesomeIcons.images),
                onPressed: selectFromGallery,
                tooltip: 'Galeri',
                iconSize: 25.25),
            IconButton(
                color: Colors.white,
                icon: FaIcon(FontAwesomeIcons.cameraRetro),
                onPressed: selectFromCamera,
                tooltip: 'Kamera',
                iconSize: 30.30),
            IconButton(
                color: Colors.white,
                icon: FaIcon(FontAwesomeIcons.infoCircle),
                tooltip: 'Tentang Aplikasi',
                iconSize: 25.25,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TentangAplikasi()),
                  );
                }),
          ],
        ),
      ),
    );
  }
}

class TentangAplikasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tentang Aplikasi",
          style: GoogleFonts.marvel(
              textStyle: Theme.of(context).textTheme.headline1,
              fontWeight: FontWeight.w700,
              fontSize: 25,
              color: Colors.white,
              fontStyle: FontStyle.normal),
        ),
        backgroundColor: Colors.lightBlueAccent,
        centerTitle: true,
      ),
      body: Container(
        margin: EdgeInsets.all(30.0),
        padding: EdgeInsets.all(10.0),
        alignment: Alignment.topCenter,
        width: 300,
        height: 800,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(),
        ),
        child: Text(
          "\n"
          "  Aplikasi ini adalah demo aplikasi klasifikasi tanaman hias yang dapat digunakan sebagai pendekteksi tanaman hias."
          "\n Cara penggunaan menggunakan metode gambar."
          " Untuk saat ini hanya dapat mendeksi tanaman hias yang terdiri dari : \n\n"
          "1. Aglaonema  Spring Snow \n"
          "2. Aglaonema Lady Valentine \n"
          "3. Aglaonema Red Stardust \n"
          "4. Puring Apel \n"
          "5. Puring Jet \n"
          "6. Puring Worten \n"
          "\n \n 2020 \u00a9 Develop by Yassir Nurpatiaguna",
          maxLines: 250,
          style: GoogleFonts.lato(
              textStyle: Theme.of(context).textTheme.display2,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              wordSpacing: 0.5,
              fontStyle: FontStyle.normal),
        ),
      ),
    );
  }
}
