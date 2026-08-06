import 'package:flutter/material.dart';

class PhotoEditorScreen extends StatefulWidget {
  final String imageUrl;
  final String initialCaption;
  final void Function(String editedUrl, String caption) onSave;

  const PhotoEditorScreen({
    super.key,
    required this.imageUrl,
    this.initialCaption = '',
    required this.onSave,
  });

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  Color _selectedColor = Colors.black;
  double _brushSize = 3;
  final List<_Stroke> _strokes = [];
  final List<_Stroke> _redoStack = [];

  static const _colors = [
    Colors.black,
    Colors.white,
    Color(0xFFFF6B00),
    Color(0xFFEC4899),
    Color(0xFF166534),
    Color(0xFF2563EB),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
  ];

  static const _sizes = [3.0, 6.0, 10.0];

  void _startStroke(Offset pt) {
    setState(() {
      _strokes.add(_Stroke(color: _selectedColor, width: _brushSize, points: [pt]));
      _redoStack.clear();
    });
  }

  void _extendStroke(Offset pt) {
    setState(() {
      _strokes.last.points.add(pt);
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.add(_strokes.removeLast());
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _strokes.add(_redoStack.removeLast());
    });
  }

  void _clearMarkup() {
    setState(() {
      _strokes.clear();
      _redoStack.clear();
    });
  }

  void _reset() {
    setState(() {
      _strokes.clear();
      _redoStack.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _canvas()),
                  SizedBox(width: 200, child: _rightPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Text('Evidence',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          _tbBtn(Icons.undo, 'Undo', _undo, enabled: _strokes.isNotEmpty),
          _tbBtn(Icons.redo, 'Redo', _redo, enabled: _redoStack.isNotEmpty),
          _tbBtn(Icons.cleaning_services_outlined, 'Clear markup', _clearMarkup),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.crop, size: 16),
            label: const Text('Crop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF111111),
              minimumSize: const Size(100, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tbBtn(IconData icon, String label, VoidCallback onTap,
      {bool enabled = true}) {
    return TextButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon,
          size: 16, color: enabled ? Colors.white : Colors.white38),
      label: Text(label,
          style: TextStyle(
              color: enabled ? Colors.white : Colors.white38, fontSize: 13)),
    );
  }

  Widget _canvas() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanStart: (d) => _startStroke(d.localPosition),
            onPanUpdate: (d) => _extendStroke(d.localPosition),
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Stack(
                children: [
                  // Placeholder image
                  Center(
                    child: Container(
                      color: const Color(0xFF2A2A2A),
                      width: constraints.maxWidth * 0.8,
                      height: constraints.maxHeight * 0.8,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 60, color: Color(0xFF6B7280)),
                          SizedBox(height: 12),
                          Text('Photo Preview',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                  ),
                  // Strokes overlay
                  CustomPaint(
                    painter: _MarkupPainter(_strokes),
                    size: Size.infinite,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rightPanel() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rotate and flip',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              _iconBtn(Icons.rotate_left),
              const SizedBox(width: 6),
              _iconBtn(Icons.rotate_right),
              const SizedBox(width: 6),
              _iconBtn(Icons.flip),
              const SizedBox(width: 6),
              _iconBtn(Icons.swap_vert),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Markup image',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          const Text('Select color',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors
                .map((c) => GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _selectedColor == c
                          ? Colors.white
                          : const Color(0xFF444444),
                      width: _selectedColor == c ? 3 : 1),
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text('Select size',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 10),
          ..._sizes.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _brushSize = s),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _brushSize == s
                          ? Colors.white
                          : const Color(0xFF444444),
                      width: _brushSize == s ? 2 : 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Container(
                  height: s,
                  width: 120,
                  color: Colors.white,
                ),
              ),
            ),
          )),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Color(0xFF444444)),
                minimumSize: const Size(0, 40),
              ),
              child: const Text('Reset all'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF444444)),
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(widget.imageUrl, widget.initialCaption);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF444444)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> points;
  _Stroke({required this.color, required this.width, required this.points});
}

class _MarkupPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _MarkupPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MarkupPainter oldDelegate) => true;
}