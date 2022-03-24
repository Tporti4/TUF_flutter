import 'dart:async';
import 'dart:io' as io;
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
  double respiratoryRate = 0;

  FlutterAudioRecorder2? audioRecorder;
  Recording? _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;

  static AudioCache audioCache = AudioCache();
  static AudioPlayer audioPlayer = AudioPlayer();
  String backgroundSoundPath = 'zelda-chest-opening.mp3';

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
              respiratoryRate.toStringAsFixed(2),
              style: const TextStyle(fontSize: 25),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                statusText,
                style: const TextStyle(color: Colors.red, fontSize: 25),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                timer,
                style: const TextStyle(fontSize: 25),
              ),
            ),
            ElevatedButton(
              onPressed: startRecording,
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
              onPressed: stopRecording,
              child:
                  const Text('Stop Recording', style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white,
                shadowColor: Colors.black,
                elevation: 5,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                startRecording();
                playLocalAsset();
              },
              child: const Text('Record with 20kHz',
                  style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
                onPrimary: Colors.white,
                shadowColor: Colors.black,
                elevation: 5,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                stopRecording();
                stopLocalAsset();
              },
              child: const Text('Stop 20kHz Recording',
                  style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                primary: Colors.purple,
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
    statusText = "Record complete";
    isComplete = true;
    setState(() {
      _current = result;
      _currentStatus = _current!.status!;
    });
  }

  // Play looping 20kHz signal
  void playLocalAsset() async {
    audioPlayer = await audioCache.loop("zelda-chest-opening.mp3");
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
    return audioPath +
        '/test_' +
        DateTime.now().month.toString() +
        '-' +
        DateTime.now().day.toString() +
        '-' +
        DateTime.now().year.toString() +
        '_' +
        DateTime.now().hour.toString() +
        ':' +
        DateTime.now().minute.toString() +
        ':' +
        DateTime.now().second.toString() +
        '_' +
        '${i++}';
  }
}
