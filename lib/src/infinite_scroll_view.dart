import 'dart:async';

import 'package:flutter/material.dart';

import 'widget.dart';

typedef LoadRetryCallback = void Function();

enum InfiniteScrollType {
  toBottom,
  toBottomWithRefreshIndicator,
  toTop;
}

enum _LoadStatusUpdateType {
  initStart,
  initAlreadyLoaded,
  loadMoreStart,
  retry,
  refreshStart,
  itemChanged,
  errorOccured,
}

enum _LoadStatus {
  noop,
  loading,
  loaded,
  loadError,
  refreshing,
  refreshed,
  refreshError,
  moreLoading,
  moreLoaded,
  moreLoadError;
}

class InfiniteScrollView<T> extends StatefulWidget {
  const InfiniteScrollView({
    super.key,
    this.controller,
    this.infiniteScrollType = InfiniteScrollType.toBottom,
    required this.items,
    required this.builder,
    required this.hasMore,
    required this.loadMore,
    required this.retry,
    this.onRefresh,
    this.error,
    this.loadingWidgetMaker,
    this.loadErrorWidgetMaker,
    this.moreLoadingWidgetMaker,
    this.moreLoadErrorWidgetMaker,
    this.refreshErrorWidgetMaker,
    this.endOfDataWidgetMaker,
    this.strictMode = false,
    this.debugPrintLoadStatus = false,
  }) : assert(
            !(infiniteScrollType ==
                    InfiniteScrollType.toBottomWithRefreshIndicator &&
                onRefresh == null),
            'Argument refresh must be passed at using RefreshIndicator.');

  final ScrollController? controller;

  final InfiniteScrollType infiniteScrollType;

  final List<T>? items;

  final Widget Function(BuildContext context, T item, int index) builder;

  final bool hasMore;

  final void Function() loadMore;

  final void Function() retry;

  final Future<void> Function()? onRefresh;

  final Object? error;

  final Widget Function(BuildContext context)? loadingWidgetMaker;

  final Widget Function(BuildContext context, Object? error,
      LoadRetryCallback loadRetryCallback)? loadErrorWidgetMaker;

  final Widget Function(BuildContext context)? moreLoadingWidgetMaker;

  final Widget Function(BuildContext context, Object? error,
      LoadRetryCallback loadRetryCallback)? moreLoadErrorWidgetMaker;

  final Widget Function(BuildContext context, Object? error,)? refreshErrorWidgetMaker;

  final Widget Function(BuildContext context)? endOfDataWidgetMaker;

  final bool strictMode;

  final bool debugPrintLoadStatus;

  @override
  State<InfiniteScrollView> createState() => _InfiniteScrollViewState<T>();
}

class _InfiniteScrollViewState<T> extends State<InfiniteScrollView<T>> {
  late final ScrollController _controller =
      widget.controller ?? ScrollController();

  bool get _reverse =>
      [InfiniteScrollType.toTop].contains(widget.infiniteScrollType);

  _LoadStatus _status = _LoadStatus.noop;

  Widget _loadingWidget(BuildContext context) =>
      widget.loadingWidgetMaker != null
          ? widget.loadingWidgetMaker!(context)
          : defaultLoadingWidget();

  Widget _loadErrorWidget(BuildContext context, Object? error) =>
      widget.loadErrorWidgetMaker != null
          ? widget.loadErrorWidgetMaker!(context, error, _retry)
          : defaultLoadErrorWidget(_retry);

  Widget _moreLoadErrorWidget(BuildContext context, Object? error) =>
      widget.moreLoadErrorWidgetMaker != null
          ? widget.moreLoadErrorWidgetMaker!(context, error, _retry)
          : defaultMoreLoadErrorWidget(context, _retry);

  Widget _refreshErrorWidget(BuildContext context, Object? error) =>
      widget.refreshErrorWidgetMaker != null
          ? widget.refreshErrorWidgetMaker!(context, error,)
          : defaultRefreshErrorWidget(context);

  Widget _moreLoadingWidget(BuildContext context) =>
      widget.moreLoadingWidgetMaker != null
          ? widget.moreLoadingWidgetMaker!(context)
          : const Center(
              child: CircularProgressIndicator(),
            );

  Widget? _endOfDataWidget(BuildContext context) =>
      widget.endOfDataWidgetMaker != null
          ? widget.endOfDataWidgetMaker!(context)
          : null;

