* このパッケージはpub.devには公開していないパッケージとなる。
* This package is not published on pub.dev.

## Features
* This is a package that simply handles infinite scrolling. 
* Dealing with infinite scrolling involves a bit more state management. 
* Using this package separates the concerns of the infinite scroll part.
* 無限スクロールの状態管理を担うパッケージ。
* スクロールによる追加ロード、Indicatorによるリフレッシュをサポート。
* 初期ローディング中、追加ローディング中、リフレッシング（RefreshIndicator）、初期ロードエラー、追加ロードエラー、リフレッシュエラーの画面表示を行う。
* buildメソッドでは各状態に応じた表示制御を行う。

## Architecture
* buildメソッドでは、現在の状態（_status）に応じたビルド処理を行う。
* 以下の処理では、現在の状態（_status）およびitemsやerrorの変化, アクションの内容に応じて次の状態へ遷移する。
    * ライフサイクル（InitState, didUpdateWidget）内でのitems, errorのチェック
    * アクション（loadMore, refresh, retry)
* 状態遷移は現在の状態に基づいて決定的に行われる。
* 一部のアクション（loadMore, retry）ではsetStateを行い、親によるリビルドを待たずに自身のビルドをトリガーする。
    * loadMoreやretryはローディング表示を先行して行う必要があるため。
![](./doc/svg/infinite_scroll_design.drawio.svg)

## Getting started
TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage
* See example/ for detail.
```dart
class _DummyPageState extends State<_DummyPage> {
  List<String> _items = [];
  bool hasMore = true;
  Object? error;

  void loadMore() {
    // Initial load and load more logic that updates items, hasMore, error
  }

  void loadNew() {
    // load new logic that updates items, hasMore, error
  }

  void retry() {
    // retry load more 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InfiniteScrollView<String>(
        items: _items,
        controller: ScrollController(),
        // Default is InfiniteScrollType.toBottom which's scroll direction is to bottom and does not have RefreshIndocator.
        infiniteScrollType: InfiniteScrollType.toBottomWithRefreshIndicator,
        builder: (BuildContext context, String item, int index) {
          return ListTile(
            title: Text(item),
          );
        },
        hasMore: hasMore,
        loadMore: loadMore,
        retry: retry,
        onRefresh: loadNew,
        error: error,
        loadErrorWidgetMaker: (context, error, loadRetryCallback) {
          return LoadErrorWidget(loadRetryCallback);// Some widgets if you want to use original widget when load error occured.
        },
        moreLoadErrorWidgetMaker: (context, error, loadRetryCallback) {
          return LoadMoreErrorWidget(loadRetryCallback);// Some widgets if you want to use original widget when load more error occured.
        },
        refreshErrorWidgetMaker: (context, error) {
          return RefreshErrorWidget();// Some widgets if you want to use original widget when refresh error occured.
        },
      ),
    );
  }
}
```

## Additional information
* 初期ローディングを経由しない
    * 状態遷移図に記載されているように、InitStateのタイミングでitemsに既に値が入っている場合はローディング画面は表示されない。
    * これは例えば、１つの画面で複数のデータリソースから取得するケースで、結果が全て揃ってからはじめてInfinieScrollViewウィジェットのビルドを始めたいといったユースケースのため。    
* エラーの状態遷移
    * InfiniteScrollViewはerrorによる遷移パターンを下記としており、「moreLoading」「refreshing」以外の状態で起きたエラーはすべて「loadError」になる。
        * 「moreLoading」 -> 「moreLoadError」
        * 「refreshing」 -> 「refreshError」
        * 上記以外の状態 -> 「loadError」
    * Strict mode
        * strictMode: trueとすると、上記の３つ目の遷移は初期ロード時のみ許容され、それ以外でエラーが発生すると例外をthrowする。
    * データリソースがStreamの場合
        * データリソースがStreamの場合はアクション(loadMoreやrefresh)とは無関係のタイミングでデータ受信の際にerrorが発生する可能性がある。
        * 例
            * loadMoreのアクションを行った際、状態は「moreLoading」となる。
            * データリソースがStreamの場合、（loadMoreのアクションが完了する前に）loadMoreとは無関係のエラーを受信し、InfiniteScrollViewの親ウィジェットがリビルドされてerrorが渡される。
            * この場合、InfiniteScrollViewは「moreLoading」->「moreLoadError」という状態遷移を行う。（moreLoadの結果としてのエラーとして扱われ、「loadError」にはならない。）
* リトライ
    * 初期ロードエラーおよびloadMoreエラーの際は、loadErrorWidgetMakerやmoreLoadErrorWidgetMakerに渡されるコールバックを実行することでリトライを実行する。
* デバッグ
    * debugPrintLoadStatusをtrueとすることで、状態遷移をするたびに標準出力へ出力をする。