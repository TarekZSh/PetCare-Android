import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPostWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPostWidget({required this.videoUrl, Key? key}) : super(key: key);

  @override
  _VideoPostWidgetState createState() => _VideoPostWidgetState();
}

class _VideoPostWidgetState extends State<VideoPostWidget> {
  late VideoPlayerController _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {}); // Trigger a rebuild once the video is initialized
      });

    // Add a listener to check for video completion
    _videoController.addListener(() {
      if (_videoController.value.position == _videoController.value.duration) {
        // Video playback is complete
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10), // Rounded corners
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Show video once initialized
          if (_videoController.value.isInitialized)
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_isPlaying) {
                    _videoController.pause();
                    _isPlaying = false;
                  } else {
                    _videoController.play();
                    _isPlaying = true;
                  }
                });
              },
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            // Show loading indicator while video is being initialized
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Play button overlay
          if (!_isPlaying || _videoController.value.position == _videoController.value.duration)
            GestureDetector(
              onTap: () {
                _videoController.seekTo(Duration.zero); // Restart the video
                _videoController.play();
                setState(() {
                  _isPlaying = true;
                });
              },
              child: Icon(
                Icons.play_circle_fill,
                size: 60,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }
}
