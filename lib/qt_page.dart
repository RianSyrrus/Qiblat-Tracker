import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

class QtPage extends StatefulWidget {
  const QtPage({super.key});

  @override
  State<QtPage> createState() => _QtPageState();
}

class _QtPageState extends State<QtPage> {
  late final WebViewController _controller;

  bool _gpsInjectedThisLoad = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final u = request.url;
            if (u.startsWith('http://') || u.startsWith('https://')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            _gpsInjectedThisLoad = false;
          },
          onPageFinished: (url) async {
            try {
              await _autoScaleToScreen();
              Future.delayed(const Duration(milliseconds: 150), () {
                _autoScaleToScreen();
              });
              Future.delayed(const Duration(milliseconds: 500), () {
                _autoScaleToScreen();
              });

              if (_gpsInjectedThisLoad) return;
              _gpsInjectedThisLoad = true;

              await _injectLocationToWeb();
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/qt/launch.html');
  }

  Future<Position> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service belum aktif.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Izin lokasi ditolak.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Aktifkan dari Settings.');
    }

    final lastPos = await Geolocator.getLastKnownPosition();
    if (lastPos != null) {
      return lastPos;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );
    } catch (_) {
      throw Exception(
        'GPS belum mendapatkan sinyal.\n'
        'Coba ke luar ruangan dan tunggu beberapa saat.',
      );
    }
  }

  Future<void> _injectLocationToWeb() async {
    final pos = await _getPosition();
    final lat = pos.latitude;
    final lon = pos.longitude;

    final nsIndex = (lat >= 0) ? 0 : 1; // 0=LU, 1=LS
    final ewIndex = (lon >= 0) ? 0 : 1; // 0=BT, 1=BB

    final js =
        '''
      (function() {
        document.InputFormCD.lat2.value = "${lat.abs().toStringAsFixed(6)}";
        document.InputFormCD.lon2.value = "${lon.abs().toStringAsFixed(6)}";
        document.InputFormCD.NS2.selectedIndex = $nsIndex;
        document.InputFormCD.EW2.selectedIndex = $ewIndex;
        try { clearInterval(myTimer); } catch(e) {}
      })();
    ''';

    await _controller.runJavaScript(js);
  }

  Future<void> _autoScaleToScreen() async {
    const js = r'''
    (function() {
      function lockNoScroll() {
        var body = document.body;
        var html = document.documentElement;
        if (!body || !html) return;
        html.style.overflow = 'hidden';
        body.style.overflow = 'hidden';
        body.style.overscrollBehavior = 'none';
        document.addEventListener('touchmove', function(e){ e.preventDefault(); }, {passive:false});
      }

      function applyScale() {
        var body = document.body;
        var html = document.documentElement;
        if (!body || !html) return;

        var contentWidth = Math.max(
          html.scrollWidth, body.scrollWidth,
          html.offsetWidth, body.offsetWidth
        );

        var viewportWidth = window.innerWidth || html.clientWidth || 360;
        var scale = viewportWidth / contentWidth;
        if (scale > 1) scale = 1;
        if (scale < 0.1) scale = 0.1;

        body.style.transformOrigin = '0 0';
        body.style.transform = 'scale(' + scale.toFixed(4) + ')';
        body.style.width = contentWidth + 'px';
        body.style.height = '';
      }

      lockNoScroll();
      applyScale();
      setTimeout(applyScale, 50);
      setTimeout(applyScale, 200);

      var lastW = window.innerWidth || document.documentElement.clientWidth;

      window.addEventListener('resize', function() {
        var w = window.innerWidth || document.documentElement.clientWidth;
        if (Math.abs(w - lastW) >= 2) {
          lastW = w;
          applyScale();
          setTimeout(applyScale, 100);
        }
      });

      window.addEventListener('orientationchange', function() {
        setTimeout(function() {
          lastW = window.innerWidth || document.documentElement.clientWidth;
          applyScale();
          setTimeout(applyScale, 100);
        }, 100);
      });
    })();
  ''';

    await _controller.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SafeArea(child: WebViewWidget(controller: _controller)),

          Positioned(
            right: 16,
            bottom: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'gps',
                  onPressed: () async {
                    try {
                      await _injectLocationToWeb();
                      await _autoScaleToScreen();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),

                const SizedBox(width: 8),

                FloatingActionButton.small(
                  heroTag: 'reload',
                  onPressed: () async {
                    await _controller.reload();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      () => _autoScaleToScreen(),
                    );
                  },
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
