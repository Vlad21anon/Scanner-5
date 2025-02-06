import 'dart:math';

import 'package:flutter/material.dart';
import 'package:snappy_list_view/snappy_list_view.dart';

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<YourSnappyWidget> yourContentList =
  List.generate(5, (index) => YourSnappyWidget.random(max: 300, min: 50));

  // Создаем список ключей для каждого элемента списка.
  late List<GlobalKey> _itemKeys;

  final PageController controller = PageController(initialPage: 0);
  late final TabController tabController;

  /// Динамические настройки
  Axis axis = Axis.vertical;
  bool reverse = false;

  // Флаги и переменные для перетаскиваемого виджета
  bool _showDraggable = false;
  int? _attachedIndex; // индекс элемента, к которому прикреплен виджет
  GlobalKey? _attachedKey; // ключ элемента-якоря
  Offset _draggableRelativeOffset = Offset.zero; // относительный сдвиг внутри элемента

  @override
  void initState() {
    _itemKeys = List.generate(yourContentList.length, (_) => GlobalKey());
    controller.addListener(pageListener);
    tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(pageListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenSize = MediaQuery.of(context).size;

    // Вычисляем позицию перетаскиваемого виджета, привязанного к якорному элементу.
    Offset draggablePosition = Offset.zero;
    if (_showDraggable && _attachedKey?.currentContext != null) {
      final RenderBox box =
      _attachedKey!.currentContext!.findRenderObject() as RenderBox;
      final baseOffset = box.localToGlobal(Offset.zero);
      draggablePosition = baseOffset + _draggableRelativeOffset;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SnappyListView Demo'),
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: SnappyListView(
                  reverse: reverse,
                  controller: controller,
                  itemCount: yourContentList.length,
                  itemSnapping: true,
                  physics: const CustomPageViewScrollPhysics(),
                  itemBuilder: (context, index) {
                    final currentSnappyWidget = yourContentList[index];
                    return Container(
                      key: _itemKeys[index],
                      height: currentSnappyWidget.height,
                      width: currentSnappyWidget.width,
                      color: currentSnappyWidget.color,
                      child: Center(child: Text("Index: $index")),
                    );
                  },
                  scrollDirection: axis,
                ),
              ),
              Text(
                "CurrentPage: ${controller.hasClients ? currentPage : 0}",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: () => setState(() => axis == Axis.horizontal
                        ? current.width = randomSize
                        : current.height = randomSize),
                    child: const Text("Resize current"),
                  ),
                  TextButton(
                    onPressed: () => setState(
                            () => yourContentList.removeAt(currentPage!.round())),
                    child: const Text("Delete current"),
                  ),
                  TextButton(
                    onPressed: () => setState(() => yourContentList.insert(
                        currentPage!.round() + 1, YourSnappyWidget.random())),
                    child: const Text("Insert after current"),
                  ),
                  TextButton(
                    onPressed: () => controller.animateToPage(0,
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.linear),
                    child: const Text("Animate to first"),
                  ),
                  TextButton(
                    onPressed: () => setState(() =>
                    axis = axis == Axis.horizontal ? Axis.vertical : Axis.horizontal),
                    child: const Text("Change axis"),
                  ),
                  TextButton(
                    onPressed: () => setState(() => reverse = !reverse),
                    child: const Text("Reverse"),
                  ),
                  // Кнопка для добавления перетаскиваемого виджета
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _attachedIndex = currentPage!.round();
                        _attachedKey = _itemKeys[_attachedIndex!];
                        _draggableRelativeOffset = Offset.zero;
                        _showDraggable = true;
                      });
                    },
                    child: const Text("Add Draggable View"),
                  ),
                ],
              )
            ],
          ),
          // Если виджет добавлен, размещаем его привязанным к якорному элементу.
          if (_showDraggable)
            Positioned(
              left: draggablePosition.dx,
              top: draggablePosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _draggableRelativeOffset += details.delta;
                  });
                },
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blueAccent,
                  alignment: Alignment.center,
                  child: const Text(
                    "Draggable",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double get randomSize => Random().nextInt(300).clamp(100, 300).toDouble();

  YourSnappyWidget get current =>
      yourContentList.elementAt(currentPage!.round());

  double? get currentPage => controller.hasClients
      ? double.parse(controller.page!.toStringAsFixed(3))
      : null;

  void pageListener() => setState(() {});

  @override
  bool get wantKeepAlive => true;
}

class YourSnappyWidget {
  double width;
  double height;
  Color color;

  YourSnappyWidget({
    required this.color,
    required this.width,
    required this.height,
  });

  YourSnappyWidget.random({int max = 300, int min = 100})
      : width = Random().nextInt(max).clamp(min, max).toDouble(),
        height = Random().nextInt(max).clamp(min, max).toDouble(),
        color =
        Colors.accents.elementAt(Random().nextInt(Colors.accents.length));
}

class CustomPageViewScrollPhysics extends ScrollPhysics {
  const CustomPageViewScrollPhysics({ScrollPhysics? parent})
      : super(parent: parent);

  @override
  CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 50,
    stiffness: 100,
    damping: 0.8,
  );
}