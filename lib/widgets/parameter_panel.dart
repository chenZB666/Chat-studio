import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/conversation_list_provider.dart';
import '../providers/providers.dart';

class ParameterPanel extends ConsumerStatefulWidget {
  const ParameterPanel({super.key});

  @override
  ConsumerState<ParameterPanel> createState() => _ParameterPanelState();
}

class _ParameterPanelState extends ConsumerState<ParameterPanel> {
  bool _expanded = false;

  // Debounce timers for each parameter to avoid excessive DB writes
  Timer? _debounceTimer;

  void _debouncedUpdate({
    double? temperature,
    double? topP,
    int? topK,
    int? maxTokens,
    double? repeatPenalty,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      final convId = ref.read(conversationListProvider).activeConversationId;
      if (convId != null) {
        ref.read(storageServiceProvider).updateConversationParameters(
          convId,
          temperature: temperature,
          topP: topP,
          topK: topK,
          maxTokens: maxTokens,
          repeatPenalty: repeatPenalty,
        );
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final convState = ref.watch(conversationListProvider);
    final convId = convState.activeConversationId;

    double temperature = 0.7, topP = 0.9, repeatPenalty = 1.1;
    int topK = 40, maxTokens = 4096;

    if (convId != null) {
      final convs = convState.conversations.where((c) => c.id == convId);
      if (convs.isNotEmpty) {
        final c = convs.first;
        temperature = c.temperature;
        topP = c.topP;
        topK = c.topK;
        maxTokens = c.maxTokens;
        repeatPenalty = c.repeatPenalty;
      }
    }

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Temperature $temperature  •  Max Tokens $maxTokens',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildSlider('Temperature', temperature, 0.0, 2.0, (v) {
                  _debouncedUpdate(temperature: v);
                }),
                _buildSlider('Top-P', topP, 0.0, 1.0, (v) {
                  _debouncedUpdate(topP: v);
                }),
                _buildSlider('Top-K', topK.toDouble(), 0, 100, (v) {
                  _debouncedUpdate(topK: v.round());
                }),
                _buildSlider('Max Tokens', maxTokens.toDouble(), 256, 32768, (v) {
                  _debouncedUpdate(maxTokens: v.round());
                }),
                _buildSlider('Repeat Penalty', repeatPenalty, 1.0, 2.0, (v) {
                  _debouncedUpdate(repeatPenalty: v);
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, void Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min) / 0.1).round().clamp(1, 1000),
              label: value.toStringAsFixed(2),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}