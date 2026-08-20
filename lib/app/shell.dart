import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_scanner/features/generator/presentation/generator_page.dart';
import 'package:qr_scanner/features/history/data/history_controller.dart';
import 'package:qr_scanner/features/history/presentation/history_page.dart';
import 'package:qr_scanner/features/scanner/presentation/scanner_page.dart';
import 'package:qr_scanner/shared/widgets/action_chip_button.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  final _scannerActive = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryController>().load();
    });
  }

  @override
  void dispose() {
    _scannerActive.dispose();
    super.dispose();
  }

  void _onTab(int index) {
    setState(() => _tab = index);
    _scannerActive.value = index == 0;
  }

  @override
  Widget build(BuildContext context) {
    final s = stringsOf(context);

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          ScannerPage(isActive: _scannerActive),
          const GeneratorPage(),
          const HistoryPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _onTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: const Icon(Icons.qr_code_scanner),
            label: s.tabScan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_2_outlined),
            selectedIcon: const Icon(Icons.qr_code_2),
            label: s.tabCreate,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: s.tabHistory,
          ),
        ],
      ),
    );
  }
}
