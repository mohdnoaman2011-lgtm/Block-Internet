class AppItem {
  AppItem(this.name, this.colors, {this.blocked = false, this.system = false});
  final String name;
  final List<Color> colors;
  final bool system;
  bool blocked;
  String get letter => name[0];
}
