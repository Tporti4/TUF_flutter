import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_audio_recorder2/flutter_audio_recorder2.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
//import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record_mp3/record_mp3.dart';
//import 'dart:convert' as convert;
//import 'package:http/http.dart' as http;
import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ext_storage/ext_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String statusText = '';
  String timer = '00:00:00';
  bool isComplete = false;
  String filePath = '';
  int i = 0;
  String respiratoryRate = '0.00';

  FlutterAudioRecorder2? audioRecorder;
  Recording? _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;

  static AudioCache audioCache = AudioCache();
  static AudioPlayer audioPlayer = AudioPlayer();
  String backgroundSoundPath = 'sound_final.wav';

  String imports = '';
  String code = '';
  String completeCode = '';

  @override
  void initState() {
    super.initState();
    loadImports();
    loadCode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: const Text('Track Ur Fit'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Respiratory Rate',
              style: TextStyle(fontSize: 25),
            ),
            Text(
              respiratoryRate,
              style: const TextStyle(fontSize: 25),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
              child: Text(
                statusText,
                style: const TextStyle(color: Colors.red, fontSize: 25),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                startRecording();
                //fetchEnvelope();
                //_writeFileToStorage();
              },
              child:
                  const Text('Start Recording', style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                onPrimary: Colors.white,
                shadowColor: Colors.black,
                elevation: 5,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                stopRecording();
                envelopeAnalysis();
              },
              child:
                  const Text('Stop Recording', style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white,
                shadowColor: Colors.black,
                elevation: 5,
              ),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        return false;
      }
    }
    if (!await Permission.storage.isGranted) {
      PermissionStatus storageStatus = await Permission.storage.request();
      if (storageStatus != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  void startRecording() async {
    bool hasPermission = await FlutterAudioRecorder2.hasPermissions ?? false;
    if (hasPermission) {
      statusText = "Recording...";
      filePath = await getFilePath();
      isComplete = false;
      print(filePath);

      var exists = await io.File(filePath + '.wav').exists();
      if (exists) {
        final file = io.File(filePath + '.wav');
        file.delete();
      }

      completeCode = imports + filePath + '.wav' + code;
      print(completeCode);

      audioRecorder = FlutterAudioRecorder2(filePath,
          audioFormat: AudioFormat.WAV, sampleRate: 44100);
      await audioRecorder!.initialized;
      var current = await audioRecorder!.current(channel: 0);
      print(current);
      setState(() {
        _current = current;
        _currentStatus = current!.status!;
        print(_currentStatus);
      });
      try {
        await audioRecorder!.start();
        var recording = await audioRecorder!.current(channel: 0);
        setState(() {
          _current = recording;
        });
        const tick = const Duration(milliseconds: 50);
        new Timer.periodic(tick, (Timer t) async {
          if (_currentStatus == RecordingStatus.Stopped) {
            t.cancel();
          }

          var current = await audioRecorder!.current(channel: 0);
          setState(() {
            _current = _current;
            _currentStatus = _current!.status!;
          });
        });
      } catch (e) {
        print(e);
      }
    } else {
      statusText = "No microphone permission";
    }
    setState(() {});
  }

  void stopRecording() async {
    var result = await audioRecorder!.stop();
    statusText = "Recording Complete";
    isComplete = true;

    /*
    String fileName = await makeFileName();
    print(fileName);
    fileName = '/recordings/' + fileName;
    print(fileName);
    final io.Directory appDocDirectory = (await getExternalStorageDirectory())!;
    String recordingPath = '${appDocDirectory.path}' + fileName;
    print(recordingPath);
    try {
      final io.File file = io.File(recordingPath);
      var dataOffset = 74;
      var bytes = await file.readAsBytes();
      var shorts = bytes.buffer.asInt16List(dataOffset);
      print(shorts.length);
      print(shorts[0]);
      print(shorts);
    } catch (e) {
      print('Could not read file');
    }

    var dataOffset = 74;
    //var bytes = await io.File(
    //'/storage/emulated/0/Android/data/com.tuf_stuff.track_ur_fit/files/recordings/test_4-6-2022_8:7:31_0')
    //.readAsBytes();

     */

    setState(() {
      _current = result;
      _currentStatus = _current!.status!;
    });
  }

  /*
  void fetchEnvelope() async {
    var url = Uri.http('10.0.2.2:5000/', '');
    print(url);
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      var result = jsonResponse['result'];
      print('Result: $result');
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

   */

  Future<void> loadImports() async {
    final loadedImports =
        await rootBundle.loadString('assets/envelopeScript1.txt');
    setState(() {
      imports = loadedImports;
    });
  }

  Future<void> loadCode() async {
    final loadedCode =
        await rootBundle.loadString('assets/envelopeScript2.txt');
    setState(() {
      code = loadedCode;
    });
  }

  void envelopeAnalysis() async {
    final result = await Chaquopy.executeCode(completeCode);
    setState(() {
      respiratoryRate = result['textOutputOrError'] ?? '';
    });
    print(respiratoryRate);
  }

  /*
  // Play looping 20kHz signal
  void playLocalAsset() async {
    audioPlayer = await audioCache.loop("sound_final.wav");
  }

  void stopLocalAsset() async {
    audioPlayer.stop();
  }

  void playRecording() {
    if (io.File(filePath).existsSync()) {
      AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.play(filePath, isLocal: true);
    }
  }

  Future<String> getDirectoryPath() async {
    io.Directory appDocDirectory;
    if (io.Platform.isIOS) {
      appDocDirectory = await getApplicationDocumentsDirectory();
    } else {
      appDocDirectory = (await getExternalStorageDirectory())!;
    }

    return appDocDirectory.path;
  }

  String _fileExtension = '.wav';
  String _directoryPath = '';

  Future<String> makeFileName() async {
    return 'test_' + _fileExtension;
  }

  void _createFile() async {
    var _completeFileName = await makeFileName();
    _directoryPath = await getDirectoryPath();
    io.File(_directoryPath + '/' + _completeFileName)
        .create(recursive: true)
        .then((io.File file) async {
      //write to file
      Uint8List bytes = await file.readAsBytes();
      file.writeAsBytes(bytes);
      print(file.path);
      completeCode = imports + file.path + code;
      print(completeCode);
    });
  }

  void _createDirectory() async {
    bool isDirectoryCreated = await io.Directory(_directoryPath).exists();
    if (!isDirectoryCreated) {
      io.Directory(_directoryPath).create()
          // The created directory is returned as a Future.
          .then((io.Directory directory) {
        print(directory.path);
      });
    }
  }

  void _writeFileToStorage() async {
    _createDirectory();
    _createFile();
  }
   */

  Future<String> getFilePath() async {
    io.Directory appDocDirectory;
    if (io.Platform.isIOS) {
      appDocDirectory = await getApplicationDocumentsDirectory();
    } else {
      appDocDirectory = (await getExternalStorageDirectory())!;
    }

    String audioPath = appDocDirectory.path + '/recordings';
    var d = io.Directory(audioPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return audioPath + '/test_' + '${i++}';
  }
}
