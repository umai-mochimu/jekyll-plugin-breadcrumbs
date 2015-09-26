# jekyll-plugin-breadcrumbs

パンくずリストを出力するプラグイン。

## インストール

<Jekyll Dir>/plugins/breadcrumbs.rbを突っ込むだけ。

## オプション

`_config.yml`には以下の設定が可能。

```yaml
breadcrumbs:
  home:
    title: [string]
    url: [string]
  collection_prefix: [string]
```

- breadcrumbs/home/title パンくずリストの先頭表示名
- breadcrumbs/home/url パンくずリストの先頭URL
- breadcrumbs/collection_prefix コレクションの先頭に付加する文字列

デフォルト値は以下の設定。

```yaml
breadcrumbs:
  home:
    title: "Home"
    url: "index.html"
  collection_prefix: "Collections:"
```
