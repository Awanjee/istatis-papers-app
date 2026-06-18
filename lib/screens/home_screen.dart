import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
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
  final _scrollController = ScrollController();

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
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentIndex == 0
                  ? 'iStatis Assistant'
                  : _currentIndex == 1
                  ? 'Product Catalogue'
                  : _currentIndex == 2
                  ? 'Request a Quote'
                  : _currentIndex == 3
                  ? 'Import Document'
                  : 'Ledger',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.text1,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _currentIndex == 0
                  ? 'Ask about products, pricing & orders'
                  : _currentIndex == 1
                  ? 'Envelopes, Paper & File Carriers'
                  : _currentIndex == 2
                  ? 'Get a personalised quote by email'
                  : _currentIndex == 3
                  ? 'Receipts, khata pages & invoices'
                  : 'Confirmed transactions',
              style: GoogleFonts.plusJakartaSans(color: AppColors.text2, fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.text1),
              onPressed: () => context.read<ChatProvider>().clearMessages(),
              tooltip: 'Clear chat',
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.text1),
            onPressed: () => context.read<AuthProvider>().signOut(),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.text3,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_quote_outlined),
            activeIcon: Icon(Icons.request_quote),
            label: 'Quote',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            activeIcon: Icon(Icons.document_scanner),
            label: 'Import',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Ledger',
          ),
        ],
      ),
    );
  }
}

// Extracted chat tab as a private widget
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) =>
                          ChatBubble(message: provider.messages[index]),
                    ),
            ),
            if (provider.messages.isEmpty)
              SuggestionChips(
                onSuggestionTap: (text) => provider.sendMessage(text),
              ),
            const SizedBox(height: 8),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.accent,
            ),
            const SizedBox(height: 16),
            Text(
              'iStatis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me about envelopes, paper, file '
              'carriers, bulk pricing, or place an order.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.text3,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
