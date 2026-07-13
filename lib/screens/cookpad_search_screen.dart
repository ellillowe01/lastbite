// lib/screens/cookpad_search_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/common_widgets.dart';

// Cari resep di Cookpad dari dalam app. WebView cuma dipakai untuk Android/iOS
// (satu-satunya platform yang didukung webview_flutter); platform lain fallback
// buka Cookpad di browser luar.
class CookpadSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const CookpadSearchScreen({super.key, this.initialQuery});

  @override
  State<CookpadSearchScreen> createState() => _CookpadSearchScreenState();
}

class _CookpadSearchScreenState extends State<CookpadSearchScreen> {
  late final TextEditingController _searchController;
  WebViewController? _webViewController;
  double _progress = 0;

  bool get _supportsWebView => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');

    if (_supportsWebView) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p / 100),
          onPageFinished: (_) => setState(() => _progress = 1),
        ));
      _load(widget.initialQuery ?? '');
    } else if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openExternal(widget.initialQuery!));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Uri _searchUri(String query) {
    final q = query.trim();
    return q.isEmpty
        ? Uri.parse('https://cookpad.com/id')
        : Uri.parse('https://cookpad.com/id/cari/${Uri.encodeComponent(q)}');
  }

  void _load(String query) => _webViewController?.loadRequest(_searchUri(query));

  Future<void> _openExternal(String query) =>
      launchUrl(_searchUri(query), mode: LaunchMode.externalApplication);

  void _submit(String query) => _supportsWebView ? _load(query) : _openExternal(query);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.arrow_back_rounded, color: kWhite),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder, width: 0.8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.search_rounded, size: 18, color: kTextMuted),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      controller: _searchController,
                      autofocus: widget.initialQuery == null,
                      style: const TextStyle(fontSize: 13, color: kWhite),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Cari resep di Cookpad...',
                        hintStyle: TextStyle(color: kTextMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: _submit,
                    )),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _submit(_searchController.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: kGreenGradient, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF13151A)),
                ),
              ),
            ]),
          ),
          if (_supportsWebView && _progress < 1)
            LinearProgressIndicator(value: _progress, minHeight: 2, backgroundColor: kBgSurface, color: kNeonGreen),
          Expanded(
            child: _supportsWebView
                ? WebViewWidget(controller: _webViewController!)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('🍳', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text('Preview Cookpad belum didukung di platform ini.',
                            style: TextStyle(color: kTextMuted), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        const Text('Ketik kata kunci lalu tekan tombol panah untuk membukanya di browser.',
                            style: TextStyle(color: kTextMuted, fontSize: 12), textAlign: TextAlign.center),
                      ]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}
