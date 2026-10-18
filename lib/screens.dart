import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'app_controller.dart';
import 'strings.dart';
import 'theme.dart';
import 'voice/voice_service.dart';
import 'widgets.dart';

const _pad = EdgeInsets.fromLTRB(20, 20, 20, 28);

Widget _scroll(List<Widget> kids, {EdgeInsets pad = _pad}) =>
    SingleChildScrollView(
      padding: pad,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < kids.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          kids[i]
        ]
      ]),
    );

Widget _label(String s, {bool gap = false}) => Padding(
      padding: EdgeInsets.only(top: gap ? 8 : 0),
      child: Text(s, style: ts(11, w: FontWeight.w800, c: K.mutedText, ls: .9)),
    );

Widget _topBar(AppController c, Screen s) {
  if (s == Screen.welcome)
    return const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Wordmark(), CountryPill()]);
  final eyebrow = s == Screen.sos
      ? 'TAP OR SAY “EMERGENCY”'
      : s == Screen.voice
          ? 'STATE: ${c.voice.stateLabel.replaceAll('.', '').toUpperCase()}'
          : 'KALPANA ASSISTED';
  return Container(
    padding: const EdgeInsets.only(bottom: 6),
    decoration:
        BoxDecoration(border: Border(bottom: BorderSide(color: K.line))),
    child: Row(children: [
      IconBtn(Ic.arrowLeft, 'Back', c.back),
      Expanded(
        child: Semantics(
          header: true,
          child: Column(children: [
            Text(screenTitles0(s),
                textAlign: TextAlign.center, style: ts(15, w: FontWeight.w800)),
            Text(eyebrow,
                style: ts(10.5, w: FontWeight.w800, c: K.purpleText, ls: .4)),
          ]),
        ),
      ),
      IconBtn(Ic.volume, 'Read this screen aloud', c.readCurrent),
    ]),
  );
}

String screenTitles0(Screen s) => const [
      'Welcome to Kalpana',
      'Accessibility setup',
      'Home dashboard',
      'Ask My Camera',
      'Voice Assistant',
      'Explore Surroundings',
      'Read Text',
      'Where Am I?',
      'Emergency SOS',
      'Community Chat',
      'Voice Directory',
      'Settings',
      'Daily Assistant',
      'Voice Dial',
      'Color Identifier'
    ][s.index];

// ---------------------------------------------------------------- Welcome
class WelcomeScreen extends StatelessWidget {
  final AppController c;
  const WelcomeScreen(this.c, {super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, box) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight - 48),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(c, Screen.welcome),
                  Column(children: [
                    const SizedBox(height: 24),
                    Orb(
                        size: 154,
                        state: c.voice.state,
                        onTap: c.beginFromButton),
                    const SizedBox(height: 8),
                    Text('“Hello! I’m Kalpana”',
                        textAlign: TextAlign.center,
                        style: ts(24, w: FontWeight.w700, ls: -.4)),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 290),
                      child: Text(
                          'Your voice-first AI companion. Speak or tap the orb to explore your world.',
                          textAlign: TextAlign.center,
                          style: ts(14, c: K.mutedText, h: 1.6)),
                    ),
                    const SizedBox(height: 24),
                  ]),
                  Column(children: [
                    KCard(
                      child: Row(children: [
                        const MiniIcon(Ic.ear),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Spoken Audio Everywhere',
                                    style: ts(14, w: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(
                                    'Tap the orb to speak, any time. Every voice action also has a button.',
                                    style: ts(12, c: K.mutedText, h: 1.35)),
                              ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton('Let’s Get Started',
                        icon: Ic.arrowRight, onTap: c.beginFromButton),
                  ]),
                ]),
          ),
        ),
      );
}

