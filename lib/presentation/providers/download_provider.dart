import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_providers.dart';
import 'settings_providers.dart';

/// Possible states for the model download lifecycle.
enum DownloadStatus { idle, downloading, completed, error }

/// State object for tracking model download progress.
class DownloadState {
  const DownloadState({
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.errorMessage,
  });

  final DownloadStatus status;

  /// Download progress from 0.0 to 1.0.
  final double progress;

  final String? errorMessage;

  DownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    String? errorMessage,
  }) {
    return DownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier that drives model downloading with real-time progress.
class DownloadNotifier extends Notifier<DownloadState> {
  @override
  DownloadState build() {
    // Re-create when the model variant changes so state resets.
    ref.watch(modelVariantProvider);
    // If the model is already loaded (e.g. preloaded from asset), start
    // in the completed state so the UI shows "Model ready".
    final dataSource = ref.read(localGemmaDataSourceProvider);
    if (dataSource.isReady) {
      return const DownloadState(
        status: DownloadStatus.completed,
        progress: 1.0,
      );
    }
    return const DownloadState();
  }

  /// Starts installing/downloading the currently selected model variant.
  ///
  /// For bundled variants the model is installed from app assets (no
  /// network needed). For non-bundled variants it is downloaded from
  /// HuggingFace.
  Future<void> downloadModel() async {
    if (state.status == DownloadStatus.downloading) return;

    state = const DownloadState(status: DownloadStatus.downloading);

    final dataSource = ref.read(localGemmaDataSourceProvider);

    // If the model is already loaded, nothing to do.
    if (dataSource.isReady) {
      state = const DownloadState(
        status: DownloadStatus.completed,
        progress: 1.0,
      );
      return;
    }

    // Step 1 — Install the model file.
    bool installed;
    if (dataSource.variant.isBundled) {
      // Bundled variant — copy from app assets (fast, no network).
      installed = await dataSource.installFromAsset();
      if (installed) {
        state = state.copyWith(progress: 1.0);
      }
    } else {
      // Non-bundled — download from HuggingFace.
      installed = await dataSource.downloadModel(
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );
    }

    if (!installed) {
      state = DownloadState(
        status: DownloadStatus.error,
        errorMessage: dataSource.variant.isBundled
            ? 'Could not install bundled model. Please reinstall the app.'
            : 'Download failed. Please check your connection and try again.',
      );
      return;
    }

    // Step 2 — Load the model into memory.
    final loaded = await dataSource.loadModel();

    if (loaded) {
      state = const DownloadState(
        status: DownloadStatus.completed,
        progress: 1.0,
      );
    } else {
      state = const DownloadState(
        status: DownloadStatus.error,
        errorMessage: 'Model installed but could not be loaded. '
            'The model format may not be supported on this device.',
      );
    }
  }

  /// Resets back to idle (e.g. after dismissing an error).
  void reset() {
    state = const DownloadState();
  }
}

/// Provides the [DownloadNotifier] for the currently selected model.
final downloadProvider =
    NotifierProvider<DownloadNotifier, DownloadState>(DownloadNotifier.new);
