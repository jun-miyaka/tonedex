import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.help)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.whatIsToneDex,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(AppLocalizations.of(context)!.whatIsToneDexDescription),

              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.howToUse,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(AppLocalizations.of(context)!.howToUseDescription),

              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.analysisParameters,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(AppLocalizations.of(context)!.analysisParametersDescription),

              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.aboutZScore,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(AppLocalizations.of(context)!.aboutZScoreDescription),

              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.notes,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(AppLocalizations.of(context)!.notesDescription),

              const SizedBox(height: 16),
              const Text(
                'Official Website',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => _launchURL('https://tonedex.base.shop/'),
                child: const Text(
                  'https://tonedex.base.shop/',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'User Community (Facebook)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => _launchURL(
                  'https://www.facebook.com/groups/1239933731263240',
                ),
                child: const Text(
                  'https://www.facebook.com/groups/1239933731263240',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // --- Support the Developer (Buy Me a Coffee) ---
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.support,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(AppLocalizations.of(context)!.supportDescription),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.favorite),
                          label: Text(
                            AppLocalizations.of(context)!.buyMeACoffee,
                          ),
                          onPressed: () {
                            _launchURL('https://www.buymeacoffee.com/junm');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
