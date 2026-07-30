import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_pdf_export/flutter_deck_pdf_export.dart';
import 'package:flutter_deck_pptx_export/flutter_deck_pptx_export.dart';
import 'package:flutter_deck_ws_client/flutter_deck_ws_client.dart';
import 'presentation/scout_markdown_slide.dart';

const _deckWebSocketUri = String.fromEnvironment(
  'DECK_WS_URI',
  defaultValue: 'ws://127.0.0.1:8080',
);

class ScoutHistoryPresentationApp extends StatelessWidget {
  const ScoutHistoryPresentationApp({
    required this.isPresenterView,
    super.key,
  });

  final bool isPresenterView;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(
        'assets/markdown/scout_history.md',
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Text(
                  'Failed to load markdown: ${snapshot.error}',
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final slides = parseScoutMarkdownDeck(snapshot.data!);

        return FlutterDeckApp(
          isPresenterView: isPresenterView,
          client: FlutterDeckWsClient(
            uri: Uri.parse(_deckWebSocketUri),
          ),
          lightTheme: FlutterDeckThemeData.light(),
          darkTheme: FlutterDeckThemeData.dark(),
          themeMode: ThemeMode.light,
          configuration: FlutterDeckConfiguration(
            background: const FlutterDeckBackgroundConfiguration(
              light: FlutterDeckBackground.solid(
                Color(0xFFF7F4EA),
              ),
              dark: FlutterDeckBackground.solid(
                Color(0xFF092D25),
              ),
            ),
            controls: FlutterDeckControlsConfiguration(
              presenterToolbarVisible: false,
              gestures: FlutterDeckGesturesConfiguration.mobileOnly(),
              shortcuts: FlutterDeckShortcutsConfiguration(
                enabled: isPresenterView,
                nextSlide: const {
                  SingleActivator(LogicalKeyboardKey.arrowRight),
                },
                previousSlide: const {
                  SingleActivator(LogicalKeyboardKey.arrowLeft),
                },
              ),
            ),
            footer: const FlutterDeckFooterConfiguration(
              showSlideNumbers: true,
              showFooter: true,
            ),
            header: const FlutterDeckHeaderConfiguration(
              showHeader: false,
            ),
            slideSize: FlutterDeckSlideSize.fromAspectRatio(
              aspectRatio: const FlutterDeckAspectRatio.ratio16x9(),
              resolution: const FlutterDeckResolution.fhd(),
            ),
            transition: const FlutterDeckTransition.fade(),
          ),
          plugins: [
            FlutterDeckPdfExportPlugin(),
            FlutterDeckPptxExportPlugin(),
          ],
          speakerInfo: const FlutterDeckSpeakerInfo(
            name: 'مصطفى خزعل',
            description: 'قائد الجوالة',
            socialHandle: '@mstfkhazaal',
            imagePath: '',
          ),
          slides: [
            for (var i = 0; i < slides.length; i++)
              ScoutMarkdownDeckSlide(
                slide: slides[i],
                slideNumber: i + 1,
              ),
          ],
        );
      },
    );
  }
}
