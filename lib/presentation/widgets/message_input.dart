import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Dynamic input bar with text field, mic, camera, and gallery actions.
///
/// When an image is attached, a removable preview thumbnail is shown
/// above the text field. The [onSend] callback receives the text and
/// an optional image file path.
///
/// Voice dictation is powered by the `speech_to_text` package. When the
/// user taps the mic icon, on-device speech recognition begins and
/// streams recognized text directly into the text field in real time.
class MessageInput extends StatefulWidget {
  const MessageInput({required this.onSend, super.key});

  /// Called when the user submits a message.
  /// The second parameter is an optional image file path.
  final void Function(String text, {String? imagePath}) onSend;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
  final _speech = stt.SpeechToText();

  String? _attachedImagePath;
  bool _isListening = false;
  bool _speechAvailable = false;

  // ---- Lifecycle ----

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        debugPrint('Speech recognition error: ${error.errorMsg}');
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
            // Auto-send when speech recognition finishes with text.
            _autoSendAfterVoice();
          }
        }
      },
    );
    if (mounted) setState(() {});
  }

  /// Automatically submits the message after voice dictation ends,
  /// if there is recognized text in the input field.
  void _autoSendAfterVoice() {
    final text = _controller.text.trim();
    if (text.isNotEmpty || _attachedImagePath != null) {
      // Small delay so the user can see the final transcription.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _submit();
      });
    }
  }

  // ---- Actions ----

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachedImagePath == null) return;

    widget.onSend(
      text.isNotEmpty ? text : 'Describe this image.',
      imagePath: _attachedImagePath,
    );
    _controller.clear();
    setState(() {
      _attachedImagePath = null;
    });
  }

  Future<void> _pickFromGallery() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() => _attachedImagePath = file.path);
    }
  }

  Future<void> _pickFromCamera() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() => _attachedImagePath = file.path);
    }
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is not available on this device.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  void _removeImage() {
    setState(() => _attachedImagePath = null);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = _controller.text.trim().isNotEmpty;
    final hasAttachment = _attachedImagePath != null;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview strip
          if (hasAttachment) _buildImagePreview(scheme),

          // Listening indicator
          if (_isListening) _buildListeningIndicator(scheme),

          // Input row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment actions (gallery + camera)
                _ActionIcon(
                  icon: Icons.photo_library_outlined,
                  tooltip: 'Gallery',
                  onPressed: _pickFromGallery,
                ),
                _ActionIcon(
                  icon: Icons.camera_alt_outlined,
                  tooltip: 'Camera',
                  onPressed: _pickFromCamera,
                ),

                // Text field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Message GemAI…',
                      filled: true,
                      fillColor:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 4),

                // Mic or Send
                if (hasText || hasAttachment)
                  _ActionIcon(
                    icon: Icons.send_rounded,
                    tooltip: 'Send',
                    filled: true,
                    onPressed: _submit,
                  )
                else
                  _ActionIcon(
                    icon: _isListening
                        ? Icons.stop_rounded
                        : Icons.mic_none_rounded,
                    tooltip: _isListening ? 'Stop dictation' : 'Voice input',
                    filled: _isListening,
                    onPressed: _toggleVoice,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme scheme) {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_attachedImagePath!),
                height: 72,
                width: 72,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: _removeImage,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.error,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: scheme.onError,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pulsing red dot + label shown while speech recognition is active.
  Widget _buildListeningIndicator(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            onEnd: () {
              // Continuously restart the animation while listening.
              if (_isListening) setState(() {});
            },
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.error,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Listening…',
            style: TextStyle(
              color: scheme.error,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small circular icon button used in the input bar.
class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return IconButton.filled(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 20),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: const EdgeInsets.all(8),
      );
    }
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 22),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: const EdgeInsets.all(8),
    );
  }
}
