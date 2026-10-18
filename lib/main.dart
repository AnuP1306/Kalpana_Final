import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_controller.dart';
import 'screens.dart';
import 'theme.dart';
import 'voice/voice_service.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: K.pale));
  runApp(KalpanaApp(AppController()));
}

class KalpanaApp extends StatelessWidget {
  final AppController c;
  const KalpanaApp(this.c, {super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kalpana',
        debugShowCheckedModeBanner: false,
        navigatorKey: c.navKey,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: K.pale,
          colorScheme:
              ColorScheme.fromSeed(seedColor: K.lilac, surface: K.pale),
        ),
        home: Shell(c),
      );
}

class Shell extends StatefulWidget {
  final AppController c;
  const Shell(this.c, {super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  AppController get c => widget.c;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => c.start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    c.onLifecycle(s);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final s = c.screen;
          final Widget main = switch (s) {
            Screen.welcome => WelcomeScreen(c),
            Screen.onboarding => OnboardingScreen(c),
            Screen.dashboard => DashboardScreen(c),
            Screen.voice => VoiceScreen(c),
            _ => DetailScreen(c, s),
          };
          return PopScope(
            canPop: s == Screen.welcome || s == Screen.dashboard,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) c.back();
            },
            child: Scaffold(
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(children: [
                      const SizedBox(height: 8),
                      GuidancePill(c),
                      if (c.onboarded &&
                          s != Screen.welcome &&
                          s != Screen.onboarding)
                        ListenBar(c),
                      const SizedBox(height: 8),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: KeyedSubtree(key: ValueKey(s), child: main),
                        ),
                      ),
                      if (s != Screen.welcome && s != Screen.onboarding)
                        BottomNav(c),
                    ]),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

/// "Kalpana Speech" bar: always shows the last thing spoken (visual alternative
/// to audio). Tap to hear it again.
class GuidancePill extends StatelessWidget {
  final AppController c;
  const GuidancePill(this.c, {super.key});
  @override
  Widget build(BuildContext context) {
    final v = c.voice;
    final dot = switch (v.state) {
      VoiceState.listening => K.teal,
      VoiceState.processing => K.gold,
      VoiceState.speaking => K.purple,
      VoiceState.error => K.coral,
      _ => K.green,
    };
    return Tap(
      label: v.state == VoiceState.speaking
          ? 'Kalpana is speaking. Double tap to stop.'
          : 'Last message from Kalpana: ${v.spoken}. Double tap to hear it again.',
      onTap: () =>
          v.state == VoiceState.speaking ? v.stop() : v.speak(v.spoken),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xE0FFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: K.line)),
        child: Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot)),
          const SizedBox(width: 7),
          Expanded(
              child: Text('Kalpana Speech: ${v.spoken}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ts(12, w: FontWeight.w500))),
          const SizedBox(width: 7),
          const Icon(Ic.volume, size: 16, color: K.mutedText),
        ]),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  final AppController c;
  const BottomNav(this.c, {super.key});
  Widget item(IconData i, String l, Screen s,
          {Color? color, bool active = false}) =>
      Tap(
        label: l,
        onTap: () => c.go(s),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i, size: 19, color: color ?? (active ? K.purple : K.muted)),
            const SizedBox(height: 3),
            Text(l,
                style: ts(11,
                    w: active || color != null
                        ? FontWeight.w800
                        : FontWeight.w600,
                    c: color != null
                        ? const Color(0xFFC04848)
                        : active
                            ? K.purpleText
                            : K.mutedText)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = c.screen;
    return SizedBox(
      height: 82,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: const Color(0xF0FFFFFF),
                border: Border(top: BorderSide(color: K.line))),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  item(Ic.home, 'Home', Screen.dashboard,
                      active: s == Screen.dashboard),
                  item(Ic.fileText, 'Read', Screen.ocr,
                      active: s == Screen.ocr),
                  const SizedBox(width: 56),
                  item(Ic.message, 'Chat', Screen.community,
                      active: s == Screen.community),
                  item(Ic.alert, 'SOS', Screen.sos, color: K.coral),
                ]),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Tap(
              label: 'Speak to Kalpana',
              onTap: c.openVoice,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDFD5FA),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x66B8C0EB),
                          blurRadius: 9,
                          offset: Offset(0, 4))
                    ]),
                child: Icon(
                    c.voice.state == VoiceState.listening ? Ic.square : Ic.mic,
                    size: 22,
                    color: K.btnText),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Shows whether Kalpana is waiting for "Hey Kalpana", awake, or fully muted,
/// plus a big button that turns the microphone off / on.
class ListenBar extends StatelessWidget {
  final AppController c;
  const ListenBar(this.c, {super.key});
  @override
  Widget build(BuildContext context) {
    final off = c.micOff;
    final text = off
        ? 'Microphone is off'
        : c.awake
            ? 'I’m listening — go ahead'
            : c.loopOn
                ? 'Say “Hey Kalpana”'
                : 'Starting to listen…';
    final status = c.online ? text : '$text • Offline mode';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(children: [
        Expanded(
            child: Text(status,
                style: ts(13,
                    w: FontWeight.w700,
                    c: off ? const Color(0xFFC04848) : K.btnText))),
        Tap(
          label: off
              ? 'Turn microphone on'
              : 'Turn microphone off. Kalpana will stop listening.',
          onTap: c.toggleMic,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 110),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: off ? K.lilac : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: K.line)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(off ? Ic.mic : Ic.square, size: 16, color: K.btnText),
              const SizedBox(width: 6),
              Text(off ? 'Mic on' : 'Mic off',
                  style: ts(13, w: FontWeight.w800)),
            ]),
          ),
        ),
      ]),
    );
  }
}
