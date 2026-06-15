import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String? videoLabel;
  final String videoUrl;

  const VideoPlayerPage({super.key, this.videoLabel, required this.videoUrl});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _hasError = false;
  bool _isInitialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    if (widget.videoUrl.isEmpty ||
        !Uri.tryParse(widget.videoUrl)!.hasAbsolutePath == true) {
      _hasError = true;
      return;
    }

    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
              _controller.play();
            }
          })
          .catchError((e) {
            debugPrint("Video init error: $e");
            setState(() {
              _hasError = true;
            });
          });
  }

  @override
  void dispose() {
    if (!_hasError) _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  Widget _buildControlsOverlay() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          if (_showControls)
            Container(
              color: Colors.black26,
              child: Center(
                child: IconButton(
                  iconSize: 64,
                  color: Colors.white,
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  onPressed: _togglePlayPause,
                ),
              ),
            ),
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Colors.green,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.grey,
                ),
                padding: const EdgeInsets.all(10),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.videoLabel ?? "Video Preview")),
        body: const Center(
          child: Text("Video not available", style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.videoLabel ?? "Video Preview")),
      body: Center(
        child:
            _isInitialized
                ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      _buildControlsOverlay(),
                    ],
                  ),
                )
                : const CircularProgressIndicator(),
      ),
    );
  }
}
