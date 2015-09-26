# encoding: utf-8
#
# パンくずリストの出力プラグイン
#
require 'cgi'

module Jekyll
  # パンくずリスト
  class Breadcrumbs < Liquid::Tag
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
      @site = context.registers[:site]
      @page = context.registers[:page]
      # 階層初期化
      @hierarchy = Array.new([])
      title = (@site.config['breadcrumbs']['home']['title'].nil?) ? 'Home' : @site.config['breadcrumbs']['home']['title']
      @base_url = (@site.config['breadcrumbs']['home']['url'].nil?) ? 'Home' : @site.config['breadcrumbs']['home']['url']
      @hierarchy << {:name => title, :url => @base_url}
      if @page['collection'].nil?
        render_other()
      else
        render_collection()
      end
      generate()

      "#{@output}"
    end

    # コレクション外のページ処理
    def render_other()
      # indexページはそのまま終了
      if @page['url'] == @base_url
        return
      end
      # categoryページはカテゴリ出力して終了
      if !@page['category'].nil?
        @hierarchy << {:name => @page['category'], :url => @page['url']}
        return
      end
      # カテゴリの先頭を階層とする
      category_dir = ""
      categories = @page['categories']
      if !categories.nil? && categories.count > 0
        category_dir = "/categories/" + categories[0] + "/index.html"
        @hierarchy << {:name => categories[0], :url => category_dir}
      end
      # 当該ページを追加
      if !@page['title'].nil? && category_dir != @page['url']
        @hierarchy << {:name => @page['title'], :url => @page['url']}
      end
    end

    # コレクションのページ処理
    def render_collection()
      prefix = (@site.config['breadcrumbs']['collection_prefix'].nil?) ? 'Collection:' : @site.config['breadcrumbs']['collection_prefix']
      collection_dir = "/collections/" + @page['collection']
      # collection名設定
      name = (@site.config['collections'][@page['collection']]['name'].nil?) ? @page['collection'] : prefix + @site.config['collections'][@page['collection']]['name']
      # collectionページを追加
      @hierarchy << {:name => name, :url => collection_dir}
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
          @hierarchy << {:name => "---", :url => url + ".html"}
        else
          @hierarchy << {:name => result.data['title'], :url => url + ".html"}
        end
        url << "/"
      end
      url = "/" + @page['collection'] + "/" + @page['url']
      if @page['title'].nil?
        @hierarchy << {:name => "---", :url => url}
      else
        @hierarchy << {:name => @page['title'], :url => url}
      end
    end

    # HTMLを生成
    def generate()
      @output = '<ul class="breadcrumbs">'
      for item in @hierarchy
        item[:name] = "---" if item[:name].nil?
        @output << "<li><a href=\"" + item[:url] + "\">" + '<span class="divider">' + CGI.escapeHTML(item[:name]) + "</span></a></li>"
      end
      @output << '</ul>'
    end

    # 対象のURLを持つパスを探索
    # @param [String] url  出力するパス(_sites)からの絶対パス
    # ex. "_sites/index.html" => "/index.html"
    def search_page(url)
      result = @site.pages.find {|item| item.url == url}
      if result != nil
        return result
      end
      result = @site.posts.find {|item| item.url == url}
      if result != nil
        return result
      end
      for collection in @site.collections
        result = collection[1].docs.find {|item| item.url == url}
        if result
          return result
        end
      end
      return nil
    end
  end
end

Liquid::Template.register_tag('breadcrumbs', Jekyll::Breadcrumbs)
