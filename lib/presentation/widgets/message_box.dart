import 'dart:async';

import 'package:flutter/material.dart';

import 'retro_window.dart';

/// 1文字ずつ表示するタイプライター風テキスト。
class TypewriterText extends StatefulWidget {
  final String text;
  final int charDelayMs;
  final TextStyle? style;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.charDelayMs = 22,
    this.style,
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => TypewriterTextState();
}

class TypewriterTextState extends State<TypewriterText> {
  int _count = 0;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _count = 0;
      _done = false;
      _start();
    }
  }

  void _start() {
    if (widget.charDelayMs <= 0) {
      _complete();
      return;
    }
    _timer = Timer.periodic(Duration(milliseconds: widget.charDelayMs), (t) {
      if (!mounted) return;
      if (_count >= widget.text.length) {
        _complete();
        return;
      }
      setState(() => _count++);
    });
  }

  void _complete() {
    _timer?.cancel();
    if (_done) return;
    setState(() {
      _count = widget.text.length;
      _done = true;
    });
    widget.onComplete?.call();
  }

  /// 即座に全文表示する。
  void skip() {
    if (!_done) _complete();
  }

  bool get isDone => _done;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.text.substring(0, _count.clamp(0, widget.text.length));
    return Text(shown, style: widget.style);
  }
}

/// メッセージ列を順番に表示するレトロなメッセージウィンドウ。
/// タップで「全文表示 → 次へ」。最後まで進むと [onDone] を呼ぶ。
class MessageQueueBox extends StatefulWidget {
  final List<String> messages;
  final int charDelayMs;
  final VoidCallback? onDone;
  final double minHeight;

  const MessageQueueBox({
    super.key,
    required this.messages,
    this.charDelayMs = 22,
    this.onDone,
    this.minHeight = 88,
  });

  @override
  State<MessageQueueBox> createState() => _MessageQueueBoxState();
}

class _MessageQueueBoxState extends State<MessageQueueBox> {
  int _index = 0;
  bool _finished = false;
  final _twKey = GlobalKey<TypewriterTextState>();

  @override
  void didUpdateWidget(MessageQueueBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.messages, widget.messages)) {
      _index = 0;
      _finished = false;
    }
  }

  void _advance() {
    final tw = _twKey.currentState;
    if (tw != null && !tw.isDone) {
      tw.skip();
      return;
    }
    if (_index < widget.messages.length - 1) {
      setState(() => _index++);
    } else {
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages.isEmpty ? const [''] : widget.messages;
    final text = messages[_index.clamp(0, messages.length - 1)];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: RetroWindow(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.minHeight, minWidth: double.infinity),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: TypewriterText(
                  key: _twKey,
                  text: text,
                  charDelayMs: widget.charDelayMs,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  onComplete: () {
                    if (mounted) setState(() => _finished = true);
                  },
                ),
              ),
              if (_finished)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: _BlinkArrow(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkArrow extends StatefulWidget {
  const _BlinkArrow();
  @override
  State<_BlinkArrow> createState() => _BlinkArrowState();
}

class _BlinkArrowState extends State<_BlinkArrow> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: const Icon(Icons.arrow_drop_down, size: 24),
    );
  }
}
