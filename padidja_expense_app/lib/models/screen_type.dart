enum ScreenType { mobile, tablet, desktop }

class ResponsiveDimensions {
  final double headerHeight;
  final double padding;
  final double cardPadding;
  final double fontSize;
  final double titleFontSize;
  final double headerFontSize;
  final double buttonHeight;
  final double buttonWidth;
  final double maxContentWidth;
  final int crossAxisCount;

  ResponsiveDimensions({
    required this.headerHeight,
    required this.padding,
    required this.cardPadding,
    required this.fontSize,
    required this.titleFontSize,
    required this.headerFontSize,
    required this.buttonHeight,
    required this.buttonWidth,
    required this.maxContentWidth,
    required this.crossAxisCount,
  });
}