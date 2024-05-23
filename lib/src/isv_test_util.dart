import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class IsvTestUtil {
  /// 無限スクロールのloadMoreの発火を伴うスクロールのために、scrollUntilVisibleをラップした関数。
  /// 処理内容はscrollUntilVisibleとpumpを実行しているのみで単純であり無限スクロールやloadMoreに特化した関数でない。
  /// ただ、loadMoreの発火を確実に行うようにdeltaの大きさなどのチューニングにおいて苦労したため、その背景などのコメントも含めてAPIとして残しておくことにした。
  ///
  /// ・処理
  ///  - scrollUntilVisible
  ///    要素を見つけるまでdragとpumpが実行される。
  ///    maxScrollExtentが計算されずにスクロールの末尾に到達することを防ぐため、引数のdeltaのデフォルト値を小さくしている。
  ///  - pump
  ///    scrollUntilVisibleは対象を見つけた後にjumpToのみ行い、このスクロールポジションの移動についてはpumpをしない。
  ///    本関数では、最終的なスクロールポジションを画面へ反映するために最後にpumpをしている。
  ///
  /// ・deltaの大きさ
  /// delta < ListViewのキャッシュ領域（cacheExtent。デフォルト250?）の大きさ にしておく
  /// まず前提としてListView.builderではitemCountを指定しない場合はmaxScrollExtentを仮計算せずにInfiniteとし、
  /// キャッシュ領域に最後の要素が入ってきた際のリレイアウトの際にはじめてmaxScrollExtentを算出する。
  /// この前提で考えると、1.現時点でmaxScrollExtentがInfinite -> 2.次のdragによってスクロールの末尾を超えてしまった、という場合、
  /// その後はmaxScrollExtentがInfinityのままmaxScrollsに達してしまい、スクロールイベントによるmoreLoadが発火しないまま
  /// finderは見つかず（Bad state: No element）としてエラーになってしまう。
  /// ※ なお、ListViewのphysicsによって多少挙動は違った。
  /// 　末尾に到達するとスクロールイベント自体が起きないケースと、スクロールイベントは起きるがInfinityのままというケース。
  ///   いずれにせよ、スクロールイベントによるmoreLoadが発火しないので、目的のデータがロードされずエラーになる。
  /// これが発生しないようにするためには、deltaをcacheExtentより小さい値にする必要がある。
  /// （cacheExtentより低くすれば、dragによって末尾に到達する前に必ずcacheExtent内に最後の要素が入るのでmaxScrollExtentが計算されるはず。
  /// 本関数ではdeltaのデフォルト値を十分に小さくしている。
  ///   ※ あまりにdeltaが小さいと目的地まで辿り着く前にmaxScrollsの回数を超えてしまう可能性がある。
  ///
  /// ・durationの大きさ
  /// 特に大きくしても小さくしても問題はないので決めの問題になる。
  /// ローディング処理で呼び出すスタブなどにDurationを設定している場合、
  /// それより圧倒的に小さいとmaxScrolls分dragされても、ローディング処理が終わらないといったことは起きるので、
  /// そういった処理のDurationとの平仄を合わせる必要はある。
  /// 本関数ではデフォルトのままにしている。
  static Future<void> scrollUntilVisibleAndPump(
      WidgetTester tester, FinderBase<Element> finder,
      {FinderBase<Element>? scrollableParent,
      double delta = 10.0,
      Duration duration = const Duration(milliseconds: 50)}) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      maxScrolls: 1500,
      duration: duration,
      scrollable: scrollableParent != null
          ? find.descendant(
              of: scrollableParent, matching: find.byType(Scrollable))
          : null,
    );
    // expect(finder, findsAtLeast(1));

    // この時点で下記の想定となる
    // 1. finderに末尾の子が指定されていた場合
    // - スクロールポジションはmaxScrollExtentとなっている(ただし画面に反映されているとは限らない)
    // - maxScrollExtentはInfinityではない
    // - moreLoadイベントが発火している
    //
    // 2. finderに、moreLoad開始以降に表示されるウィジェット(ローディングウィジェットもこれに該当)が指定
    // - スクロールポジションはfinderで指定したウィジェットの下端の位置まで移動している(ただし画面に反映されているとは限らない)
    // - 途中で1回以上のmoreLoadイベントが発火(完了)している。
    //
    // 3. 上記以外 ※ 動作はするがこの用途の場合は本関数を利用する必要はなくscrollUntilVisibleで十分。
    // - スクロールポジションはfinderで指定したウィジェットの下端の位置まで移動している(ただし画面に反映されているとは限らない)

    // 最終的なスクロールポジションの位置を画面に反映
    //
    // moreLoadが発火済の場合(上記の1.の場合)、ここでリビルドされてローディングウィジェットが表示される。
    // ※ ただしローディングウィジェットは現在のスクロールポジションよりも下にあり、かつViewport外にあるためfindで見つからない点に注意。
    await tester.pump();
  }
}
