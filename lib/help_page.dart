import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.help)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.whatIsToneDex,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(AppLocalizations.of(context)!.whatIsToneDexDescription),

              SizedBox(height: 16),
              Text('How to use', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(AppLocalizations.of(context)!.howToUseDescription),

              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.analysisParameters,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(AppLocalizations.of(context)!.analysisParametersDescription),

              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.aboutZScore,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(AppLocalizations.of(context)!.aboutZScoreDescription),

              SizedBox(height: 16),
              Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
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
            ],
          ),
        ),
      ),
    );
  }
}
