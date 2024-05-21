import 'package:flutter/material.dart';

Widget defaultLoadingWidget() {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

Widget defaultLoadErrorWidget(void Function()? onPressed) {
  return Center(
      child: Column(
    children: [
      const Text(
        "Something error.",
      ),
      TextButton(
          onPressed: onPressed,
          child: const Text(
            "Retry",
          ))
    ],
  ));
}

Widget defaultMoreLoadErrorWidget(
    BuildContext context, void Function()? onPressed) {
  return Center(
      child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            children: [
              Text(
                "Something error.",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Theme.of(context).colorScheme.onError),
              ),
              TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: onPressed,
                  child: Text(
                    "Retry",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ))
            ],
          )));
}

Widget defaultRefreshErrorWidget(BuildContext context) {
  return Center(
      child: Container(
    padding: const EdgeInsets.symmetric(
      vertical: 5,
      horizontal: 10,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.error,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
    ),
    child: Text(
      "Something error.",
      style: Theme.of(context)
          .textTheme
          .bodyMedium!
          .copyWith(color: Theme.of(context).colorScheme.onError),
    ),
  ));
}
