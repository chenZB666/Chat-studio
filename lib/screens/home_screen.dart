import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../core/constants/app_constants.dart';
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
                icon: const Icon(Icons.menu, size: 18),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                tooltip: 'Menu',
              )
            : null,
        actions: [
          if (!isWide)
            IconButton(
              icon: const Icon(Icons.search, size: 18),
              onPressed: () => _showSearch(context, ref),
              tooltip: 'Search',
            ),
          IconButton(
            icon: const Icon(Icons.settings, size: 18),
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
                      SizedBox(
                        width: 280,
                        child: Material(
                          color: colorScheme.surfaceContainerLow,
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.dns),
                                title: const Text('Servers'),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(child: ConversationList()),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, color: colorScheme.outlineVariant),
                      Expanded(child: convState.activeConversationId != null
                          ? const ChatScreen()
                          : _buildEmptyState(colorScheme)),
                    ],
                  )
                : (convState.activeConversationId != null
                    ? const ChatScreen()
                    : _buildEmptyState(colorScheme)),
          ),
          const ConnectionStatusBar(),
        ],
      ),
      floatingActionButton: !isWide && convState.activeConversationId == null
          ? FloatingActionButton(
              onPressed: () async {
                final id = await ref.read(conversationListProvider.notifier).createConversation();
                ref.read(chatProvider.notifier).loadConversation(id);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showSearch(context: context, delegate: _ConversationSearchDelegate(ref));
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Select or create a conversation',
            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              final id = await ref.read(conversationListProvider.notifier).createConversation();
              ref.read(chatProvider.notifier).loadConversation(id);
            },
            icon: const Icon(Icons.add),
            label: const Text('New Conversation'),
          ),
        ],
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
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text('Type to search conversations',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    return FutureBuilder<List<Conversation>>(
      future: ref.read(storageServiceProvider).searchConversations(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No conversations found'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final conv = snapshot.data![index];
            return ListTile(
              title: Text(conv.title),
              subtitle: Text(DateTime.fromMillisecondsSinceEpoch(conv.updatedAt).toString()),
              onTap: () {
                ref.read(conversationListProvider.notifier).selectConversation(conv.id);
                ref.read(chatProvider.notifier).loadConversation(conv.id);
                close(context, conv);
              },
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
