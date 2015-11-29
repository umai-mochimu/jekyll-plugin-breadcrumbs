# encoding: utf-8
#
# パンくずリストの出力プラグイン
# @author 在望もむ
# @date 2015/11/22
require 'cgi'

# Jekyllプラグイン
module Jekyll
  # パンくずリスト共通処理クラス
  class Breadcrumbs
    # コンストラクタ
    def initialize()
      @default_settings = {'home' => {'title' => 'Home', 'url' => 'index.html'}, 'collection_prefix' => 'Collections:'}
    end

    # ページ毎実施処理
    # @param  [Misc]  context コンテキスト
    def create_hierarchy(context)
      @site = context.registers[:site]
      @page = context.registers[:page]
      # 階層初期化
      @hierarchy = Array.new([])
      # 設定読み取り
      if @site.config['breadcrumbs'].nil?
        @site.config['breadcrumbs'] = @default_settings
      end
      if @site.config['breadcrumbs']['home'].nil?
        @site.config['breadcrumbs']['home'] = @default_settings['home']
      end
      title = (@site.config['breadcrumbs']['home']['title'].nil?) ? @default_settings['home']['title'] : @site.config['breadcrumbs']['home']['title']
      @base_url = (@site.config['breadcrumbs']['home']['url'].nil?) ? @default_settings['home']['url'] : @site.config['breadcrumbs']['home']['url']
      @hierarchy << {'title' => title, 'url' => @base_url}
      # Jekyll 3.0よりpostがpostsコレクションに割り当たったためチェックを追加
      if @page['collection'].nil? || @page['collection'] == 'posts'
        render_other()
      else
        render_collection()
      end
      return @hierarchy
    end

    private
    # コレクション外のページ処理
    def render_other()
      # indexページはそのまま終了
      if @page['url'] == @base_url
        return
      end
      # categoryページはカテゴリ出力して終了
      if !@page['category'].nil?
        @hierarchy << {'title' => @page['category'], 'url' => @page['url']}
        return
      end
      # カテゴリの先頭を階層とする
      category_dir = ""
      categories = @page['categories']
      if !categories.nil? && categories.count > 0
        category_dir = "/categories/" + categories[0] + "/index.html"
        @hierarchy << {'title' => categories[0], 'url' => category_dir}
      end
      # 当該ページを追加
      if !@page['title'].nil? && category_dir != @page['url']
        @hierarchy << {'title' => @page['title'], 'url' => @page['url']}
      end
    end

    # コレクションのページ処理
    def render_collection()
      prefix = (@site.config['breadcrumbs']['collection_prefix'].nil?) ? 'Collection:' : @site.config['breadcrumbs']['collection_prefix']
      collection_dir = "/collections/" + @page['collection']
      # collection名設定
      title = (@site.config['collections'][@page['collection']]['name'].nil?) ? @page['collection'] : prefix + @site.config['collections'][@page['collection']]['name']
      # collectionページを追加
      @hierarchy << {'title' => title, 'url' => collection_dir}
      # 中間ページを追加
      page_url = @page['url']
      page_url.slice!("/" + @page['collection'] + "/")
      url_array = page_url.split("/")
      # 末尾のファイル名を削除する
      url_array.pop()
      url = "/" + @page['collection'] + "/"
      for item in url_array
        url << item
        result = search_page(url + ".html")
        if result.nil?
          @hierarchy << {'title' => "---", 'url' => url + ".html"}
        else
          @hierarchy << {'title' => result.data['title'], 'url' => url + ".html"}
        end
        url << "/"
      end
      url = "/" + @page['collection'] + "/" + @page['url']
      if @page['title'].nil?
        @hierarchy << {'title' => "---", 'url' => url}
      else
        @hierarchy << {'title' => @page['title'], 'url' => url}
      end
    end

    # 対象のURLを持つパスを探索
    # @param [String] url  出力するパス(_sites)からの絶対パス
    # ex. "_sites/index.html" => "/index.html"
    def search_page(url)
      result = @site.pages.find {|item| item.url == url}
      if !result.nil?
        return result
      end
      for collection in @site.collections
        result = collection[1].docs.find {|item| item.url == url}
        if !result.nil?
          return result
        end
      end
      return nil
    end
  end

  # パンくずリスト出力タグ
  class BreadcrumbsTag < Liquid::Tag
    # 初期化フック処理
    # @param  [String]  name  名前
    # @param  [String]  text  テキスト
    # @param  [String]  tokens  トークン
    def initialize(name, text, tokens)
      super
    end

    # ページ毎実施処理
    # @param  [Misc]  context コンテキスト
    def render(context)
      breadcrumbs = Breadcrumbs.new
      hierarchy = breadcrumbs.create_hierarchy(context)
      generate(hierarchy)
      "#{@output}"
    end

    # HTMLを生成
    # @param  [Array]  hierarchy 階層情報
    def generate(hierarchy)
      @output = '<ul class="breadcrumbs">'
      for item in hierarchy
        item['title'] = "---" if item['title'].nil?
        @output << "<li><a href=\"" + item['url'] + "\">" + '<span class="divider">' + CGI.escapeHTML(item['title']) + "</span></a></li>"
      end
      @output << '</ul>'
    end
  end

  # パンくずリスト出力ブロック
  class BreadcrumbsBlock < Liquid::Block
    # 初期化フック処理
    # @param  [String]  name  名前
    # @param  [String]  text  テキスト
    # @param  [String]  tokens  トークン
    def initialize(name, text, tokens)
      super
    end

    # ページ毎実施処理
    # @param  [Misc]  context コンテキスト
    def render(context)
      breadcrumbs = Breadcrumbs.new()
      hierarchy = breadcrumbs.create_hierarchy(context)
      context.stack do
        context['entries'] = hierarchy
        return super
      end
    end
  end
end

Liquid::Template.register_tag('breadcrumbs_tag', Jekyll::BreadcrumbsTag)
Liquid::Template.register_tag('breadcrumbs', Jekyll::BreadcrumbsBlock)
