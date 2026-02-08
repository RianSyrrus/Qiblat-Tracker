import 'package:flutter/material.dart';
import 'package:qiblat/pdf_guide_page.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onToggleCompass;
  final bool isCompassVisible;

  const AppDrawer({
    super.key,
    required this.onReset,
    required this.onToggleCompass,
    required this.isCompassVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade900, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.explore, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'QIBLAT TRACKER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'RHI Mobile',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu Items
            _buildMenuItem(
              context,
              icon: Icons.menu_book,
              title: 'Panduan Penggunaan',
              subtitle: 'Cara menggunakan aplikasi',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PdfGuidePage()),
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.refresh,
              title: 'Reset & Muat Ulang',
              subtitle: 'Reset data dan GPS',
              onTap: () {
                Navigator.pop(context);
                _showResetDialog(context);
              },
            ),

            _buildMenuItem(
              context,
              icon: isCompassVisible ? Icons.visibility_off : Icons.explore,
              title: 'Kompas Magnetik',
              subtitle: isCompassVisible
                  ? 'Sembunyikan kompas'
                  : 'Tampilkan kompas',
              onTap: () {
                Navigator.pop(context);
                onToggleCompass();
              },
            ),

            const Spacer(),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  Text(
                    'Versi 1.1.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '© 2025 RHI',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.red.shade300, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('Reset Aplikasi', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'Reset akan:\n'
            '• Muat ulang halaman kompas\n'
            '• Ambil ulang data GPS\n'
            '• Reset skala tampilan\n\n'
            'Lanjutkan?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onReset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
