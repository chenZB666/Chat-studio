import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/design_tokens.dart';
import '../database/database.dart';
import '../providers/conversation_list_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/providers.dart';
import '../widgets/conversation_list.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/title_bar.dart';
import 'chat_screen.dart';
import 'server_settings_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _initWindowListener();
    }
  }

  void _initWindowListener() {
    windowManager.isMaximized().then((v) {
      if (mounted) setState(() => _isMaximized = v);
    });
    final listener = _WindowListener(this);
    windowManager.addListener(listener);
  }

  void _onWindowMaximize() => setState(() => _isMaximized = true);
  void _onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  Widget build(BuildContext context) {
    final convState = ref.watch(conversationListProvider);
    final isWide = MediaQuery.of(context).size.width >= AppConstants.layoutBreakpoint;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      appBar: TitleBar(
        isMaximized: _isMaximized,
        leading: !isWide
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, size: LayoutTokens.iconSize),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                tooltip: 'Menu',
              )
            : null,
        actions: [
          if (!isWide)
            IconButton(
              icon: const Icon(Icons.search_rounded, size: LayoutTokens.iconSize),
              onPressed: () => _showSearch(context, ref),
              tooltip: 'Search',
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: LayoutTokens.iconSize),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
            ),
            tooltip: 'Servers',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: LayoutTokens.iconSize),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(
        child: SafeArea(
          child: ConversationList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      // Sidebar
                      SizedBox(
                        width: LayoutTokens.sidebarWidth,
                        child: Column(
                          children: [
                            Expanded(child: ConversationList()),
                          ],
                        ),
                      ),
                      // Vertical divider
                      VerticalDivider(width: 1, thickness: LayoutTokens.dividerThickness, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      // Main content
                      Expanded(
                        child: convState.activeConversationId != null
                            ? const ChatScreen()
                            : _buildEmptyState(colorScheme),
                      ),
                    ],
                  )
                : (convState.activeConversationId != null
                    ? const ChatScreen()
                    : _buildEmptyState(colorScheme)),
          ),
          const ConnectionStatusBar(),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showSearch(context: context, delegate: _ConversationSearchDelegate(ref));
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
              ),
              child: Icon(Icons.chat_bubble_outline_rounded, size: 36, color: colorScheme.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Start a conversation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Select an existing chat or create a new one',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton.icon(
              onPressed: () async {
                final id = await ref.read(conversationListProvider.notifier).createConversation();
                ref.read(chatProvider.notifier).loadConversation(id);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Conversation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationSearchDelegate extends SearchDelegate<Conversation?> {
  final WidgetRef ref;

  _ConversationSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.close_rounded),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
            const SizedBox(height: Spacing.md),
            Text('Type to search', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
          ],
        ),
      );
    }
    return FutureBuilder<List<Conversation>>(
      future: ref.read(storageServiceProvider).searchConversations(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
                const SizedBox(height: Spacing.md),
                Text('No conversations found', style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xxs),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final conv = snapshot.data![index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusTokens.sm)),
                title: Text(conv.title, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  DateTime.fromMillisecondsSinceEpoch(conv.updatedAt).toString().substring(0, 16),
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  ref.read(conversationListProvider.notifier).selectConversation(conv.id);
                  ref.read(chatProvider.notifier).loadConversation(conv.id);
                  close(context, conv);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _WindowListener extends WindowListener {
  final _HomeScreenState _state;
  _WindowListener(this._state);

  @override
  void onWindowMaximize() => _state._onWindowMaximize();
  @override
  void onWindowUnmaximize() => _state._onWindowUnmaximize();
}