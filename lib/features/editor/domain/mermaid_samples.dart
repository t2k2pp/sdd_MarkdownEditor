/// Mermaidダイアグラムのサンプルテンプレート
class MermaidSamples {
  /// フローチャートのサンプル
  static const String flowchart = '''
```mermaid
flowchart TD
    A[開始] --> B{条件分岐}
    B -->|Yes| C[処理1]
    B -->|No| D[処理2]
    C --> E[終了]
    D --> E
```
''';

  /// シーケンス図のサンプル
  static const String sequenceDiagram = '''
```mermaid
sequenceDiagram
    participant ユーザー
    participant クライアント
    participant サーバー
    ユーザー->>クライアント: 操作
    クライアント->>サーバー: リクエスト
    サーバー-->>クライアント: レスポンス
    クライアント-->>ユーザー: 結果表示
```
''';

  /// クラス図のサンプル
  static const String classDiagram = '''
```mermaid
classDiagram
    class Animal {
        +String name
        +int age
        +makeSound()
    }
    class Dog {
        +bark()
    }
    class Cat {
        +meow()
    }
    Animal <|-- Dog
    Animal <|-- Cat
```
''';

  /// ガントチャートのサンプル
  static const String ganttChart = '''
```mermaid
gantt
    title プロジェクト計画
    dateFormat  YYYY-MM-DD
    section 設計
    要件定義    :a1, 2024-01-01, 7d
    基本設計    :a2, after a1, 14d
    section 開発
    実装        :b1, after a2, 21d
    テスト      :b2, after b1, 14d
```
''';

  /// 円グラフのサンプル
  static const String pieChart = '''
```mermaid
pie title 売上構成
    "製品A" : 40
    "製品B" : 30
    "製品C" : 20
    "その他" : 10
```
''';

  /// 状態遷移図のサンプル
  static const String stateDiagram = '''
```mermaid
stateDiagram-v2
    [*] --> 待機中
    待機中 --> 処理中 : 開始
    処理中 --> 完了 : 成功
    処理中 --> エラー : 失敗
    エラー --> 待機中 : リトライ
    完了 --> [*]
```
''';

  /// すべてのサンプルを返す
  static List<MermaidSampleItem> get allSamples => [
    MermaidSampleItem(name: 'フローチャート', icon: '📊', template: flowchart),
    MermaidSampleItem(name: 'シーケンス図', icon: '🔀', template: sequenceDiagram),
    MermaidSampleItem(name: 'クラス図', icon: '📦', template: classDiagram),
    MermaidSampleItem(name: 'ガントチャート', icon: '📅', template: ganttChart),
    MermaidSampleItem(name: '円グラフ', icon: '🥧', template: pieChart),
    MermaidSampleItem(name: '状態遷移図', icon: '🔄', template: stateDiagram),
  ];
}

/// Mermaidサンプルのアイテム
class MermaidSampleItem {
  final String name;
  final String icon;
  final String template;

  const MermaidSampleItem({
    required this.name,
    required this.icon,
    required this.template,
  });
}
