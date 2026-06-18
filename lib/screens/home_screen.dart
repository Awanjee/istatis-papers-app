import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../theme/arco_components.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/suggestion_chips.dart';
import 'catalogue_screen.dart';
import 'import_document_screen.dart';
import 'quote_screen.dart';
import 'transaction_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _tabLabels = [
    'Assistant',
    'Catalogue',
    'Quote',
    'Import',
    'Ledger',
  ];

  static const _titles = [
    'iStatis Assistant',
    'Product Catalogue',
    'Request a Quote',
    'Import Document',
    'Ledger',
  ];

  static const _subtitles = [
    'Ask about products, pricing & orders',
    'Envelopes, paper & file carriers',
    'Get a personalised quote by email',
    'Receipts, khata pages & invoices',
    'Confirmed transactions',
  ];

  List<Widget> get _screens => const [
    _ChatTab(),
    CatalogueScreen(),
    QuoteScreen(),
    ImportDocumentScreen(),
    TransactionHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: ArcoTopBar(
        title: _titles[_currentIndex],
        subtitle: _subtitles[_currentIndex],
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: AppColors.text2),
              onPressed: () => context.read<ChatProvider>().clearMessages(),
              tooltip: 'Clear chat',
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.text2),
            onPressed: () => context.read<AuthProvider>().signOut(),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: Column(
        children: [
          ArcoSegTabs(
            labels: _tabLabels,
            selectedIndex: _currentIndex,
            onSelected: (i) => setState(() => _currentIndex = i),
          ),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
    );
  }
}

class _ChatTab extends StatefulWidget {
  const _ChatTab();

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        _scrollToBottom();
        return Column(
          children: [
            Expanded(
              child: provider.messages.isEmpty
                  ? _buildWelcome()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s3,
                        horizontal: AppSpacing.s2,
                      ),
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) =>
                          ChatBubble(message: provider.messages[index]),
                    ),
            ),
            if (provider.messages.isEmpty) ...[
              SuggestionChips(
                onSuggestionTap: (text) => provider.sendMessage(text),
              ),
              const SizedBox(height: AppSpacing.s4),
            ],
            ChatInput(
              isLoading: provider.isLoading,
              onSend: (text) => provider.sendMessage(text),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: AppRadius.rMd,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 28,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text.rich(
              TextSpan(
                text: 'i',
                style: AppText.h2,
                children: [
                  TextSpan(
                    text: 'Statis',
                    style: AppText.h2.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Ask about envelopes, paper, file carriers, bulk pricing, or place an order.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.text2),
            ),
          ],
        ),
      ),
    );
  }
}
