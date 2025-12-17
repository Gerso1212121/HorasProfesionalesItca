// lib/Frontend/Modules/Diary/Widgets/ToolbarWidget.dart
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';

class ToolbarWidget extends StatelessWidget {
  final Function() onImagePressed;
  final Function() onEmojiPressed;
  final QuillController controller;
  final double toolbarHeight;

  const ToolbarWidget({
    Key? key,
    required this.onImagePressed,
    required this.onEmojiPressed,
    required this.controller,
    this.toolbarHeight = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: QuillToolbar(
        configurations: QuillToolbarConfigurations(
          // Configuración de visibilidad de botones
          showBoldButton: true,
          showItalicButton: false,
          showUnderLineButton: false,
          showStrikeThrough: false,
          showColorButton: true,
          showBackgroundColorButton: false,
          showClearFormat: false,
          showAlignmentButtons: true,
          showLeftAlignment: true,
          showCenterAlignment: true,
          showRightAlignment: true,
          showJustifyAlignment: false,
          showHeaderStyle: true,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: false,
          showCodeBlock: false,
          showQuote: true,
          showIndent: false,
          showLink: true,
          showUndo: true,
          showRedo: true,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
          showFontFamily: false,
          showFontSize: false,
          showSmallButton: false,
          showInlineCode: false,
          showDirection: false,

          // Botones personalizados para emoji, imagen
          customButtons: [
            QuillToolbarCustomButtonOptions(
              icon: const Icon(
                Icons.image_rounded,
                size: 20,
                color: Color(0xFF5A5A5A),
              ),
              tooltip: 'Insertar imagen',
              onPressed: onImagePressed,
            ),
            QuillToolbarCustomButtonOptions(
              icon: const Icon(
                Icons.emoji_emotions_rounded,
                size: 20,
                color: Color(0xFF5A5A5A),
              ),
              tooltip: 'Insertar emoji',
              onPressed: onEmojiPressed,
            ),
          ],

          // Opciones de botones
          buttonOptions: QuillToolbarButtonOptions(
            base: const QuillToolbarBaseButtonOptions(
              globalIconSize: 20,
              globalIconButtonFactor: 1.77,
            ),
            bold: QuillToolbarToggleStyleButtonOptions(
              iconData: Icons.format_bold_rounded,
              iconSize: 20,
              fillColor: const Color(0xFFE8F0FE),
            ),
            italic: QuillToolbarToggleStyleButtonOptions(
              iconData: Icons.format_italic_rounded,
              iconSize: 20,
              fillColor: const Color(0xFFE8F0FE),
            ),
            underLine: QuillToolbarToggleStyleButtonOptions(
              iconData: Icons.format_underlined_rounded,
              iconSize: 20,
              fillColor: const Color(0xFFE8F0FE),
            ),
            strikeThrough: QuillToolbarToggleStyleButtonOptions(
              iconData: Icons.format_strikethrough_rounded,
              iconSize: 20,
              fillColor: const Color(0xFFE8F0FE),
            ),
            listBullets: QuillToolbarToggleStyleButtonOptions(
              iconData: Icons.format_list_bulleted_rounded,
              iconSize: 20,
              fillColor: const Color(0xFFE8F0FE),
            ),
            listNumbers: QuillToolbarToggleStyleButtonOptions(
              iconData: Icons.format_list_numbered_rounded,
              iconSize: 20,
              fillColor: const Color(0xFFE8F0FE),
            ),
            undoHistory: QuillToolbarHistoryButtonOptions(
              isUndo: true,
              iconData: Icons.undo_rounded,
              iconSize: 20,
            ),
            redoHistory: QuillToolbarHistoryButtonOptions(
              isUndo: false,
              iconData: Icons.redo_rounded,
              iconSize: 20,
            ),
            linkStyle: QuillToolbarLinkStyleButtonOptions(
              iconData: Icons.link_rounded,
              iconSize: 20,
              dialogTheme: QuillDialogTheme(
                labelTextStyle: GoogleFonts.poppins(
                  color: const Color(0xFF1A237E),
                  fontWeight: FontWeight.w600,
                ),
                inputTextStyle: GoogleFonts.inter(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            color: QuillToolbarColorButtonOptions(
              iconData: Icons.format_color_text_rounded,
              iconSize: 20,
            ),
            backgroundColor: QuillToolbarColorButtonOptions(
              iconData: Icons.format_color_fill_rounded,
              iconSize: 20,
            ),
            clearFormat: QuillToolbarClearFormatButtonOptions(
              iconData: Icons.format_clear_rounded,
              iconSize: 20,
            ),
          ),

          toolbarSize: toolbarHeight,
          showDividers: true,
          axis: Axis.horizontal,
          color: Colors.white,
          sectionDividerColor: Colors.grey[200],
          sectionDividerSpace: 16,

          dialogTheme: QuillDialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}