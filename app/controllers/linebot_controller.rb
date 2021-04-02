class LinebotController < ApplicationController
    require 'line/bot'
    require "selenium-webdriver"
    require "time"
    require "date"
    # callbackアクションのCSRFトークン認証を無効
    protect_from_forgery :except => [:callback]    

      # LINE Developers登録完了後に作成される環境変数の認証
    def client
      
      @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      

      }
    end


    def callback
      body = request.body.read

      signature = request.env['HTTP_X_LINE_SIGNATURE']

      unless client.validate_signature(body, signature)
        error 400 do 'Bad Request' end
      end
      events = client.parse_events_from(body)

      events.each do |event|

        if event.message["text"] == "予約"
          message = baskeyoyaku_login
        elsif
          event.message["text"] == "確認"
          message = baskeyoyaku_index
        else
          message="抽選申し込み予約は「予約」"+"\n"+"抽選確認は「確認」"+"\n"+"を送信して下さい。"+"\n"+"「予約」送信後、30秒程立ちましたら"+"「確認」を送信してください。"
        end

        case event
        when Line::Bot::Event::Message
          case event.type
          when Line::Bot::Event::MessageType::Text
            message = {
              type: 'text',
              text: message
            }
          end
        end
        client.reply_message(event['replyToken'], message)
      end
      head :ok


    end

  def yoyaku_massage
    mess= "予約しました。"+"\n"+"「確認」と打って確かめてください。"
    return mess
  end

  def baskeyoyaku_login
      #Chrome用のドライバ
      driver = Selenium::WebDriver.for :chrome

      #オーパスにアクセスする
      driver.get "https://reserve.opas.jp/osakashi/menu/Logout.cgi"

      # 利用者IDを入力
      element = driver.find_element(:id, 'txtRiyoshaCode')
      element.send_keys ENV["riyhoshaCode_"+"#{params["events"][0]["source"]["userId"]}"]
      # パスワードを入力

      element2 = driver.find_element(:id, 'txtPassWord')
      element2.send_keys ENV["PASSWORD_"+"#{params["events"][0]["source"]["userId"]}"]

      # 決定ボタンをクリック
      element3 = driver.find_element(:class, 'loginbtn')
      element3.click
      
      # ログイン失敗時にメッセージを返す場合は以下コメントアウトを流用

      # error = driver.find_element(:class, 'a-alert-content')
      # if error.text == "このEメールアドレスを持つアカウントが見つかりません" then

      #   message = "メルアド間違えてる"
      #   driver.quit
      #   return message
      # end

      #抽選申し込みクリック
      elements = driver.find_elements(:class, "bgpng")
      elements[3].click
      # sleep(0.1)
      #利用目的クリック
      element4 = driver.find_element(:xpath, '//*[@id="mmaincolumn"]/div/table/tbody/tr[2]/td')
      element4.click
      # sleep(0.1)

      #バスケットボール選択
      element5 = driver.find_element(:xpath, '//*[@id="mmaincolumn"]/div/table/tbody/tr[3]/td')
      element5.click
      # sleep(0.1)
      #バスケットボール選択【2】
      driver.find_element(:xpath,'//*[@id="mmaincolumn"]/div/table/tbody/tr[2]/td').click
      # sleep(0.1)
      #天王寺スポーツセンター選択
      # driver.find_element(:xpath, '//*[@id="mmaincolumn"]/div/table/tbody/tr[13]/td[1]').click

      #城東スポーツセンター選択
      driver.find_element(:xpath, '//*[@id="mmaincolumn"]/div/table/tbody/tr[21]/td[1]').click
      # sleep(0.1)

      #「次に進む」クリック
      driver.find_element(:xpath, '//*[@id="pagerbox"]/a[2]/img').click
      #「時間帯任意」クリック
      driver.find_element(:xpath, '//*[@id="mmaincolumn"]/div/table/tbody/tr/td/table/tbody/tr[1]/td/div/a/img').click
      #「抽選申し込み内容」クリック
      driver.find_element(:xpath, '//*[@id="riyoDate"]').click

      
        # ーーーーーーーーーーーーーーーーーーーーーーーーーーーーー
      
        # 変数をまとめて定義する場所

      # 今日の日付を取得
      now=Time.current
      # 2ヶ月後の月
      month=now.since(2.month).month
      # 2ヶ月後の年号
      year=now.since(2.month).year
      # while文で使用する日付の部分の初期値
      x=1
      # end_of_monthメソッドを使用するために、仮に来々月の1日の日付を作成
      one_day=Date.new(year,month,x)
      final_day=one_day.end_of_month
      
       # 2ヶ月後のデータを丸ごと格納するための配列を定義（datetime型）※別に日付だけのinteger型の配列を作っても問題ない。
      all_days=[]
      
      for x in 1..final_day.day
        # Dateモデルの新規作成メソッド 第3引数まで指定できる、。(year, month, day)
        date=Date.new(year,month,x)
        all_days.push(date)
      end
      
      satsun = []

      all_days.each do |day|
        if day.saturday? || day.sunday?
          satsun.push(day)
        end
      end

      hinichi = []

      satsun.each do |day|
        # 1日につき2回エントリーするので、ここで、あえて同じ日付を2回PUSHしてます。
        hinichi.push(day.day)
        hinichi.push(day.day)
      end


                hinichi.shuffle.each do |t|

                  xid='//*[@id="riyoDate"]/option['+t.to_s+']'
                    #「施設」選択⇨セレクタの「第一体育場1/2」選択
                    driver.find_element(:xpath, '//*[@id="shisetsu"]').click
                    driver.find_element(:xpath, '//*[@id="shisetsu"]/option[2]').click
                    # driver.find_element(:xpath, '//*[@value="271004_001_21_01_01_0000"]').click

                      driver.find_element(:xpath, xid).click
                      driver.find_element(:xpath, '//*[@id="pagerbox"]/a[2]/img').click

                      # 予約画面に遷移できないケースが2種類。1予約済みと2満員、どちらも同じTITLEのページに足踏みするので、それを利用して、each文をbreakする。
                      if driver.title == "公共施設予約システム（時間帯任意入力）"
                        # break → each文を進める。
                      else
                        driver.find_element(:xpath, '//*[@id="mmaincolumn"]/div/p[2]/a/img').click
                        # "公共施設予約システム（申込内容確認）"というタイトルのページに遷移すればOK
                        driver.find_element(:xpath, '//*[@id="popup_ok"]').click
                      end

                      driver.get "https://reserve.opas.jp/osakashi/chusen/ChusenKubunSelect.cgi"
                end
                mess= "予約しました。"+"\n"+"「確認」と打って確かめてください。"
                return mess
  end




    def baskeyoyaku_index

      #Chrome用のドライバ
      driver = Selenium::WebDriver.for :chrome
      

      #オーパスにアクセスする
      driver.get "https://reserve.opas.jp/osakashi/menu/Logout.cgi"

      # 利用者IDを入力

      element = driver.find_element(:id, 'txtRiyoshaCode')
      element.send_keys ENV["riyhoshaCode_"+"#{params["events"][0]["source"]["userId"]}"]
      # パスワードを入力
      element2 = driver.find_element(:id, 'txtPassWord')
      element2.send_keys ENV["PASSWORD_"+"#{params["events"][0]["source"]["userId"]}"]

      # 決定ボタンをクリック
      element3 = driver.find_element(:class, 'loginbtn')
      element3.click


      driver.get "https://reserve.opas.jp/osakashi/chusen/ChusenKubunSelect.cgi"

      driver.find_element(:xpath, '//*[@id="gnavi"]/ul/li[5]/a').click


      sleep(0.5)
      driver.find_element(:xpath, '//*[@id="mmaincolumn"]/div/div/div/select').click
      sleep(0.5)
      driver.find_element(:xpath, '//*[@id="mmaincolumn"]/div/div/div/select/option[4]').click
      sleep(0.5)
      driver.find_element(:xpath, '//*[@id="mmaincolumn"]/div/div/div/a/img').click


     reserved_num=driver.find_elements(:tag_name, 'tr')
     sum=reserved_num.size-1



      mess=""

      for i in 3..sum
        tr_id='//*[@id="mmaincolumn"]/div/div/table/tbody/tr['+i.to_s+']/td[4]'
        tr_id2='//*[@id="mmaincolumn"]/div/div/table/tbody/tr['+i.to_s+']/td[2]'
        
        text1=driver.find_element(:xpath, tr_id).text
        text2=driver.find_element(:xpath, tr_id2).text

        mess=mess+"\n"+text2+"\n"+text1+"\n"
      end
      return mess

    end



  end