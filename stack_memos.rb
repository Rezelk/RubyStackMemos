#===============================================================================
# name: Stack Memos
# version: 0.1
# encoding: UTF-8 (without BOM)
#===============================================================================

require "sinatra"
require "active_record"
require "haml"

# DB設定を読み込んで設定
ActiveRecord::Base.configurations = YAML.load_file("config/database.yml")
ActiveRecord::Base.establish_connection("development")

class Memo < ActiveRecord::Base
	#self.table_name = "memos"
end

# ルートアクセス時の処理
get "/" do
	p "### get '/'"
	
	# メッセージを初期化
	@message = ""
	
	# ページタイトルの設定
	@page_title = "Stack memos on Sinatra"
	
	# DBからメモを取得
	p "### SELECT * FROM memos WHERE(NOT is_deleted='true');"
	@memos = Memo.where("NOT is_deleted='true'").all
	p "### get " + @memos.length.to_s + " memos"
	
	# index.hamlを表示
	haml :index
end

# フォームアクション時の処理
post "/insert" do
	p "### post '/insert'"
	
	# パラメーターを取得
	@title = params[:title]
	@content = params[:content]
	@tags = params[:tags]
	
	# メッセージを初期化
	@message = ""
	
	# パラメーターチェック
	if @title.nil? || @content.nil? || @tags.nil? then
		@message = "ERROR: 無効なパラメーターを検出しました。"
		redirect "/"
	end
	
	# パラメーターチェック
	if @title == "" && @content == "" then
		@message = "ERROR: タイトルと内容を空のメモは追加できません。"
		redirect "/"
	end
	
	# 日付を取得
	day = Time.now
	date_time = day.strftime("%Y-%m-%d %H:%M:%S")
	
	# 記号をエスケープ
	@title = @title.gsub("<", "&lt;").gsub(">", "&gt;").gsub("\n", "<br/>").gsub("\t", "&nbsp;&nbsp;&nbsp;")
	@content = @content.gsub("<", "&lt;").gsub(">", "&gt;").gsub("\n", "<br/>").gsub("\t", "&nbsp;&nbsp;&nbsp;")
	@tags = @tags.gsub("<", "&lt;").gsub(">", "&gt;").gsub("\n", "<br/>").gsub("\t", "&nbsp;&nbsp;&nbsp;")
	
	# 無題はタイトルを付与
	if @title == "" then
		@title = "Untitled"
	end
	
	# レコードを作成
	p "### INSERT INTO memos VALUES('" + @title + "','" + @content + "','" + @tags + "','false','" + date_time + "');"
	memo = Memo.new do |r|
		r.title = @title
		r.content = @content
		r.tags = @tags
		r.is_deleted = "false"
		r.date_time = date_time
	end
	
	# レコードを挿入
	memo.save
	
	# メッセージを設定
	@message = "メモを設定しました。"
	
	# "/:message"へリダイレクト
	redirect "/"
end

# フォームアクション時の処理
post "/delete" do
	p "### post '/delete'"
	
	# パラメーターを取得
	@selections = params[:selection]
	
	# メッセージを初期化
	@message = ""
	
	# パラメーターチェック
	if @selections.nil? then
		@message = "ERROR: 無効なパラメーターを検出しました。"
		redirect "/"
	end
	
	# 選択されている要素のvalue（date_time）をキーに論理削除する
	@selections.each do |value|
		p "### UPDATE memos SET is_deleted='true' WHERE(date_time='" + value + "');"
		#memo = Memo.where("date_time=?", value).first
		Memo.update_all("is_deleted='true'", "date_time='"+value+"'")
		#memo.save
	end
	
	# メッセージを設定
	@message = "INFO: メモを " + @selections.length.to_s + "件 削除しました。"
	
	# "/:message"へリダイレクト
	redirect "/"
end
