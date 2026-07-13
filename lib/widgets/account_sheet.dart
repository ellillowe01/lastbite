// lib/widgets/account_sheet.dart
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../services/auth_service.dart';
import 'common_widgets.dart';

void showAccountSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kBgCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _AccountSheetContent(),
  );
}

class _AccountSheetContent extends StatefulWidget {
  const _AccountSheetContent();
  @override
  State<_AccountSheetContent> createState() => _AccountSheetContentState();
}

class _AccountSheetContentState extends State<_AccountSheetContent> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signInWithGoogle();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal login: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signOut();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal keluar: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),

        if (user != null) ...[
          Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: kBgSurface,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null ? const Icon(Icons.person_rounded, color: kNeonGreen, size: 28) : null,
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.displayName ?? 'Akun Google',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kWhite)),
              Text(user.email ?? '', style: const TextStyle(fontSize: 12, color: kTextMuted)),
            ])),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kNeonGreen.withOpacity(0.25)),
            ),
            child: const Row(children: [
              Icon(Icons.cloud_done_rounded, size: 16, color: kNeonGreen),
              SizedBox(width: 8),
              Expanded(child: Text('Data kulkas & resep kamu tersinkron ke cloud',
                  style: TextStyle(fontSize: 12, color: kNeonGreen))),
            ]),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: kDanger, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: GestureDetector(
            onTap: _loading ? null : _signOut,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: kDanger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDanger.withOpacity(0.4)),
              ),
              alignment: Alignment.center,
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kDanger))
                  : const Text('Keluar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDanger)),
            ),
          )),
        ] else ...[
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: kBgSurface,
                border: Border.all(color: kNeonGreen.withOpacity(0.3)),
              ),
              child: const Icon(Icons.person_outline_rounded, color: kNeonGreen, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Kamu belum login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kWhite)),
              Text('Data kulkas & resep hanya tersimpan di perangkat ini',
                  style: TextStyle(fontSize: 11, color: kTextMuted)),
            ])),
          ]),
          const SizedBox(height: 20),

          if (!DefaultFirebaseOptions.isConfigured)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kWarning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kWarning.withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: kWarning),
                SizedBox(width: 8),
                Expanded(child: Text('Login cloud belum dikonfigurasi developer. Coba lagi nanti.',
                    style: TextStyle(fontSize: 11, color: kWarning))),
              ]),
            ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 12)),
            ),

          SizedBox(width: double.infinity, child: GestureDetector(
            onTap: _loading ? null : _signIn,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(gradient: kGreenGradient, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF13151A)))
                  : const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.login_rounded, size: 16, color: Color(0xFF13151A)),
                      SizedBox(width: 8),
                      Text('Masuk dengan Google',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF13151A))),
                    ]),
            ),
          )),
        ],
        const SizedBox(height: 8),
      ]),
    );
  }
}
