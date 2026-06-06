import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/llm_provider.dart';
import '../services/storage/secure_storage_service.dart';
import '../services/llm/llm_resolver.dart';
import '../services/email/gmail_api_service.dart';
import 'service_providers.dart';

class SettingsState {
  final Map<String, String> apiKeys;
  final LLMProvider selectedProvider;
  final String selectedModel;
  final bool hasGmailToken;

  const SettingsState({
    this.apiKeys = const {},
    this.selectedProvider = LLMProvider.gemini,
    this.selectedModel = 'gemini-1.5-flash',
    this.hasGmailToken = false,
  });

  SettingsState copyWith({
    Map<String, String>? apiKeys,
    LLMProvider? selectedProvider,
    String? selectedModel,
    bool? hasGmailToken,
  }) {
    return SettingsState(
      apiKeys: apiKeys ?? this.apiKeys,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedModel: selectedModel ?? this.selectedModel,
      hasGmailToken: hasGmailToken ?? this.hasGmailToken,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SecureStorageService _storage;
  final LLMResolver _resolver;
  final GmailApiService _gmailService;

  SettingsNotifier(this._storage, this._resolver, this._gmailService)
      : super(const SettingsState()) {
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final keys = await _storage.getAllApiKeys();
    state = state.copyWith(
      apiKeys: keys.map((k, v) => MapEntry(k, v ?? '')),
    );
    _resolver.configureAll(keys);
  }

  Future<void> saveApiKey(String provider, String key) async {
    await _storage.saveApiKey(provider, key);
    state = state.copyWith(
      apiKeys: {...state.apiKeys, provider: key},
    );
    _resolver.configureAll({provider: key});
  }

  Future<void> deleteApiKey(String provider) async {
    await _storage.deleteApiKey(provider);
    state = state.copyWith(
      apiKeys: {...state.apiKeys, provider: ''},
    );
  }

  void selectProvider(LLMProvider provider) {
    state = state.copyWith(
      selectedProvider: provider,
      selectedModel: provider.defaultModel,
    );
  }

  void selectModel(String model) {
    state = state.copyWith(selectedModel: model);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(
    ref.watch(secureStorageProvider),
    ref.watch(llmResolverProvider),
    ref.watch(gmailApiServiceProvider),
  );
});
