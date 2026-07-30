import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';

class ScoutDeckSlideData {
  const ScoutDeckSlideData({
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.quote,
    required this.speakerNotes,
    required this.layout,
  });

  final String title;
  final String subtitle;
  final List<String> bullets;
  final String quote;
  final String speakerNotes;
  final ScoutDeckSlideLayout layout;
}

enum ScoutDeckSlideLayout {
  cover,
  content,
  quote,
  timeline,
}

List<ScoutDeckSlideData> parseScoutMarkdownDeck(String markdown) {
  final normalized = markdown.replaceAll('\r\n', '\n').trim();
  final sections = normalized
      .split(RegExp(r'\n\s*---\s*\n'))
      .map((section) => section.trim())
      .where((section) => section.isNotEmpty)
      .toList(growable: false);

  return [
    for (var i = 0; i < sections.length; i++)
      _parseSlideSection(sections[i], index: i),
  ];
}

ScoutDeckSlideData _parseSlideSection(String section, {required int index}) {
  final lines = section.split('\n');

  var title = '';
  var subtitle = '';
  var quote = '';
  var speakerNotes = '';
  final bullets = <String>[];
  var readingNotes = false;
  final noteLines = <String>[];

  for (final rawLine in lines) {
    final line = rawLine.trim();

    if (line == ':::notes') {
      readingNotes = true;
      continue;
    }

    if (line == ':::' && readingNotes) {
      readingNotes = false;
      continue;
    }

    if (readingNotes) {
      noteLines.add(rawLine.trim());
      continue;
    }

    if (line.startsWith('# ')) {
      title = line.substring(2).trim();
      continue;
    }

    if (line.startsWith('## ')) {
      subtitle = line.substring(3).trim();
      continue;
    }

    if (line.startsWith('- ')) {
      bullets.add(line.substring(2).trim());
      continue;
    }

    if (line.startsWith('> ')) {
      quote = line.substring(2).trim();
    }
  }

  speakerNotes = noteLines.join('\n').trim();

  return ScoutDeckSlideData(
    title: title,
    subtitle: subtitle,
    bullets: bullets,
    quote: quote,
    speakerNotes: speakerNotes,
    layout: _detectLayout(index: index, title: title, quote: quote),
  );
}

ScoutDeckSlideLayout _detectLayout({
  required int index,
  required String title,
  required String quote,
}) {
  if (index == 0) {
    return ScoutDeckSlideLayout.cover;
  }

  if (quote.isNotEmpty) {
    return ScoutDeckSlideLayout.quote;
  }

  if (title.contains('خط زمني')) {
    return ScoutDeckSlideLayout.timeline;
  }

  return ScoutDeckSlideLayout.content;
}

class ScoutMarkdownDeckSlide extends FlutterDeckSlideWidget {
  ScoutMarkdownDeckSlide({
    required this.slide,
    required this.slideNumber,
    super.key,
  }) : super(
          configuration: FlutterDeckSlideConfiguration(
            route: '/scout-history-$slideNumber',
            title: slide.title,
            speakerNotes: slide.speakerNotes,
            footer: const FlutterDeckFooterConfiguration(showFooter: true),
          ),
        );

  final ScoutDeckSlideData slide;
  final int slideNumber;

  static const Color _green = Color(0xFF0F4A3A);
  static const Color _darkGreen = Color(0xFF092D25);
  static const Color _gold = Color(0xFFC89B2E);
  static const Color _cream = Color(0xFFF7F4EA);

  @override
  Widget build(BuildContext context) {
    return FlutterDeckSlide.custom(
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: _SlideShell(
            slideNumber: slideNumber,
            child: switch (slide.layout) {
              ScoutDeckSlideLayout.cover => _CoverSlide(slide: slide),
              ScoutDeckSlideLayout.quote => _QuoteSlide(slide: slide),
              ScoutDeckSlideLayout.timeline => _TimelineSlide(slide: slide),
              ScoutDeckSlideLayout.content => _ContentSlide(slide: slide),
            },
          ),
        );
      },
    );
  }
}

class _SlideShell extends StatelessWidget {
  const _SlideShell({
    required this.child,
    required this.slideNumber,
  });

