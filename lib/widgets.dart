import 'package:flutter/material.dart';
import 'theme.dart';
import 'voice/voice_service.dart';

TextStyle ts(double size, {FontWeight w = FontWeight.w400, Color c = K.ink, double? h, double? ls}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls);

/// Accessible tap target: announces as a button with [label], same pressed
/// feedback as Bolt (opacity .75 + scale .98), supports long-press.
class Tap extends StatefulWidget {
  final String label;
  final VoidCallback? onTap, onLongPress;
  final Widget child;
  const Tap({super.key, required this.label, required this.child, this.onTap, this.onLongPress});
  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool down = false;
  void _d(bool v) => setState(() => down = v);
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _d(true),
          onTapUp: (_) => _d(false),
          onTapCancel: () => _d(false),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Opacity(opacity: down ? .75 : 1, child: Transform.scale(scale: down ? .98 : 1, child: widget.child)),
        ),
      );
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key});
  @override
  Widget build(BuildContext context) {
    final st = ts(22, w: FontWeight.w800, ls: -0.6);
    return Semantics(
      label: 'Kalpana',
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Kalpa', style: st),
        const SizedBox(width: 4),
        SizedBox(
          width: 15,
          height: 19,
          child: Wrap(spacing: 2, runSpacing: 2, alignment: WrapAlignment.center, runAlignment: WrapAlignment.center, children: [
            for (final f in [1, 1, 0, 1, 1, 0])
              Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: f == 1 ? K.ink : const Color(0xFFE5DFEF)))
          ]),
        ),
        const SizedBox(width: 4),
        Text('a', style: st),
      ]),
    );
  }
}

class CountryPill extends StatelessWidget {
  const CountryPill({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: K.line)),
        child: Text('India', style: ts(12, c: K.mutedText)),
      );
}

/// The floating voice orb. Its icon, ring and spoken label change with [state]
/// so listening / processing / success / error are never colour-only.
class Orb extends StatefulWidget {
  final double size;
  final VoiceState state;
  final VoidCallback? onTap;
  const Orb({super.key, this.size = 156, this.state = VoiceState.idle, this.onTap});
  @override
  State<Orb> createState() => _OrbState();
}

class _OrbState extends State<Orb> with SingleTickerProviderStateMixin {
  late final AnimationController a =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2100))..repeat(reverse: true);
  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final (Color ring, IconData icon, String label) = switch (widget.state) {
      VoiceState.idle => (const Color(0xFFD9C9FA), Ic.mic, 'Ready'),
      VoiceState.listening => (K.teal, Ic.mic, 'Listening'),
      VoiceState.processing => (K.gold, Ic.sparkles, 'Thinking'),
      VoiceState.speaking => (K.purple, Ic.volume, 'Speaking'),
      VoiceState.success => (K.green, Ic.check, 'Done'),
      VoiceState.error => (K.coral, Ic.alert, 'Something went wrong, tap to try again'),
    };
    final v = CurvedAnimation(parent: a, curve: Curves.easeInOut);
    return Semantics(
      button: true,
      label: 'Microphone. $label. Double tap to speak to Kalpana.',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: s + 28,
          height: s + 28,
          child: AnimatedBuilder(
            animation: v,
            builder: (_, __) {
              final dy = -7 * v.value;
              return Stack(alignment: Alignment.center, children: [
                Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.scale(
                    scale: 1 + 0.018 * v.value,
                    child: Container(
                      width: s + 22,
                      height: s + 22,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, border: Border.all(color: ring, width: widget.state == VoiceState.idle ? 1.5 : 3)),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, dy),
                  child: Container(
                    width: s,
                    height: s,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFFFFF), Color(0xFFEFB9D8), Color(0xFFD9CFF5), Color(0xFFBFDDFB)]),
                      boxShadow: [BoxShadow(color: Color(0x7AB8C0EB), blurRadius: 22, offset: Offset(0, 15))],
                    ),
                    child: Center(
                      child: Container(
                        width: 47,
                        height: 47,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x85FFFFFF)),
                        child: Icon(icon, size: 22, color: K.btnText),
                      ),
                    ),
                  ),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const PrimaryButton(this.label, {super.key, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        label: label,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: K.lilac, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xB3FFFFFF))),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(label, textAlign: TextAlign.center, style: ts(15, w: FontWeight.w700))),
            if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18, color: K.btnText)],
          ]),
        ),
      );
}

class SoftButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const SoftButton(this.label, {super.key, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        label: label,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: K.line)),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 16, color: K.mutedText), const SizedBox(width: 5)],
            Flexible(child: Text(label, style: ts(13, w: FontWeight.w700))),
          ]),
        ),
      );
}

class KCard extends StatelessWidget {
  final Widget child;
  final Color? accent;
  const KCard({super.key, required this.child, this.accent});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: accent ?? Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: accent ?? K.line),
          boxShadow: const [BoxShadow(color: Color(0x1AB4AAD7), blurRadius: 12, offset: Offset(0, 5))],
        ),
        child: child,
      );
}

class MiniIcon extends StatelessWidget {
  final IconData icon;
  final Color? bg, color;
  final double box;
  const MiniIcon(this.icon, {super.key, this.bg, this.color, this.box = 33});
  @override
  Widget build(BuildContext context) => Container(
        width: box,
        height: box,
        decoration: BoxDecoration(color: bg ?? K.lilacSoft, borderRadius: BorderRadius.circular(box / 3)),
        child: Icon(icon, size: 16, color: color ?? K.purple),
      );
}

/// 33px visual button inside a 48px touch target.
class IconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const IconBtn(this.icon, this.label, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => Tap(
        label: label,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: K.line)),
              child: Icon(icon, size: 17, color: K.mutedText),
            ),
          ),
        ),
      );
}

/// Large-button confirmation used before SOS, calls and messages.
class ConfirmDialog extends StatelessWidget {
  final String prompt;
  final void Function(bool) onChoice;
  const ConfirmDialog({super.key, required this.prompt, required this.onChoice});
  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Ic.alert, color: K.coral),
          const SizedBox(width: 8),
          Text('Please confirm', style: ts(17, w: FontWeight.w800)),
        ]),
        content: Text('$prompt\n\nYou can also tap a button.', style: ts(15, h: 1.5)),
        actions: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PrimaryButton('Yes, confirm', icon: Ic.check, onTap: () => onChoice(true)),
            const SizedBox(height: 10),
            SoftButton('No, cancel', onTap: () => onChoice(false)),
          ]),
        ],
      );
}