  @override
  void initState() {
    super.initState();
    if (widget.items != null) {
      _statusUpdate(_LoadStatusUpdateType.initAlreadyLoaded);
    } else {
      _statusUpdate(_LoadStatusUpdateType.initStart);
    }
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget as InfiniteScrollView<T>);

    // TODO: Prepare widget.itemComparator?
    final isItemChanged = oldWidget.items != widget.items ||
        oldWidget.items?.length != widget.items?.length;
    final isNewError = oldWidget.error != widget.error && widget.error != null;

    // Prioritize error than item change.
    if (isNewError) {
      _statusUpdate(_LoadStatusUpdateType.errorOccured);
    }
    if (isItemChanged) {
      _statusUpdate(_LoadStatusUpdateType.itemChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.debugPrintLoadStatus) {
      debugPrint('@build status: $_status');
    }
    switch (_status) {
      case _LoadStatus.noop:
        throw FlutterError(
            'Invalid status: LoadStatus noop must be updated before build start.');
      case _LoadStatus.refreshing:
        throw FlutterError(
            'Invalid status: At LoadStatus refreshing, the build method should not be called.');
      case _LoadStatus.loading:
        return _loadingWidget(context);
      case _LoadStatus.loadError:
        return _loadErrorWidget(context, widget.error);
      case _LoadStatus.loaded:
      case _LoadStatus.moreLoaded:
      case _LoadStatus.refreshed:
      case _LoadStatus.refreshError:
        if (widget.hasMore) {
          _controller.removeListener(_setOnceCallbackOnScrollEnd);
          _controller.addListener(_setOnceCallbackOnScrollEnd);
        }
      case _LoadStatus.moreLoading:
      case _LoadStatus.moreLoadError:
        break;
    }
    final Widget? endWidget = switch (_status) {
      _LoadStatus.moreLoading => _moreLoadingWidget(context),
      _LoadStatus.moreLoadError => _moreLoadErrorWidget(context, widget.error),
      _ => widget.hasMore ? null : _endOfDataWidget(context),
    };
    final bool useRefreshIndicator = switch (widget.infiniteScrollType) {
      InfiniteScrollType.toBottomWithRefreshIndicator => true,
      InfiniteScrollType.toBottom || InfiniteScrollType.toTop => false,
    };
    final Widget? startWidget = switch ((_status, useRefreshIndicator)) {
      (_LoadStatus.refreshError, true) =>
        _refreshErrorWidget(context, widget.error),
      (_, _) => null,
    };
    assert(widget.items != null, 'Items should not be null here.');
    final child = ListView.builder(
        controller: _controller,
        reverse: _reverse,
        itemBuilder: (BuildContext context, int index) {
          switch ((index, widget.items!.length - index, startWidget)) {
            case (0, int _, Widget _):
              return startWidget;
            case (> 0, -1, Widget _):
              return endWidget;
            case (> 0, > -1, Widget _):
              return widget.builder(
                  context, widget.items![index - 1], index - 1);
            case (> 0, < -1, Widget _):
              return null;
            case (_, 0, null):
              return endWidget;
            case (_, > 0, null):
              return widget.builder(context, widget.items![index], index);
            case (_, < 0, null):
              return null;
            default:
              throw FlutterError('Unexpected builder case.');
          }
        });

    return useRefreshIndicator
        ? RefreshIndicator(
            onRefresh: _refresh,
            child: child,
          )
        : child;
  }

  void _loadMore() {
    _statusUpdate(_LoadStatusUpdateType.loadMoreStart);
    setState(() {}); // To rebuild to disp loader (modified at 24/1/4)
    widget.loadMore();
  }

  void _retry() {
    _statusUpdate(_LoadStatusUpdateType.retry);
    setState(() {});
    widget.retry();
  }

  Future<void> _refresh() async {
    assert(widget.onRefresh != null,
        '_refresh can be called only when RefreshIndicator is used.');
    _statusUpdate(_LoadStatusUpdateType.refreshStart);
    await widget.onRefresh!();
  }