// ------------------------------------------------------------- Onboarding
class OnboardingScreen extends StatelessWidget {
  final AppController c;
  const OnboardingScreen(this.c, {super.key});
  @override
  Widget build(BuildContext context) {
    final perms = [
      ('Microphone', 'Voice queries & commands', Ic.mic, c.micOk),
      ('Camera', 'Label reading & detection', Ic.camera, c.camOk),
      ('Location (GPS)', 'Where Am I & SOS coordinates', Ic.mapPin, c.locOk),
      ('Contacts', 'Pick your emergency contact', Ic.user, c.contactsOk),
    ];
    Widget field(TextEditingController ctl, String label, String hint,
            {TextInputType? type, int idx = -1}) =>
        Semantics(
          label: label,
          textField: true,
          child: TextField(
            controller: ctl,
            keyboardType: type,
            style: ts(14, w: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: ts(14, c: K.mutedText),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: c.activeField == idx ? K.purple : K.line,
                      width: c.activeField == idx ? 2 : 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: K.purple, width: 2)),
            ),
          ),
        );
    return _scroll([
      _topBar(c, Screen.onboarding),
      _label(
          'VOICE SIGN-UP: ${c.voice.stateLabel.replaceAll('.', '').toUpperCase()}'),
      if (c.voice.heard.isNotEmpty) _label('HEARD: ${c.voice.heard}'),
      _label('PREFERRED SPOKEN LANGUAGE'),
      Row(children: [
        for (final l in AppLang.values) ...[
          if (l != AppLang.en) const SizedBox(width: 8),
          Expanded(child: LangChip(c, l)),
        ]
      ]),
      _label('ACCESS PERMISSIONS', gap: true),
      for (var i = 0; i < perms.length; i++)
        Tap(
          label:
              '${perms[i].$1}. ${perms[i].$2}. ${perms[i].$4 ? 'Allowed' : 'Not allowed yet. Double tap to allow.'}',
          onTap: () => c.requestPermissionRow(i),
          child: KCard(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: Row(children: [
                MiniIcon(perms[i].$3),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(perms[i].$1, style: ts(14, w: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(perms[i].$2, style: ts(12, c: K.mutedText)),
                      ]),
                ),
                perms[i].$4
                    ? const Icon(Ic.check, size: 20, color: K.green)
                    : Text('Allow',
                        style: ts(13, w: FontWeight.w800, c: K.purpleText)),
              ]),
            ),
          ),
        ),
      _label('YOUR PROFILE', gap: true),
      field(c.nameCtl, 'Your full name', 'Kane Sharma', idx: 0),
      field(c.phoneCtl, 'Your phone number', '+91 98201 43210',
          type: TextInputType.phone, idx: 1),
      field(c.emergencyCtl, 'Emergency contact: name, relation and number',
          'Priya Sharma (Sister) • +91 98201 99999',
          idx: 2),
      Row(children: [
        Expanded(
            child: SoftButton('Stop speaking',
                icon: Ic.square, onTap: c.voice.stop)),
        const SizedBox(width: 8),
        Expanded(
            child: SoftButton('Restart voice sign-up',
                icon: Ic.mic, onTap: c.startSignup)),
      ]),
      PrimaryButton('Confirm & Open Kalpana',
          icon: Ic.check, onTap: c.finishOnboarding),
    ]);
  }
}

class LangChip extends StatelessWidget {
  final AppController c;
  final AppLang l;
  const LangChip(this.c, this.l, {super.key});
  @override
  Widget build(BuildContext context) {
    final sel = c.lang == l;
    return Tap(
      label: '${l.english}${sel ? ', selected' : ''}',
      onTap: () => c.changeLanguage(l),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border:
                Border.all(color: sel ? K.lilac : K.line, width: sel ? 2 : 1)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(l.label, style: ts(14, w: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(sel ? 'Primary' : l.english, style: ts(12, c: K.mutedText)),
        ]),
      ),
    );
  }
}

