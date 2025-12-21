import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Simple rich text editor with basic formatting options
/// Stores content as simple HTML-like markup
class RichTextEditor extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? placeholder;

  const RichTextEditor({
    super.key,
    this.initialValue = '',
    required this.onChanged,
    this.placeholder,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late final TextEditingController _controller;
  bool _isBold = false;
  bool _isItalic = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Parse HTML back to plain text for editing
    _controller = TextEditingController(text: _parseHtmlToPlainText(widget.initialValue));
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Convert to simple HTML
    final html = _plainTextToHtml(_controller.text);
    widget.onChanged(html);
  }

  String _parseHtmlToPlainText(String html) {
    // Simple HTML to plain text conversion
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');
  }

  String _plainTextToHtml(String text) {
    // Simple plain text to HTML conversion
    // In a real app, you'd track formatting ranges
    String html = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll('\n', '<br>');
    
    return html;
  }

  void _toggleBold() {
    setState(() {
      _isBold = !_isBold;
    });
    // In a real implementation, you would apply bold to selected text
    _focusNode.requestFocus();
  }

  void _toggleItalic() {
    setState(() {
      _isItalic = !_isItalic;
    });
    // In a real implementation, you would apply italic to selected text
    _focusNode.requestFocus();
  }

  void _insertLink() {
    showDialog(
      context: context,
      builder: (context) => _LinkDialog(
        onInsert: (text, url) {
          final link = '[$text]($url)';
          final selection = _controller.selection;
          final newText = _controller.text.replaceRange(
            selection.start,
            selection.end,
            link,
          );
          _controller.text = newText;
          _controller.selection = TextSelection.collapsed(
            offset: selection.start + link.length,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusMedium),
            ),
          ),
          child: Row(
            children: [
              _ToolbarButton(
                icon: Icons.format_bold,
                isActive: _isBold,
                onTap: _toggleBold,
                tooltip: 'Fed',
              ),
              _ToolbarButton(
                icon: Icons.format_italic,
                isActive: _isItalic,
                onTap: _toggleItalic,
                tooltip: 'Kursiv',
              ),
              _ToolbarButton(
                icon: Icons.link,
                isActive: false,
                onTap: _insertLink,
                tooltip: 'Indsæt link',
              ),
            ],
          ),
        ),
        
        // Text field
        Container(
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppSpacing.radiusMedium),
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(color: AppColors.gray),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
            style: TextStyle(
              fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _ToolbarButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryPurple.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.primaryPurple : AppColors.gray,
          ),
        ),
      ),
    );
  }
}

class _LinkDialog extends StatefulWidget {
  final void Function(String text, String url) onInsert;

  const _LinkDialog({required this.onInsert});

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final _textController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Indsæt link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Tekst',
              hintText: 'Linkets tekst',
            ),
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://...',
            ),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuller'),
        ),
        TextButton(
          onPressed: () {
            final text = _textController.text.trim();
            final url = _urlController.text.trim();
            if (text.isNotEmpty && url.isNotEmpty) {
              widget.onInsert(text, url);
              Navigator.pop(context);
            }
          },
          child: const Text('Indsæt'),
        ),
      ],
    );
  }
}
