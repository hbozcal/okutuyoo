import 'package:flutter/material.dart';
import 'package:qr_scanner/app/theme/app_tokens.dart';
import 'package:qr_scanner/core/l10n/app_strings.dart';
import 'package:qr_scanner/core/services/clipboard_service.dart';
import 'package:qr_scanner/core/services/launch_service.dart';
import 'package:qr_scanner/core/services/share_service.dart';
import 'package:qr_scanner/core/utils/date_formatters.dart';
import 'package:qr_scanner/core/utils/qr_content_parser.dart';
import 'package:qr_scanner/features/history/models/qr_content_type.dart';
import 'package:qr_scanner/shared/widgets/action_chip_button.dart';

class ResultSheet extends StatelessWidget {
  const ResultSheet({
    super.key,
    required this.raw,
    this.createdAt,
    this.onRescan,
  });

  final String raw;
  final DateTime? createdAt;
  final VoidCallback? onRescan;

  @override
  Widget build(BuildContext context) {
    final s = stringsOf(context);
    final parsed = QrContentParser.parse(raw, strings: s);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(_iconFor(parsed.type), color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.resultTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          parsed.title,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (createdAt != null)
                    Text(
                      DateFormatters.absolute(createdAt!),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    parsed.raw,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (parsed.metadata.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ...parsed.metadata.entries
                    .where((e) => e.key != 'password')
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                if (parsed.type == QrContentType.wifi &&
                    parsed.metadata['password'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SelectableText(
                      'password: ${parsed.metadata['password']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ActionChipButton(
                    icon: Icons.copy_rounded,
                    label: s.copy,
                    onTap: () =>
                        const ClipboardService().copyWithFeedback(context, raw),
                  ),
                  ActionChipButton(
                    icon: Icons.share_rounded,
                    label: s.share,
                    onTap: () => const ShareService().shareTextWithFeedback(
                      context,
                      raw,
                    ),
                  ),
                  ..._primaryActions(context, s, parsed),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onRescan?.call();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(s.rescan),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _primaryActions(
    BuildContext context,
    AppStrings s,
    ParsedQrContent parsed,
  ) {
    switch (parsed.type) {
      case QrContentType.url:
        return [
          ActionChipButton(
            icon: Icons.open_in_new_rounded,
            label: s.open,
            onTap: () => const LaunchService().openParsed(context, parsed),
          ),
        ];
      case QrContentType.phone:
        return [
          ActionChipButton(
            icon: Icons.call_rounded,
            label: s.call,
            onTap: () => const LaunchService().openParsed(
              context,
              parsed,
              confirmWeb: false,
            ),
          ),
        ];
      case QrContentType.email:
        return [
          ActionChipButton(
            icon: Icons.mail_outline_rounded,
            label: s.sendEmail,
            onTap: () => const LaunchService().openParsed(
              context,
              parsed,
              confirmWeb: false,
            ),
          ),
        ];
      case QrContentType.sms:
        return [
          ActionChipButton(
            icon: Icons.sms_outlined,
            label: s.sendSms,
            onTap: () => const LaunchService().openParsed(
              context,
              parsed,
              confirmWeb: false,
            ),
          ),
        ];
      case QrContentType.geo:
        return [
          ActionChipButton(
            icon: Icons.map_outlined,
            label: s.open,
            onTap: () => const LaunchService().openParsed(
              context,
              parsed,
              confirmWeb: false,
            ),
          ),
        ];
      case QrContentType.wifi:
      case QrContentType.contact:
      case QrContentType.text:
      case QrContentType.unknown:
        return const [];
    }
  }

  IconData _iconFor(QrContentType type) => switch (type) {
    QrContentType.url => Icons.link_rounded,
    QrContentType.email => Icons.mail_outline,
    QrContentType.phone => Icons.phone_outlined,
    QrContentType.sms => Icons.sms_outlined,
    QrContentType.wifi => Icons.wifi_rounded,
    QrContentType.geo => Icons.place_outlined,
    QrContentType.contact => Icons.contact_page_outlined,
    QrContentType.text || QrContentType.unknown => Icons.text_snippet_outlined,
  };
}