// -------------------------------------------------------------- Dashboard
class DashboardScreen extends StatelessWidget {
  final AppController c;
  const DashboardScreen(this.c, {super.key});
  @override
  Widget build(BuildContext context) {
    const tools = [
      (
        'Explore',
        'Live obstacles',
        Ic.radio,
        Color(0xFFEBF6F1),
        Screen.explore
      ),
      (
        'Read Text',
        'Signs & notices',
        Ic.fileText,
        Color(0xFFEDF3FC),
        Screen.ocr
      ),
      (
        'Where Am I?',
        'GPS landmark',
        Ic.crosshair,
        Color(0xFFF6EFF8),
        Screen.location
      ),
      (
        'Emergency SOS',
        'Alert contacts',
        Ic.alert,
        Color(0xFFFFF0F0),
        Screen.sos
      ),
      (
        'Community Chat',
        'Assistive reply',
        Ic.message,
        Color(0xFFF4EFFC),
        Screen.community
      ),
      (
        'Color ID',
        'Fabric & items',
        Ic.palette,
        Color(0xFFFFF9EC),
        Screen.color
      ),
    ];
    final w = (MediaQuery.of(context).size.width.clamp(0, 430) - 40 - 8) / 2;
    return _scroll([
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Wordmark(), SizedBox(height: 4), CountryPill()]),
        Row(children: [
          IconBtn(Ic.help, 'Help: voice directory', () => c.go(Screen.help)),
          IconBtn(Ic.settings, 'Settings', () => c.go(Screen.settings))
        ]),
      ]),
      Column(children: [
        Semantics(
            header: true,
            child: Text(c.greeting(),
                textAlign: TextAlign.center,
                style: ts(22, w: FontWeight.w700))),
        const SizedBox(height: 2),
        Text('How can I help you today?', style: ts(14, c: K.mutedText)),
      ]),
      Column(children: [
        Orb(size: 128, state: c.voice.state, onTap: c.openVoice),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: K.line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: K.green)),
            const SizedBox(width: 6),
            Flexible(
                child: Text('Tap the orb, then say “Kalpana, help me”',
                    style: ts(12.5, w: FontWeight.w600, c: K.btnText))),
          ]),
        ),
      ]),
      Tap(
        label: c.reminders.isEmpty
            ? 'No reminders yet. Open reminders.'
            : 'Reminder: ${c.reminders.first}. Open reminders.',
        onTap: () => c.go(Screen.daily),
        child: KCard(
          child: Row(children: [
            const MiniIcon(Ic.bell),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        c.reminders.isEmpty
                            ? 'No reminders yet'
                            : c.reminders.first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(14, w: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                        c.reminders.isEmpty
                            ? 'Say “remind me to…”'
                            : '${c.reminders.length} saved',
                        style: ts(12, c: K.mutedText)),
                  ]),
            ),
            const Icon(Ic.chevronRight, size: 18, color: K.purple),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _label('ACCESSIBILITY TOOLS'),
          Text('6 Shortcuts', style: ts(11, c: K.mutedText))
        ]),
      ),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in tools)
          Tap(
            label: '${t.$1}. ${t.$2}',
            onTap: () => c.go(t.$5),
            child: Container(
              width: w,
              constraints: const BoxConstraints(minHeight: 84),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: K.line)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                MiniIcon(t.$3,
                    bg: t.$4,
                    color: t.$5 == Screen.sos ? K.coral : K.purple,
                    box: 31),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.$1,
                            style: ts(14,
                                w: FontWeight.w700,
                                c: t.$5 == Screen.sos
                                    ? const Color(0xFFB94444)
                                    : K.ink)),
                        const SizedBox(height: 3),
                        Text(t.$2, style: ts(12, c: K.mutedText, h: 1.2)),
                      ]),
                ),
              ]),
            ),
          ),
      ]),
    ]);
  }
}

// ------------------------------------------------------- Voice assistant
class CommandChips extends StatelessWidget {
  final AppController c;
  const CommandChips(this.c, {super.key});
  @override
  Widget build(BuildContext context) {
    final first = c.contacts.first.label.split(' ').first;
    final cmds = [
      'What is in front of me?',
      'Read this text',
      'Where am I?',
      'Open my reminders',
      'Change language to Marathi',
      'Call $first',
      'Help me',
      'Emergency'
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final e in cmds)
        Tap(
          label: 'Run command: $e',
          onTap: () => c.runCommand(e),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: K.line)),
            child: Text(e, style: ts(13, w: FontWeight.w600, c: K.btnText)),
          ),
        ),
    ]);
  }
}

class VoiceScreen extends StatelessWidget {
  final AppController c;
  const VoiceScreen(this.c, {super.key});
  @override
  Widget build(BuildContext context) {
    final v = c.voice;
    return _scroll([
      _topBar(c, Screen.voice),
      Column(children: [
        Orb(size: 156, state: v.state, onTap: c.listenAndRun),
        Semantics(
            liveRegion: true,
            child: Text(v.stateLabel.toUpperCase(),
                style: ts(12, w: FontWeight.w800, c: K.purpleText, ls: 1))),
      ]),
      KCard(
        child: Row(children: [
          const Icon(Ic.user, size: 17, color: K.purple),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('YOU SAID',
                  style: ts(10.5, w: FontWeight.w800, c: K.purpleText, ls: .4)),
              const SizedBox(height: 4),
              Text(
                  v.heard.isEmpty
                      ? '“Tap the orb and speak, or type below.”'
                      : '“${v.heard}”',
                  style: ts(14, h: 1.5)),
            ]),
          ),
        ]),
      ),
      KCard(
        child: Row(children: [
          const Icon(Ic.sparkles, size: 17, color: K.purple),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('KALPANA',
                  style: ts(10.5, w: FontWeight.w800, c: K.purpleText, ls: .4)),
              const SizedBox(height: 4),
              Text('“${v.spoken}”', style: ts(14, h: 1.5)),
            ]),
          ),
        ]),
      ),
      Row(children: [
        Expanded(
            child: SoftButton('Listen', icon: Ic.mic, onTap: c.listenAndRun)),
        const SizedBox(width: 7),
        Expanded(
            child: SoftButton('Repeat',
                icon: Ic.play, onTap: () => v.speak(v.spoken))),
        const SizedBox(width: 7),
        Expanded(child: SoftButton('Stop', icon: Ic.square, onTap: v.stop)),
      ]),
      _label('TYPE A COMMAND INSTEAD', gap: true),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: K.line)),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: c.typedCtl,
              style: ts(14),
              textInputAction: TextInputAction.send,
              onSubmitted: (s) {
                c.runCommand(s);
                c.typedCtl.clear();
              },
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'e.g. “Where am I?”',
                  hintStyle: ts(14, c: K.mutedText)),
            ),
          ),
          Tap(
            label: 'Run typed command',
            onTap: () {
              c.runCommand(c.typedCtl.text);
              c.typedCtl.clear();
            },
            child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: K.lilac, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Ic.send, size: 18, color: K.ink)),
          ),
        ]),
      ),
      CommandChips(c),
    ]);
  }
}

