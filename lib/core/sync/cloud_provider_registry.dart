import 'cloud_provider.dart';

/// Manages the lifecycle of [CloudProvider] instances and supports
/// runtime switching of the active sync provider.
class CloudStorageProviderRegistry {
  final Map<String, CloudProvider> _providers = {};
  final List<void Function(List<CloudProvider>)> _listeners = [];

  /// Register a cloud provider instance.
  void register(CloudProvider provider) {
    _providers[provider.providerType] = provider;
    _notifyListeners();
  }

  /// Unregister a provider by type.
  void unregister(String providerType) {
    _providers.remove(providerType);
    _notifyListeners();
  }

  /// Get a provider by type.
  CloudProvider? get(String providerType) => _providers[providerType];

  /// All registered providers.
  List<CloudProvider> get all => _providers.values.toList(growable: false);

  /// Listen for provider registration changes.
  void addListener(void Function(List<CloudProvider>) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(List<CloudProvider>) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    final providers = all;
    for (final listener in _listeners) {
      listener(providers);
    }
  }

  /// Dispose all providers.
  Future<void> dispose() async {
    for (final provider in _providers.values) {
      await provider.deauthenticate();
    }
    _providers.clear();
    _listeners.clear();
  }
}
