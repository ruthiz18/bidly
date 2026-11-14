import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

/// Photo chooser for the sell and edit screens. Pick from gallery or camera,
/// upload to Cloudinary with a progress bar, and report the resulting URL
/// through [onChanged] (null = no photo). Parents should disable their save
/// button while [onBusyChanged] says true.
class PhotoField extends StatefulWidget {
  const PhotoField({
    super.key,
    required this.initialUrl,
    required this.onChanged,
    this.onBusyChanged,
  });

  final String? initialUrl;
  final ValueChanged<String?> onChanged;
  final ValueChanged<bool>? onBusyChanged;

  @override
  State<PhotoField> createState() => _PhotoFieldState();
}

class _PhotoFieldState extends State<PhotoField> {
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();

  String? _url;
  XFile? _local; // shown instantly while/after uploading
  double _progress = 0;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _url = widget.initialUrl;
  }

  Future<void> _pick(ImageSource source) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: 1600, // keep uploads small; this is the slowest step
        imageQuality: 85,
      );
    } catch (_) {
      setState(() => _error = 'Could not open the photo picker.');
      return;
    }
    if (file == null) return;

    setState(() {
      _local = file;
      _uploading = true;
      _progress = 0;
      _error = null;
    });
    widget.onBusyChanged?.call(true);
    try {
      final url = await _cloudinary.upload(file,
          onProgress: (p) => mounted ? setState(() => _progress = p) : null);
      if (!mounted) return;
      setState(() => _url = url);
      widget.onChanged(url);
    } on UploadException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _local = null; // fall back to the previous photo
      });
    } finally {
      if (mounted) setState(() => _uploading = false);
      widget.onBusyChanged?.call(false);
    }
  }

  void _remove() {
    setState(() {
      _url = null;
      _local = null;
      _error = null;
    });
    widget.onChanged(null);
  }

  void _chooseSource() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(ctx);
              _pick(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.pop(ctx);
              _pick(ImageSource.camera);
            },
          ),
        ]),
      ),
    );
  }

  Widget _preview() {
    if (_local != null) {
      return FutureBuilder(
        future: _local!.readAsBytes(),
        builder: (_, snap) => snap.hasData
            ? Image.memory(snap.data!, fit: BoxFit.cover, width: double.infinity)
            : const SizedBox.shrink(),
      );
    }
    if (_url != null) {
      return Image.network(_url!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  size: 40, color: AppColors.tertiary)));
    }
    return const Center(
        child: Icon(Icons.add_a_photo_outlined,
            size: 40, color: AppColors.tertiary));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasPhoto = _url != null || _local != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _uploading ? null : _chooseSource,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.field),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.field, child: _preview()),
                  if (_uploading)
                    Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LinearProgressIndicator(
                            value: _progress >= 1 ? null : _progress,
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _progress >= 1
                                ? 'Finishing up…'
                                : 'Uploading ${(_progress * 100).round()}%',
                            style: text.labelLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          TextButton.icon(
            onPressed: _uploading ? null : _chooseSource,
            icon: const Icon(Icons.image_outlined, size: 18),
            label: Text(hasPhoto ? 'Change photo' : 'Add photo'),
          ),
          if (hasPhoto)
            TextButton(
              onPressed: _uploading ? null : _remove,
              child: const Text('Remove'),
            ),
        ]),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(_error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ),
      ],
    );
  }
}