  final Widget child;
  final int slideNumber;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            ScoutMarkdownDeckSlide._cream,
            Color(0xFFE9F1EA),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            left: -100,
            child: Text(
              '⚜',
              style: TextStyle(
                color: ScoutMarkdownDeckSlide._green.withOpacity(0.06),
                fontSize: 420,
                height: 1,
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 0,
            child: Container(
              width: 14,
              height: 150,
              color: ScoutMarkdownDeckSlide._gold,
            ),
          ),
          Positioned(
            right: 64,
            bottom: 34,
            child: Text(
              'تاريخ الحركة الكشفية',
              style: TextStyle(
                color: ScoutMarkdownDeckSlide._green.withOpacity(0.75),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            left: 64,
            bottom: 34,
            child: Text(
              '$slideNumber',
              style: TextStyle(
                color: ScoutMarkdownDeckSlide._green.withOpacity(0.65),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(96, 80, 96, 72),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CoverSlide extends StatelessWidget {
  const _CoverSlide({required this.slide});

  final ScoutDeckSlideData slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text(
          slide.title,
          style: const TextStyle(
            color: ScoutMarkdownDeckSlide._darkGreen,
            fontSize: 72,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          slide.subtitle,
          style: const TextStyle(
            color: ScoutMarkdownDeckSlide._gold,
            fontSize: 42,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 48),
        _BulletList(bullets: slide.bullets, fontSize: 30),
        const Spacer(),
        const _GoldRule(),
        const SizedBox(height: 20),
        const Text(
          'إعداد: القائد مصطفى خزعل',
          style: TextStyle(
            color: ScoutMarkdownDeckSlide._green,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ContentSlide extends StatelessWidget {
  const _ContentSlide({required this.slide});

  final ScoutDeckSlideData slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideTitle(slide: slide),
        const SizedBox(height: 36),
        Expanded(
          child: Align(
            alignment: Alignment.topRight,
            child: SingleChildScrollView(
              child: _BulletList(bullets: slide.bullets),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuoteSlide extends StatelessWidget {
  const _QuoteSlide({required this.slide});

  final ScoutDeckSlideData slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideTitle(slide: slide),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            border: const Border(
              right: BorderSide(
                color: ScoutMarkdownDeckSlide._gold,
                width: 8,
              ),
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(
            '«${slide.quote}»',
            style: const TextStyle(
              color: ScoutMarkdownDeckSlide._darkGreen,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 36),
        _BulletList(bullets: slide.bullets, fontSize: 26),
        const Spacer(),
      ],
    );
  }
}

class _TimelineSlide extends StatelessWidget {
  const _TimelineSlide({required this.slide});

  final ScoutDeckSlideData slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideTitle(slide: slide),
        const SizedBox(height: 30),
        Expanded(
          child: Wrap(
            spacing: 18,
            runSpacing: 18,
            textDirection: TextDirection.rtl,
            children: [
              for (final bullet in slide.bullets)
                _TimelineChip(label: bullet),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineChip extends StatelessWidget {
  const _TimelineChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final parts = label.split(':');
    final year = parts.first.trim();
    final event = parts.skip(1).join(':').trim();

    return Container(
      width: 350,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ScoutMarkdownDeckSlide._green.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            year,
            style: const TextStyle(
              color: ScoutMarkdownDeckSlide._gold,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              event,
              style: const TextStyle(
                color: ScoutMarkdownDeckSlide._darkGreen,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideTitle extends StatelessWidget {
  const _SlideTitle({required this.slide});

  final ScoutDeckSlideData slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slide.title,
          style: const TextStyle(
            color: ScoutMarkdownDeckSlide._darkGreen,
            fontSize: 50,
            fontWeight: FontWeight.w900,
            height: 1.14,
          ),
        ),
        if (slide.subtitle.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            slide.subtitle,
            style: const TextStyle(
              color: ScoutMarkdownDeckSlide._green,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 18),
        const _GoldRule(),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.bullets,
    this.fontSize = 30,
  });

  final List<String> bullets;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final bullet in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.navigation,
                    color: ScoutMarkdownDeckSlide._gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    bullet,
                    style: TextStyle(
                      color: ScoutMarkdownDeckSlide._darkGreen,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      height: 1.42,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GoldRule extends StatelessWidget {
  const _GoldRule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 6,
      decoration: BoxDecoration(
        color: ScoutMarkdownDeckSlide._gold,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
