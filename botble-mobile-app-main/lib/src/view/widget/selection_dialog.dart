import 'package:flutter/material.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';

class SelectionDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemTitle;
  final bool Function(T, T) isSelected;
  final int Function(T)? orderBy;

  const SelectionDialog({
    super.key,
    required this.title,
    required this.items,
    this.selectedItem,
    required this.itemTitle,
    required this.isSelected,
    this.orderBy,
  });

  @override
  State<SelectionDialog<T>> createState() => _SelectionDialogState<T>();
}

class _SelectionDialogState<T> extends State<SelectionDialog<T>> {
  late List<T> _sortedItems;

  @override
  void initState() {
    super.initState();
    _sortedItems = List.from(widget.items);
    if (widget.orderBy != null) {
      _sortedItems.sort(
        (a, b) => widget.orderBy!(a).compareTo(widget.orderBy!(b)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.getCardBackgroundColor(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: kAppTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getPrimaryTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _sortedItems.length,
              itemBuilder: (context, index) {
                final item = _sortedItems[index];
                return ListTile(
                  title: Text(
                    widget.itemTitle(item),
                    style: kAppTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getPrimaryTextColor(context),
                    ),
                  ),
                  trailing:
                      widget.isSelected(item, widget.selectedItem as T)
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                  onTap: () {
                    Navigator.pop(context, item);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
