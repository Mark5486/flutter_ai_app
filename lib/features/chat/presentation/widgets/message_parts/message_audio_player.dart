import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class MessageAudioPlayer extends StatefulWidget {
  const MessageAudioPlayer({super.key, required this.audioUrl});

  final String audioUrl;

  @override
  State<MessageAudioPlayer> createState() => _MessageAudioPlayerState();
}

class _MessageAudioPlayerState extends State<MessageAudioPlayer> {
  static const _speedCycle = [1.0, 1.5, 2.0];

  final AudioPlayer _player = AudioPlayer();

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _hasError = false;

  StreamSubscription? _stateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _completeSubscription;

  @override
  void initState() {
    super.initState();

    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant MessageAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _reset();
    }
  }

  void _reset() {
    _player.stop();
    if (mounted) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
        _duration = Duration.zero;
        _hasError = false;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_hasError) {
      _showErrorToast();
      return;
    }

    if (_playerState == PlayerState.playing) {
      await _player.pause();
      return;
    }

    if (_playerState == PlayerState.paused) {
      await _player.resume();
      return;
    }

    try {
      await _player.setPlaybackRate(_speed);
      await _player.play(UrlSource(widget.audioUrl));
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
      _showErrorToast();
    }
  }

  Future<void> _seekTo(double value) async {
    if (_duration == Duration.zero || _hasError) return;

    final position = Duration(milliseconds: value.round());

    try {
      await _player.seek(position);
      if (mounted) setState(() => _position = position);
    } catch (_) {}
  }

  Future<void> _cycleSpeed() async {
    final next =
        _speedCycle[(_speedCycle.indexOf(_speed) + 1) % _speedCycle.length];

    try {
      await _player.setPlaybackRate(next);
      if (mounted) setState(() => _speed = next);
    } catch (_) {}
  }

  void _showErrorToast() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('تعذّر تشغيل هذه الرسالة الصوتية.'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double? get _sliderValue {
    if (_duration.inMilliseconds == 0) return null;
    final value = _position.inMilliseconds / _duration.inMilliseconds;
    return value.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;

    return Container(
      margin: const EdgeInsets.all(8),
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _PlayButton(
                isPlaying: isPlaying,
                hasError: _hasError,
                onTap: _togglePlayback,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _hasError
                      ? 'رسالة صوتية (تعذّر التشغيل)'
                      : 'رسالة صوتية',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _hasError ? null : _cycleSpeed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9F7BFF).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_speed.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Color(0xFF9F7BFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!_hasError) ...[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: const Color(0xFF9F7BFF),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _sliderValue ?? 0,
                onChanged:
                    _duration == Duration.zero ? null : (value) => _seekTo(
                      value * _duration.inMilliseconds,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.hasError,
    required this.onTap,
  });

  final bool isPlaying;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient:
                hasError
                    ? null
                    : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8E6BFF), Color(0xFF5B3DD8)],
                    ),
            color: hasError ? const Color(0xFFFF5C7A) : null,
            shape: BoxShape.circle,
          ),
          width: 40,
          height: 40,
          child: Icon(
            hasError
                ? Icons.error_outline
                : (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
