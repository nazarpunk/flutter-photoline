import 'dart:math' as math;

extension PhotolineListExtensions<E> on List<E> {
  E reorder(int oldIndex, int newIndex) {
    final item = removeAt(oldIndex);
    insert(math.min(length, newIndex), item);
    return item;
  }
}