  void _statusUpdate(_LoadStatusUpdateType type) {
    if (widget.debugPrintLoadStatus) {
      debugPrint('@_statusUpdate: $_status->$type');
    }
    switch (type) {
      case _LoadStatusUpdateType.initStart:
        switch (_status) {
          case _LoadStatus.noop:
            _status = _LoadStatus.loading;
          default:
            throw FlutterError('Invalid status update attempted.');
        }
      case _LoadStatusUpdateType.initAlreadyLoaded:
        switch (_status) {
          case _LoadStatus.noop:
            _status = _LoadStatus.loaded;
          default:
            throw FlutterError('Invalid status update attempted.');
        }
      case _LoadStatusUpdateType.loadMoreStart:
        switch (_status) {
          case _LoadStatus.noop:
          case _LoadStatus.loadError:
            _status = _LoadStatus.loading;
          case _LoadStatus.loaded:
          case _LoadStatus.moreLoaded:
          case _LoadStatus.moreLoadError:
          case _LoadStatus.refreshed:
          case _LoadStatus.refreshError:
            _status = _LoadStatus.moreLoading;
          case _LoadStatus.loading:
          case _LoadStatus.moreLoading:
          case _LoadStatus.refreshing:
            // This case occurs when the state is not updated properly
            // after loading. Raises an exception if in strict mode.
            if (widget.strictMode) {
              throw FlutterError('Invalid status update attempted.');
            } else {
              _status = _LoadStatus.moreLoading;
            }
        }
      case _LoadStatusUpdateType.retry:
        switch (_status) {
          case _LoadStatus.loadError:
            _status = _LoadStatus.loading;
          case _LoadStatus.moreLoadError:
            _status = _LoadStatus.moreLoading;
          case _LoadStatus.noop:
          case _LoadStatus.loaded:
          case _LoadStatus.moreLoaded:
          case _LoadStatus.refreshError:
          case _LoadStatus.refreshed:
          case _LoadStatus.loading:
          case _LoadStatus.moreLoading:
          case _LoadStatus.refreshing:
            // retry action can be done only at error widget
            throw FlutterError('Invalid status update attempted.');
        }
      case _LoadStatusUpdateType.refreshStart:
        switch (_status) {
          case _LoadStatus.loaded:
          case _LoadStatus.moreLoaded:
          case _LoadStatus.moreLoadError:
          case _LoadStatus.refreshed:
          case _LoadStatus.refreshError:
            _status = _LoadStatus.refreshing;
          case _LoadStatus.loading:
          case _LoadStatus.moreLoading:
          case _LoadStatus.refreshing:
            // This case occurs when the state is not updated properly
            // after loading. Raises an exception if in strict mode.
            if (widget.strictMode) {
              throw FlutterError('Invalid status update attempted.');
            } else {
              _status = _LoadStatus.refreshing;
            }
          case _LoadStatus.noop:
          case _LoadStatus.loadError:
            throw FlutterError('Invalid status update attempted.');
        }
      case _LoadStatusUpdateType.errorOccured:
        switch (_status) {
          case _LoadStatus.loading:
            _status = _LoadStatus.loadError;
          case _LoadStatus.moreLoading:
            _status = _LoadStatus.moreLoadError;
          case _LoadStatus.refreshing:
            _status = _LoadStatus.refreshError;
          case _LoadStatus.loaded:
          case _LoadStatus.loadError:
          case _LoadStatus.moreLoaded:
          case _LoadStatus.moreLoadError:
          case _LoadStatus.refreshed:
          case _LoadStatus.refreshError:
            // This case occurs when the state is not updated properly
            // after loading. Raises an exception if in strict mode.
            if (widget.strictMode) {
              throw FlutterError('Invalid status update attempted.');
            } else {
              _status = _LoadStatus.loadError;
            }
          case _LoadStatus.noop:
            throw FlutterError('Invalid status update attempted.');
        }
      case _LoadStatusUpdateType.itemChanged:
        switch (_status) {
          case _LoadStatus.loading:
            _status = _LoadStatus.loaded;
          case _LoadStatus.moreLoading:
            _status = _LoadStatus.moreLoaded;
          case _LoadStatus.refreshing:
            _status = _LoadStatus.refreshed;
          case _LoadStatus.loadError:
          case _LoadStatus.loaded:
          case _LoadStatus.moreLoaded:
          case _LoadStatus.moreLoadError:
          case _LoadStatus.refreshed:
          case _LoadStatus.refreshError:
            // This is the case that item is updated for different reason than scroll event.
            // Since this case can always and frequently occur on the application side,
            // we allow it and do nothing.
            break;
          case _LoadStatus.noop:
            throw FlutterError('Invalid status update attempted.');
        }
    }
  }

  void _setOnceCallbackOnScrollEnd() {
    if (_controller.position.pixels >= _controller.position.maxScrollExtent) {
      _loadMore();
      _controller.removeListener(_setOnceCallbackOnScrollEnd);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}
