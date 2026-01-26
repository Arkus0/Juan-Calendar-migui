import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/voice_service.dart';
import '../services/ocr_service.dart';
import '../widgets/proposal_dialog.dart';
import 'calendar_screen.dart';
import 'agenda_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late StreamSubscription _intentDataStreamSubscription;
  final VoiceService _voiceService = VoiceService();
  final OcrService _ocrService = OcrService();
  bool _isListening = false;

  final List<Widget> _screens = const [
    CalendarScreen(),
    AgendaScreen(),
    ContactsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initSharingListener();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _ocrService.dispose();
    super.dispose();
  }

  void _initSharingListener() {
    // Stream
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _processSharedFiles(value);
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // Initial
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _processSharedFiles(value);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  Future<void> _processSharedFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    final file = files.first;

    if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
      // For text/url, path contains the content
      if (file.path.isNotEmpty) {
        _showProposal(file.path);
      }
    } else if (file.type == SharedMediaType.image) {
      if (file.path.isNotEmpty) {
        final text = await _ocrService.processImage(file.path);
        if (text.isNotEmpty) {
          _showProposal(text);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo extraer texto de la imagen.')));
          }
        }
      }
    }
  }

  void _showProposal(String text) {
    showDialog(
      context: context,
      builder: (_) => ProposalDialog(text: text),
    );
  }

  Future<void> _showVoiceDialog() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) return;
    }

    String recognizedText = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!_isListening) {
               _isListening = true;
               _voiceService.startListening(
                 onResult: (text) {
                   setState(() => recognizedText = text);
                 },
                 onListeningStateChanged: (isListening) {
                    if (!isListening) {
                      _isListening = false;
                      if (Navigator.canPop(dialogContext)) {
                        Navigator.pop(dialogContext);
                      }
                      if (recognizedText.isNotEmpty) {
                        _showProposal(recognizedText);
                      }
                    }
                 }
               );
            }

            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(recognizedText.isEmpty ? 'Escuchando...' : recognizedText, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                       _voiceService.stopListening();
                    },
                    child: const Text('Detener'),
                  )
                ],
              ),
            );
          }
        );
      }
    ).then((_) {
       if (_isListening) {
         _voiceService.stopListening();
         _isListening = false;
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Musician Organizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Añadir por voz',
            onPressed: _showVoiceDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts),
            label: 'Contactos',
          ),
        ],
      ),
    );
  }
}
