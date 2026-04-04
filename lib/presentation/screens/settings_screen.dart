import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/datasources/ai/local_gemma_data_source.dart';
import '../providers/chat_providers.dart';
import '../providers/download_provider.dart';
import '../providers/settings_providers.dart';

/// Settings screen for theme, model variant, and privacy controls.
///
/// All preferences are persisted locally via [SharedPreferences] and
/// never leave the device.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final themeMode = ref.watch(themeModeProvider);
    final modelVariant = ref.watch(modelVariantProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ---- Appearance ----
          _SectionHeader(title: 'Appearance', scheme: scheme),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(themeMode)),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),

          const Divider(height: 1),

          // ---- AI Model ----
          _SectionHeader(title: 'AI Model', scheme: scheme),
          _DeviceSpecTile(scheme: scheme),
          ListTile(
            leading: const Icon(Icons.memory_outlined),
            title: const Text('Gemma Model Variant'),
            subtitle: Text(modelVariant.displayName),
            trailing: FilledButton.tonal(
              onPressed: () => _showModelPicker(context, ref, modelVariant),
              child: const Text('Choose'),
            ),
            onTap: () => _showModelPicker(context, ref, modelVariant),
          ),
          _DownloadModelTile(ref: ref, scheme: scheme),

          const Divider(height: 1),

          // ---- Privacy ----
          _SectionHeader(title: 'Privacy', scheme: scheme),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Data Policy'),
            subtitle: Text(AppConstants.privacySlogan),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: scheme.error),
            title: Text(
              'Delete All Conversations',
              style: TextStyle(color: scheme.error),
            ),
            subtitle: const Text('This action cannot be undone'),
            onTap: () => _confirmDeleteAll(context, ref),
          ),

          const SizedBox(height: 32),

          // ---- About ----
          Center(
            child: Text(
              '${AppConstants.appName} v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---- Pickers ----

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (v) {
            if (v != null) {
              ref.read(themeModeProvider.notifier).setThemeMode(v);
            }
            Navigator.pop(ctx);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Theme',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              for (final mode in ThemeMode.values)
                RadioListTile<ThemeMode>(
                  title: Text(_themeModeLabel(mode)),
                  value: mode,
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showModelPicker(
    BuildContext context,
    WidgetRef ref,
    GemmaModelVariant current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            var selected = current;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Select Model Variant',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  RadioGroup<GemmaModelVariant>(
                    groupValue: selected,
                    onChanged: (v) async {
                      if (v == null) return;
                      // Show memory warning if the variant exceeds recommendation.
                      final proceed = await _checkMemoryWarning(ctx, v);
                      if (!proceed) return;
                      setSheetState(() => selected = v);
                      ref.read(modelVariantProvider.notifier).setVariant(v);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final variant in GemmaModelVariant.values)
                          RadioListTile<GemmaModelVariant>(
                            title: Text(variant.displayName),
                            subtitle: Text(_variantDescription(variant)),
                            value: variant,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Returns the minimum RAM (in MB) recommended for [variant].
  int _requiredRamMb(GemmaModelVariant variant) => switch (variant) {
        GemmaModelVariant.ultraLight => 0, // always fine
        GemmaModelVariant.standard => 5120, // 5 GB
        GemmaModelVariant.full => 8192, // 8 GB
      };

  /// Shows a memory warning dialog if [variant] exceeds the device's
  /// estimated RAM. Returns `true` if the user wants to proceed.
  Future<bool> _checkMemoryWarning(
    BuildContext context,
    GemmaModelVariant variant,
  ) async {
    final required = _requiredRamMb(variant);
    if (required == 0) return true; // always fine

    final ramMb = await _getDeviceRamMb();
    if (ramMb >= required) return true; // device can handle it

    if (!context.mounted) return false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Memory Warning'),
        content: const Text(
          "The model you've selected may exceed your device's memory, "
          'which can cause the app to crash. For the best experience, '
          'we recommend trying a smaller model.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proceed anyway'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  /// Reads the device RAM in MB (best-effort estimate).
  Future<int> _getDeviceRamMb() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        if (info.systemFeatures.contains('android.hardware.ram.low')) {
          return 2048;
        }
        final totalMem = info.data['totalMemory'] as int?;
        if (totalMem != null && totalMem > 0) {
          return (totalMem / (1024 * 1024)).round();
        }
        return 4096;
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final model = info.utsname.machine;
        if (model.startsWith('iPhone16,')) return 8192;
        if (model.startsWith('iPhone15,') || model.startsWith('iPhone14,')) {
          return 6144;
        }
        return 4096;
      }
    } catch (_) {}
    return 4096;
  }

  void _confirmDeleteAll(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete All Conversations?'),
        content: const Text(
          'All your chat history will be permanently removed '
          'from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(chatRepositoryProvider);
              final conversations =
                  await ref.read(conversationsProvider.future);
              for (final conv in conversations) {
                await repo.deleteConversation(conv.id);
              }
              ref.invalidate(conversationsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ---- Helpers ----

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System Default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  String _variantDescription(GemmaModelVariant variant) => switch (variant) {
        GemmaModelVariant.ultraLight =>
          'Gemma 3 1B — Bundled with app, no download needed',
        GemmaModelVariant.standard =>
          'Gemma 4 E2B (~2 GB) — Balanced for most phones',
        GemmaModelVariant.full =>
          'Gemma 4 E4B (~3 GB) — Highest quality, needs ≥ 8 GB RAM',
      };
}

/// Download-model tile: shows a button, progress bar, or completion state.
class _DownloadModelTile extends StatelessWidget {
  const _DownloadModelTile({required this.ref, required this.scheme});

  final WidgetRef ref;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadProvider);
    final variant = ref.watch(modelVariantProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: switch (downloadState.status) {
        DownloadStatus.idle => FilledButton.tonalIcon(
            onPressed: () =>
                ref.read(downloadProvider.notifier).downloadModel(),
            icon: Icon(
              variant.isBundled
                  ? Icons.play_arrow_rounded
                  : Icons.download_rounded,
            ),
            label: Text(
              variant.isBundled ? 'Load Bundled Model' : 'Download Model',
            ),
          ),
        DownloadStatus.downloading => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Downloading… ${(downloadState.progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: downloadState.progress,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        DownloadStatus.completed => Row(
            children: [
              Icon(Icons.check_circle_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Model ready',
                style: TextStyle(color: scheme.primary),
              ),
            ],
          ),
        DownloadStatus.error => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                downloadState.errorMessage ?? 'Download failed.',
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  ref.read(downloadProvider.notifier).reset();
                  ref.read(downloadProvider.notifier).downloadModel();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
      },
    );
  }
}

/// Section header for the settings list.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.scheme});

  final String title;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Shows device hardware info and a model recommendation.
class _DeviceSpecTile extends StatefulWidget {
  const _DeviceSpecTile({required this.scheme});

  final ColorScheme scheme;

  @override
  State<_DeviceSpecTile> createState() => _DeviceSpecTileState();
}

class _DeviceSpecTileState extends State<_DeviceSpecTile> {
  String _device = '';
  String _ram = '';
  String _recommendation = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final plugin = DeviceInfoPlugin();
    String device;
    int ramMb;

    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      device = '${info.manufacturer} ${info.model}';
      // systemFeatures doesn't expose RAM directly on all devices.
      // Use totalMemory from /proc/meminfo via the SDK helper.
      ramMb = info.systemFeatures.contains('android.hardware.ram.low')
          ? 2048
          : 4096; // conservative estimate when exact value unavailable
      final totalMem = info.data['totalMemory'] as int?;
      if (totalMem != null && totalMem > 0) {
        ramMb = (totalMem / (1024 * 1024)).round();
      }
    } else if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      device = '${info.name} (${info.utsname.machine})';
      // iOS doesn't expose RAM. Estimate from chip.
      final model = info.utsname.machine;
      ramMb = _estimateIosRam(model);
    } else {
      device = 'Unknown';
      ramMb = 4096;
    }

    final ramGb = (ramMb / 1024).toStringAsFixed(1);
    final rec = _recommendModel(ramMb);

    if (mounted) {
      setState(() {
        _device = device;
        _ram = '$ramGb GB';
        _recommendation = rec;
        _loaded = true;
      });
    }
  }

  /// Rough iOS RAM estimate based on device model identifier prefix.
  int _estimateIosRam(String model) {
    // iPhone 15 Pro / Pro Max → 8 GB
    if (model.startsWith('iPhone16,')) return 8192;
    // iPhone 15 / 14 Pro → 6 GB
    if (model.startsWith('iPhone15,') || model.startsWith('iPhone14,')) {
      return 6144;
    }
    // Older → 4 GB
    return 4096;
  }

  String _recommendModel(int ramMb) {
    if (ramMb >= 8192) {
      return 'Full (Gemma 4 E4B) — your device can handle it';
    } else if (ramMb >= 5120) {
      return 'Standard (Gemma 4 E2B) — good fit for your device';
    } else {
      return 'Ultra-Light (1B) — best for your device';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Reading device info…'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: widget.scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.phone_android_rounded,
                    size: 18,
                    color: widget.scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your Device',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: widget.scheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Device: $_device'),
              Text('Estimated RAM: $_ram'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: widget.scheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Recommended: $_recommendation',
                      style: TextStyle(
                        color: widget.scheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