// ----------------------------------------------- Detail (10 result screens)
class DetailScreen extends StatelessWidget {
  final AppController c;
  final Screen s;
  const DetailScreen(this.c, this.s, {super.key});
  @override
  Widget build(BuildContext context) {
    final i = c.info(s);
    final Widget hero;
    if (s == Screen.sos) {
      hero = Center(
        child: Tap(
          label:
              'Emergency SOS button. Double tap to start. I will ask you to confirm first.',
          onTap: c.sos,
          onLongPress: c.sos,
          child: Container(
            width: 168,
            height: 168,
            margin: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: K.coral,
                border: Border.all(color: const Color(0xFFFFE5E5), width: 5),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x59FF7676),
                      blurRadius: 18,
                      offset: Offset(0, 8))
                ]),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Ic.alert, size: 32, color: Colors.black87),
              const SizedBox(height: 4),
              Text('SOS',
                  style: ts(20, w: FontWeight.w800, c: Colors.black87, ls: 1)),
              Text('Tap or hold • Calls',
                  style: ts(11, w: FontWeight.w600, c: Colors.black87)),
            ]),
          ),
        ),
      );
    } else if (AppController.isCapture(s)) {
      hero = CameraBox(c);
    } else {
      hero = Container(
        constraints: const BoxConstraints(minHeight: 190),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: i.accent ?? const Color(0xFFF3F0F7),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: K.line)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(i.icon,
              size: 32,
              color: s == Screen.location ? const Color(0xFF9A74A4) : K.purple),
          const SizedBox(height: 12),
          Text(i.heading,
              textAlign: TextAlign.center, style: ts(16, w: FontWeight.w800)),
        ]),
      );
    }
    final sosOrDial = s == Screen.sos || s == Screen.dial;
    return _scroll([
      _topBar(c, s),
      hero,
      KCard(
        accent: i.accent,
        child: Row(children: [
          MiniIcon(i.icon),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i.subtitle,
                  style: ts(10.5, w: FontWeight.w800, c: K.purpleText, ls: .4)),
              const SizedBox(height: 4),
              Text(i.body, style: ts(14, h: 1.5)),
              if (i.demo) ...[
                const SizedBox(height: 6),
                Text('Sample content — live analysis not connected yet.',
                    style: ts(11.5, c: K.mutedText))
              ],
            ]),
          ),
        ]),
      ),
      if (s == Screen.dial)
        for (final k in c.contacts)
          Tap(
            label: 'Call ${k.label} on ${k.number}',
            onTap: () => c.callContact(k.label),
            child: KCard(
              child: Row(children: [
                const MiniIcon(Ic.phone),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('${k.label} • ${k.number}',
                        style: ts(14, w: FontWeight.w700))),
                Text('Call',
                    style: ts(13, w: FontWeight.w800, c: K.purpleText)),
              ]),
            ),
          ),
      if (s == Screen.sos)
        SoftButton('Send my location by text',
            icon: Ic.mapPin, onTap: c.sendLocation),
      if (s == Screen.community)
        Container(
          padding: const EdgeInsets.fromLTRB(12, 5, 5, 5),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: K.line)),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: c.chatCtl,
                style: ts(14),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Speak or type message...',
                    hintStyle: ts(14, c: K.mutedText)),
              ),
            ),
            IconBtn(Ic.mic, 'Dictate message', c.dictate),
            Tap(
              label: 'Send message',
              onTap: c.sendChat,
              child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: K.lilac, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Ic.send, size: 18, color: K.ink)),
            ),
          ]),
        ),
      if (s == Screen.help) ...[const HelpList(), CommandChips(c)],
      if (s == Screen.daily)
        SoftButton('Clear all reminders', onTap: c.clearReminders),
      if (s == Screen.settings) ...[
        _label('SPOKEN LANGUAGE'),
        Row(children: [
          for (final l in AppLang.values) ...[
            if (l != AppLang.en) const SizedBox(width: 8),
            Expanded(child: LangChip(c, l))
          ]
        ]),
        Row(children: [
          Expanded(
              child: SoftButton('Slower', onTap: () => c.adjustRate(-0.1))),
          const SizedBox(width: 8),
          Expanded(child: SoftButton('Faster', onTap: () => c.adjustRate(0.1))),
        ]),
        _toggle('Haptic Feedback', c.haptics, c.toggleHaptics),
        _toggle('High Contrast Borders', c.highContrast, c.toggleContrast),
      ],
      if (AppController.isCapture(s)) ...[
        PrimaryButton('Take Picture', icon: Ic.camera, onTap: c.takePicture),
        SoftButton('Speak Result Aloud', icon: Ic.volume, onTap: c.readCurrent),
      ] else
        PrimaryButton(
          s == Screen.sos
              ? 'Return to Dashboard'
              : s == Screen.dial
                  ? 'Back to Dashboard'
                  : 'Speak Result Aloud',
          icon: sosOrDial ? Ic.arrowLeft : Ic.volume,
          onTap: () => sosOrDial ? c.go(Screen.dashboard) : c.readCurrent(),
        ),
    ]);
  }

  Widget _toggle(String label, bool on, VoidCallback f) => Semantics(
        toggled: on,
        child: Tap(
          label: '$label, ${on ? 'on' : 'off'}. Double tap to change.',
          onTap: f,
          child: KCard(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: Row(children: [
                Expanded(child: Text(label, style: ts(14, w: FontWeight.w700))),
                Icon(on ? Ic.check : Ic.circle,
                    size: 20, color: on ? K.green : K.muted),
                const SizedBox(width: 4),
                Text(on ? 'On' : 'Off', style: ts(12, c: K.mutedText)),
              ]),
            ),
          ),
        ),
      );
}

