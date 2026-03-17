import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class IBText {
  IBText(this.text, {this.context});

  final String text;
  final BuildContext? context;

  TextStyle? _style;
  TextAlign? _align;
  int? _maxLines;
  TextOverflow? _overflow;

  IBText get titulo => _with(_titleStyle());
  IBText get subtitulo => _with(_subtitleStyle());
  IBText get body => _with(_bodyStyle());
  IBText get muted => _with(_bodyStyle().copyWith(color: AppColors.textMuted));
  IBText get caption => _with(_captionStyle());
  IBText get label => _with(_labelStyle());

  IBText color(Color color) => _with((_style ?? _bodyStyle()).copyWith(color: color));
  IBText weight(FontWeight weight) => _with((_style ?? _bodyStyle()).copyWith(fontWeight: weight));
  IBText align(TextAlign align) {
    _align = align;
    return this;
  }

  IBText maxLines(int max) {
    _maxLines = max;
    _overflow = TextOverflow.ellipsis;
    return this;
  }

  Text build() {
    return Text(
      text,
      style: _style ?? _bodyStyle(),
      textAlign: _align,
      maxLines: _maxLines,
      overflow: _overflow,
    );
  }

  IBText _with(TextStyle style) {
    final next = IBText(text, context: context);
    next._style = style;
    next._align = _align;
    next._maxLines = _maxLines;
    next._overflow = _overflow;
    return next;
  }

  TextStyle _titleStyle() {
    final base = context != null
        ? Theme.of(context!).textTheme.titleLarge
        : const TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
    return base!.copyWith(color: AppColors.text);
  }

  TextStyle _subtitleStyle() {
    final base = context != null
        ? Theme.of(context!).textTheme.titleMedium
        : const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return base!.copyWith(color: AppColors.text);
  }

  TextStyle _bodyStyle() {
    final base = context != null
        ? Theme.of(context!).textTheme.bodyMedium
        : const TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
    return base!.copyWith(color: AppColors.text);
  }

  TextStyle _captionStyle() {
    final base = context != null
        ? Theme.of(context!).textTheme.bodySmall
        : const TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
    return base!.copyWith(color: AppColors.textMuted);
  }

  TextStyle _labelStyle() {
    return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text);
  }
}
