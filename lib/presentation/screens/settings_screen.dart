import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final saveRepo = ref.read(saveRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('せってい')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionTitle('がめん'),
            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('ライトモード'),
                    value: ThemeMode.light,
                    groupValue: settings.themeMode,
                    onChanged: (v) => ctrl.setThemeMode(v!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('ダークモード'),
                    value: ThemeMode.dark,
                    groupValue: settings.themeMode,
                    onChanged: (v) => ctrl.setThemeMode(v!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('システムに あわせる'),
                    value: ThemeMode.system,
                    groupValue: settings.themeMode,
                    onChanged: (v) => ctrl.setThemeMode(v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const _SectionTitle('メッセージ そくど'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('おそい'),
                    Expanded(
                      child: Slider(
                        value: settings.textSpeed.toDouble(),
                        min: 1,
                        max: 3,
                        divisions: 2,
                        label: ['おそい', 'ふつう', 'はやい'][settings.textSpeed - 1],
                        onChanged: (v) => ctrl.setTextSpeed(v.round()),
                      ),
                    ),
                    const Text('はやい'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('バトル えんしゅつ'),
                value: settings.battleAnimations,
                onChanged: ctrl.setBattleAnimations,
              ),
            ),
            const SizedBox(height: 16),
            const _SectionTitle('データかんり / バックアップ'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('バックアップを かきだす'),
                    subtitle: const Text('セーブデータを テキストとして コピーできます'),
                    onTap: () => _exportBackup(context, saveRepo.exportJson()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('バックアップを よみこむ'),
                    subtitle: const Text('テキストから セーブデータを ふくげんします'),
                    onTap: () => _importBackup(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('セーブデータを さくじょ', style: TextStyle(color: Colors.red)),
                    onTap: () => _deleteSave(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportBackup(BuildContext context, String json) {
    if (json.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('セーブデータが ありません')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('バックアップ データ'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(json, style: const TextStyle(fontSize: 11))),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('クリップボードに コピーしました')));
            },
            child: const Text('コピー'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('とじる')),
        ],
      ),
    );
  }

  void _importBackup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('バックアップを よみこむ'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'バックアップ テキストを はりつけ', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('やめる')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('よみこむ')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(saveRepositoryProvider).importJson(controller.text.trim());
      ref.read(gameControllerProvider.notifier).continueGame();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('よみこみが かんりょうしました！')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('データが ただしくありません')));
      }
    }
  }

  void _deleteSave(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('かくにん'),
        content: const Text('セーブデータを かんぜんに さくじょしますか？ もとには もどせません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('やめる')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('さくじょ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(saveRepositoryProvider).delete();
    ref.read(gameControllerProvider.notifier).quitToTitle();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('セーブデータを さくじょしました')));
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
    );
  }
}
