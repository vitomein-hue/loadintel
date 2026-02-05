import 'dart:io';

import 'package:flutter/material.dart';
import 'package:loadintel/core/utils/fps_stats.dart';
import 'package:loadintel/domain/models/firearm.dart';
import 'package:loadintel/domain/models/range_result.dart';
import 'package:loadintel/domain/models/target_photo.dart';
import 'package:loadintel/domain/repositories/firearm_repository.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/domain/repositories/range_result_repository.dart';
import 'package:loadintel/domain/repositories/target_photo_repository.dart';
import 'package:loadintel/features/build_load/build_load_screen.dart';
import 'package:loadintel/services/photo_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class EditResultScreen extends StatefulWidget {
  const EditResultScreen({super.key, required this.result});

  final RangeResult result;

  @override
  State<EditResultScreen> createState() => _EditResultScreenState();
}

class _EditResultScreenState extends State<EditResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  final _photoService = PhotoService();

  late final TextEditingController _distanceController;
  late final TextEditingController _groupController;
  late final TextEditingController _avgController;
  late final TextEditingController _sdController;
  late final TextEditingController _esController;
  late final TextEditingController _notesController;

  late DateTime _testedAt;
  String? _firearmId;
  bool _shotsMode = false;
  final List<TextEditingController> _shotControllers = [];
  final List<TargetPhoto> _photos = [];
  late Future<List<Firearm>> _firearmsFuture;

  @override
  void initState() {
    super.initState();
    _distanceController =
        TextEditingController(text: widget.result.distanceYds.toString());
    _groupController =
        TextEditingController(text: widget.result.groupSizeIn.toString());
    _avgController = TextEditingController(text: widget.result.avgFps?.toString() ?? '');
    _sdController = TextEditingController(text: widget.result.sdFps?.toString() ?? '');
    _esController = TextEditingController(text: widget.result.esFps?.toString() ?? '');
    _notesController = TextEditingController(text: widget.result.notes ?? '');

    _testedAt = widget.result.testedAt;
    _firearmId = widget.result.firearmId;
    _shotsMode = widget.result.fpsShots != null && widget.result.fpsShots!.isNotEmpty;
    _initShotControllers(widget.result.fpsShots);

    _firearmsFuture = context.read<FirearmRepository>().listFirearms();
    _loadPhotos();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _groupController.dispose();
    _avgController.dispose();
    _sdController.dispose();
    _esController.dispose();
    _notesController.dispose();
    for (final controller in _shotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initShotControllers(List<double>? shots) {
    _shotControllers.clear();
    if (shots != null && shots.isNotEmpty) {
      for (final shot in shots) {
        _shotControllers.add(TextEditingController(text: shot.toString()));
      }
    }
    if (_shotControllers.isEmpty) {
      _shotControllers.add(TextEditingController());
    }
  }

  Future<void> _loadPhotos() async {
    final repo = context.read<TargetPhotoRepository>();
    final photos = await repo.listPhotosForResult(widget.result.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _photos
        ..clear()
        ..addAll(photos);
    });
  }

  Future<void> _pickTestedAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _testedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_testedAt),
    );
    final timeValue = time ?? TimeOfDay.fromDateTime(_testedAt);
    setState(() {
      _testedAt = DateTime(
        date.year,
        date.month,
        date.day,
        timeValue.hour,
        timeValue.minute,
      );
    });
  }

  Future<void> _switchMode(bool shotsMode) async {
    if (_shotsMode == shotsMode) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch entry mode?'),
        content: const Text('Switching entry mode clears current FPS inputs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _shotsMode = shotsMode;
      _avgController.clear();
      _sdController.clear();
      _esController.clear();
      for (final controller in _shotControllers) {
        controller.dispose();
      }
      _shotControllers
        ..clear()
        ..add(TextEditingController());
    });
  }

  List<double> _currentShots() {
    return _shotControllers
        .map((controller) => double.tryParse(controller.text.trim()))
        .whereType<double>()
        .toList();
  }

  FpsStats? _statsForShots(List<double> shots) {
    if (shots.length < 2) {
      return null;
    }
    return computeFpsStats(shots);
  }

  Future<void> _addPhoto() async {
    final picked = await _photoService.pickFromGallery();
    if (picked == null) {
      return;
    }
    final savedPath = await _photoService.persistAndSave(picked);
    if (savedPath == null) {
      return;
    }
    final repo = context.read<TargetPhotoRepository>();
    final photo = TargetPhoto(
      id: _uuid.v4(),
      rangeResultId: widget.result.id,
      galleryPath: savedPath,
      thumbPath: null,
    );
    await repo.addPhoto(photo);
    if (!mounted) {
      return;
    }
    setState(() {
      _photos.add(photo);
    });
  }

  Future<void> _removePhoto(TargetPhoto photo) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete photo?'),
            content: const Text('This will remove the photo from this result.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    final repo = context.read<TargetPhotoRepository>();
    await repo.deletePhoto(photo.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _photos.removeWhere((item) => item.id == photo.id);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final distance = double.tryParse(_distanceController.text.trim());
    if (distance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter distance.')),
      );
      return;
    }
    if (_firearmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a firearm.')),
      );
      return;
    }

    final shots = _shotsMode ? _currentShots() : <double>[];
    if (_shotsMode && shots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one shot.')),
      );
      return;
    }

    double? avgFps;
    double? sdFps;
    double? esFps;
    if (_shotsMode) {
      final stats = _statsForShots(shots);
      avgFps = stats?.average;
      sdFps = stats?.sd;
      esFps = stats?.es;
    } else {
      avgFps = double.tryParse(_avgController.text.trim());
      sdFps = double.tryParse(_sdController.text.trim());
      esFps = double.tryParse(_esController.text.trim());
      if (avgFps == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter AVG FPS.')),
        );
        return;
      }
    }

    final groupSize = double.parse(_groupController.text.trim());
    final updated = widget.result.copyWith(
      testedAt: _testedAt,
      firearmId: _firearmId,
      distanceYds: distance,
      fpsShots: _shotsMode ? shots : null,
      avgFps: avgFps,
      sdFps: sdFps,
      esFps: esFps,
      groupSizeIn: groupSize,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    await context.read<RangeResultRepository>().updateResult(updated);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _editLoad() async {
    final loadRepo = context.read<LoadRecipeRepository>();
    final recipe = await loadRepo.getRecipe(widget.result.loadId);
    if (!mounted) {
      return;
    }
    if (recipe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Load recipe not found.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BuildLoadScreen(recipe: recipe)),
    );
  }

  Future<void> _deleteResult() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Result'),
            content: const Text(
              'Delete this test result? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await context.read<RangeResultRepository>().deleteResult(widget.result.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Result'),
        actions: [
          IconButton(
            onPressed: _deleteResult,
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Firearm>>(
          future: _firearmsFuture,
          builder: (context, snapshot) {
            final firearms = snapshot.data ?? [];
            final shots = _currentShots();
            final stats = _shotsMode ? _statsForShots(shots) : null;
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _editLoad,
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Load'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Tested: ${_formatDateTime(_testedAt)}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              TextButton(
                                onPressed: _pickTestedAt,
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                          DropdownButtonFormField<String?>(
                            value: firearms.any((f) => f.id == _firearmId)
                                ? _firearmId
                                : null,
                            decoration: const InputDecoration(labelText: 'Firearm'),
                            items: firearms
                                .map(
                                  (firearm) => DropdownMenuItem<String?>(
                                    value: firearm.id,
                                    child: Text(firearm.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _firearmId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _distanceController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Distance (yds)'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _shotsMode
                                ? OutlinedButton(
                                    onPressed: () => _switchMode(false),
                                    child: const Text('Use Manual Summary'),
                                  )
                                : OutlinedButton(
                                    onPressed: () => _switchMode(true),
                                    child: const Text('Use Shot-by-shot'),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          if (_shotsMode)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ..._shotControllers.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final controller = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: TextField(
                                      controller: controller,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(labelText: 'Shot ${index + 1}'),
                                      onChanged: (_) {
                                        if (index == _shotControllers.length - 1 &&
                                            controller.text.trim().isNotEmpty) {
                                          setState(() {
                                            _shotControllers.add(TextEditingController());
                                          });
                                          return;
                                        }
                                        setState(() {});
                                      },
                                    ),
                                  );
                                }),
                                if (stats != null)
                                  Text(
                                    'AVG ${stats.average.toStringAsFixed(1)} '
                                    '| SD ${stats.sd.toStringAsFixed(1)} '
                                    '| ES ${stats.es.toStringAsFixed(1)}',
                                  ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                TextFormField(
                                  controller: _avgController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'AVG FPS *'),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value.trim()) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _sdController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'SD FPS'),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _esController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'ES FPS'),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _groupController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Group Size (in)'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Notes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Photos',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _addPhoto,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          if (_photos.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('No photos yet.'),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _photos
                                    .map(
                                      (photo) => Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              File(photo.thumbPath ?? photo.galleryPath),
                                              width: 72,
                                              height: 72,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 72,
                                                height: 72,
                                                color: Colors.black12,
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.image_not_supported),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: IconButton(
                                              icon: const Icon(Icons.close, size: 18),
                                              onPressed: () => _removePhoto(photo),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}
