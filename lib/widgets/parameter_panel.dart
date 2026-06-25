import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/conversation_list_provider.dart';
import '../providers/providers.dart';
import '../core/theme/design_tokens.dart';

class ParameterPanel extends ConsumerStatefulWidget {
  const ParameterPanel({super.key});

  @override
  ConsumerState<ParameterPanel> createState() => _ParameterPanelState();
}

class _ParameterPanelState extends ConsumerState<ParameterPanel> {
  bool _expanded = false;
  Timer? _debounceTimer;

  void _debouncedUpdate({
    double? temperature,
    double? topP,
    int? topK,
    int? maxTokens,
    double? repeatPenalty,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
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
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xxs),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.chevron_right_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: Spacing.xxs),
                Text(
                  'T: ${temperature.toStringAsFixed(1)}  ·  M: $maxTokens',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xxs, Spacing.md, Spacing.sm),
            child: Column(
              children: [
                _ParamSlider(
                  label: 'Temperature',
                  value: temperature,
                  min: 0.0, max: 2.0,
                  displayValue: temperature.toStringAsFixed(2),
                  onChanged: (v) => _debouncedUpdate(temperature: v),
                  colorScheme: colorScheme,
                ),
                _ParamSlider(
                  label: 'Top-P',
                  value: topP,
                  min: 0.0, max: 1.0,
                  displayValue: topP.toStringAsFixed(2),
                  onChanged: (v) => _debouncedUpdate(topP: v),
                  colorScheme: colorScheme,
                ),
                _ParamSlider(
                  label: 'Top-K',
                  value: topK.toDouble(),
                  min: 0, max: 100,
                  displayValue: topK.toString(),
                  onChanged: (v) => _debouncedUpdate(topK: v.round()),
                  colorScheme: colorScheme,
                ),
                _ParamSlider(
                  label: 'Max Tokens',
                  value: maxTokens.toDouble(),
                  min: 256, max: 32768,
                  displayValue: maxTokens.toString(),
                  onChanged: (v) => _debouncedUpdate(maxTokens: v.round()),
                  colorScheme: colorScheme,
                ),
                _ParamSlider(
                  label: 'Repeat Penalty',
                  value: repeatPenalty,
                  min: 1.0, max: 2.0,
                  displayValue: repeatPenalty.toStringAsFixed(2),
                  onChanged: (v) => _debouncedUpdate(repeatPenalty: v),
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _ParamSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;
  final ColorScheme colorScheme;

  const _ParamSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.15),
                thumbColor: colorScheme.primary,
                overlayColor: colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: ((max - min) / 0.1).round().clamp(1, 1000),
                label: displayValue,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              displayValue,
              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}