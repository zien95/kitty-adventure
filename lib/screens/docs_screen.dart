import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

class DocsScreen extends StatelessWidget {
  const DocsScreen({super.key});

  Future<String> _loadReadme() {
    return rootBundle.loadString('README.md');
  }

  Future<void> _openLink(String? href) async {
    if (href == null || href.isEmpty) return;

    final uri = Uri.tryParse(href);
    if (uri == null || !uri.hasScheme) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF241A33),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('🐱 Game Docs'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF7BA7), Color(0xFF8D6BFF)],
            ),
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: _loadReadme(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Could not load README.md:\n${snapshot.error}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data?.trim();
          if (docs == null || docs.isEmpty) {
            return const Center(
              child: Text(
                'README.md is empty.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF302344), Color(0xFF20182D)],
              ),
            ),
            child: Markdown(
              data: docs,
              selectable: true,
              padding: const EdgeInsets.all(20),
              softLineBreak: true,
              onTapLink: (text, href, title) => _openLink(href),
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  color: Color(0xFFFFF7F9),
                  fontSize: 16,
                  height: 1.45,
                ),
                h1: const TextStyle(
                  color: Color(0xFFFFF2A8),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
                h2: const TextStyle(
                  color: Color(0xFFFF9CC4),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
                h3: const TextStyle(
                  color: Color(0xFF9EEBEE),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
                strong: const TextStyle(
                  color: Color(0xFFFFF2A8),
                  fontWeight: FontWeight.bold,
                ),
                em: const TextStyle(
                  color: Color(0xFFFFD1E1),
                  fontStyle: FontStyle.italic,
                ),
                a: const TextStyle(
                  color: Color(0xFF8FE8FF),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF8FE8FF),
                ),
                code: const TextStyle(
                  color: Color(0xFFFFD166),
                  backgroundColor: Color(0xFF1E1E29),
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                codeblockPadding: const EdgeInsets.all(12),
                codeblockDecoration: BoxDecoration(
                  color: const Color(0xFF1E1E29),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4A4A5E)),
                ),
                blockquote: const TextStyle(
                  color: Color(0xFFFFF7F9),
                  fontSize: 16,
                  height: 1.45,
                ),
                blockquotePadding: const EdgeInsets.all(12),
                blockquoteDecoration: BoxDecoration(
                  color: const Color(0xFF3A3A4A),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFFFD166), width: 4),
                  ),
                ),
                listBullet: const TextStyle(
                  color: Color(0xFFFFF2A8),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
                horizontalRuleDecoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFFF9CC4)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
