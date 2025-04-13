import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/scan_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter String Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter String Scanner'),
        actions: [
          if (state.results != null)
            IconButton(
              icon: const Icon(Icons.save),  // 将 Icons.export 改为 Icons.save
              onPressed: () => _exportResults(state.results!),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildControls(ref),
          Expanded(child: _buildResults(state)),
        ],
      ),
    );
  }

  Widget _buildControls(WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ref.watch(scanProvider.select((s) => s.projectPath ?? 'No project selected')),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: ref.read(scanProvider.notifier).selectProject,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: ref.read(scanProvider.notifier).scanProject,
              child: const Text('Scan Project'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ScanState state) {
    if (state.isScanning) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    if (state.results == null || state.results!.isEmpty) {
      return const Center(child: Text('No results yet. Select a project and scan.'));
    }

    return ListView.builder(
      itemCount: state.results!.length,
      itemBuilder: (context, index) {
        final entry = state.results!.entries.elementAt(index);
        return ExpansionTile(
          title: Text(entry.key.split('/').last),
          subtitle: Text('${entry.value.length} strings found'),
          children: entry.value.map((str) => ListTile(
            title: Text(str),
          )).toList(),
        );
      },
    );
  }

  Future<void> _exportResults(Map<String, List<String>> results) async {
    // 实现导出功能
  }
}