/// Live camera preview (falls back to the Bolt placeholder until the camera is ready).
class CameraBox extends StatelessWidget {
  final AppController c;
  const CameraBox(this.c, {super.key});
  @override
  Widget build(BuildContext context) {
    final ctl = c.cam;
    final ready = ctl != null && c.camReady && ctl.value.previewSize != null;
    return Semantics(
      label: ready ? 'Camera preview' : 'Camera is starting',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 260,
          color: const Color(0xFFF3F0F7),
          child: ready
              ? FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                      width: ctl.value.previewSize!.height,
                      height: ctl.value.previewSize!.width,
                      child: CameraPreview(ctl)),
                )
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(c.info(c.screen).icon, size: 32, color: K.purple),
                  const SizedBox(height: 10),
                  Text(
                      c.camOk ? 'Starting camera…' : 'Camera permission needed',
                      style: ts(14, w: FontWeight.w700)),
                ]),
        ),
      ),
    );
  }
}

/// Which spoken command opens which page (shown on the Help screen).
class HelpList extends StatelessWidget {
  const HelpList({super.key});
  @override
  Widget build(BuildContext context) {
    const rows = [
      (
        'Reminders',
        '“Open my reminders” • “Remind me to take medicine at 2 PM”',
        Ic.bell
      ),
      ('Read Text', '“Read this text” • “What is this?”', Ic.fileText),
      ('Explore', '“Describe my surroundings”', Ic.radio),
      ('Color ID', '“Identify this colour”', Ic.palette),
      ('Where Am I?', '“Where am I?”', Ic.crosshair),
      ('Call', '“Call Priya” • “Call emergency contact”', Ic.phone),
      ('Emergency SOS', '“Emergency”', Ic.alert),
      ('Language', '“Change language to Hindi / Marathi”', Ic.mic),
      ('Pause me', '“Stop listening” — wake me with “Hey Kalpana”', Ic.volume),
    ];
    return Column(children: [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            label:
                '${r.$1}. Say ${r.$2.replaceAll('“', '').replaceAll('”', '')}',
            excludeSemantics: true,
            child: KCard(
              child: Row(children: [
                MiniIcon(r.$3),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$1, style: ts(14, w: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(r.$2, style: ts(12.5, c: K.mutedText, h: 1.3)),
                      ]),
                ),
              ]),
            ),
          ),
        ),
    ]);
  }
}
