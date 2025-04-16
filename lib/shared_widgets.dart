import 'package:flutter/material.dart';

class TitleCard extends StatelessWidget {
  final String title;
  final Widget icon;

  const TitleCard({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Row(
        spacing: 10,
        children: [
          icon,
          Text(
            title,
            style: theme.textTheme.titleMedium!.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorBoxWidget extends StatelessWidget {
  final String errorText;
  const ErrorBoxWidget({super.key, required this.errorText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.tertiary;
    final fg = theme.colorScheme.onTertiary;

    return Container(
      padding: EdgeInsets.only(top: 5, bottom: 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Column(
            children: [
              Text(
                "Error",
                style: theme.textTheme.bodyMedium!.copyWith(color: fg),
              ),
              FittedBox(
                child: Text(
                  errorText,
                  style: theme.textTheme.bodySmall!.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}