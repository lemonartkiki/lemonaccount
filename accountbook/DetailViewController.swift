//
//  DetailViewController.swift
//  accountbook
//
//  Created by lemonart on 2018/12/11.
//  Copyright © 2018 Lemon. All rights reserved.
//

import UIKit
import SQLite3

class DetailViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate
{
    var datePicker:UIDatePicker!
    var currentDataTime:String!
    @IBOutlet weak var textDate: UITextField!
    
    @IBOutlet weak var textItem: UITextField!
    
    @IBOutlet weak var textAmount: UITextField!
    
    @IBOutlet weak var textType: UITextField!
    
    @IBOutlet weak var textMemo: UITextField!
    
    
    
    
    //宣告資料庫連線指標
    var db:OpaquePointer?   //存放資料庫連線的資料
    
    
    //紀錄上一頁表格控制器的執行實體
    weak var myTableViewController:MyTableViewController!
    
    //輸入時才會推入的PickerView
    var pkvItem:UIPickerView!
    var pkvType:UIPickerView!
    //PickerView的資料來源陣列
    let arrItem =  ["💄化妝品","🍟外食","👜服飾","💰收入","🍆食品","🚦交通罰單","🍩零食","🍺飲料","🍱外賣","💡日用品","📠辦公用品","🔑房租","🏠房屋貸款","🚌巴士","🚕計程車","🎮娛樂","🛋家具","📷家電","🐶寵物用品","🎁禮物","💈理髮","📱電話費","🖥上網費","📺有線電視費","🔌電費","💦水費","🔥煤氣費","💊醫療","⛽️汽油","🅿️停車費","🚗汽車","🎫收費道路費","📕教育","✈️旅行","💼商務旅行","💪健身","🍼寶寶","📑保險費"]
    let arrType = ["💰現金","💳信用卡","🏧轉帳","💸其他"]
    //記錄目前輸入元件的Ｙ軸底緣位置
    var currentObjectBottonYPosition:CGFloat = 0
    
    //MARK: Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //===================資料庫相關程式====================================
        if let delegate = UIApplication.shared.delegate as? AppDelegate
        {
            //由應用程式代理的實體，取得資料庫連線
            db = delegate.db
        }
        //==================================================================
        
        //向通知中心註冊鍵盤彈出通知
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        //向通知中心註冊鍵盤收合通知 //自訂函式沒有參數所以打函式名稱就好
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        //從上一頁的離線資料集，取得當筆被點選過來的字典
        var currentData = [String:Any?]()
        
        
        currentData = myTableViewController.arrTable[myTableViewController.currentRow]
        print("目前在第\([myTableViewController.currentRow])筆資料")
        //        print("0000000000000000\(currentData)")
        currentDataTime = myTableViewController.arrTable[myTableViewController.currentRow]["time"]! as! String
        //        currentDataTime = (currentData["time"] as? String)!
        print("TIME~~~~~~\(currentDataTime)")
        //顯示當筆資料在界面上
        textDate.text = currentData["shoppingdate"] as? String
        
        textItem.text = currentData["shoppingitem"] as?String
        textAmount.text = "\(currentData["shoppingamount"] as! Int)"
        textType.text = currentData["shoppingtype"] as? String
        textMemo.text = currentData["memo"] as? String
        //初始化購買項目的輸入滾輪
        pkvItem = UIPickerView()
        pkvItem.tag = 2
        //初始化消費方式的輸入滾輪
        pkvType = UIPickerView()
        pkvType.tag = 4
        //指定購買項目與消費方式的“代理人”
        pkvItem.dataSource = self
        pkvItem.delegate = self
        pkvType.dataSource = self
        pkvType.delegate = self
        
        //指定輸入購買項目與消費方式時使用對應的滾輪來選擇資料（不使用預設鍵盤）
        textItem.inputView = pkvItem
        textType.inputView = pkvType
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.locale = NSLocale(localeIdentifier: "zh_TW") as Locale
        textDate.inputView = datePicker
        datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        
    }
    // MARK: - 自訂函式
    //鍵盤彈出時，由通知中心呼叫的函式
    @objc func keyBoardWillShow(_ sender:Notification)
    {
        //        print("鍵盤彈出：\(sender.userInfo!)")
        //取得虛擬鍵盤的高度
        if let keyBoardHeight = (sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height{
            //            print("鍵盤高度：\(keyBoardHeight)")
            //計算可視高度 ＝ 底面view的總高度 － 鍵盤的高度
            let visiableHeight = self.view.frame.height - keyBoardHeight
            //如果“y軸底元高度“比”可視高度”還高，表示輸入元件被遮住
            if currentObjectBottonYPosition > visiableHeight
            {
                //移動y軸底緣位置與可是高度之間的差值
                self.view.frame.origin.y = 0 - (currentObjectBottonYPosition - visiableHeight)
            }
        }
    }
    //鍵盤收合時，由通知中心呼叫的函式
    @objc func keyBoardWillHide()
    {
        //        print("鍵盤收合")
        //將底view的y軸座標拉回原點
        self.view.frame.origin.y = 0
    }
    func DateFormat(selectDate:Date)->String {
        //             selectDate = Date()
        var date = DateFormatter()
        date.dateFormat = "YYYYMMdd"
        //            print(date.string(from: selectDate))
        return date.string(from: selectDate)
    }
    
    // MARK: - 自訂手勢
    //觸碰開始
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        //收起鍵盤的編輯狀態
        self.view.endEditing(true)
    }
    
    
    //日期picker
    @objc func datePickerChanged(datePicker:UIDatePicker) {
        //        print(datePicker.date)
        //        shoppingDate.text = (datePicker.date as! String)
        textDate.text = DateFormat(selectDate: datePicker.date)
    }
    
    
    //MAEK: - Target Action
    //按下虛擬鍵盤的事件，不需執行任何城市，即可在按下return鍵時，收起鍵盤
    @IBAction func didEndOnExit(_ sender: UITextField)
    {
        //        print("按下虛擬鍵盤的return鍵")
    }
    
    @IBAction func editDidBegin(_ sender: UITextField)
    {
        //        print("開始編輯！")
        //紀錄目前輸入元件的y軸底緣位置
        currentObjectBottonYPosition = sender.frame.origin.y + sender.frame.size.height
        
        switch sender.tag
        {
        case 3: //更換電話的輸入鍵盤
            sender.keyboardType = .phonePad
        default:
            sender.keyboardType = .default
        }
        
    }
    
    
    
    // MARK: - 按鈕群
    
    //更新資料按鈕
    
    @IBAction func 更新資料(_ sender: UIButton)
    {
        if db != nil
        {
            var d:Date = Date()
            var time:DateFormatter = DateFormatter()
            time.dateFormat = "YYYY-MM-dd HH:mm:ss"
            var timeCurrent = time.string(from: d)
            print("===================\(time.string(from: d))")
            
            //準備SQL指令
            let sql = "update account set shoppingdate = \(textDate.text!),shoppingitem = '\(textItem.text!)',shoppingamount = \(textAmount.text!),shoppingtype = '\(textType.text!)',memo = '\(textMemo.text!)' where time = '\(currentDataTime!)'; "
            print("~~~~~~~~更新指令:\(sql)")
            //將ＳＱＬ指令轉成Ｃ語言字串
            let cSQL = sql.cString(using: .utf8)
            //宣告儲存指令結果的指令
            var statement:OpaquePointer?
            /*
             Step1:準備查詢
             （第三個參數若為正數，則限定SQL指令的長度，負數則不限定SQL指定的長度，
             第四個參數為預備標誌-prepareFlag，準備給下一版使用，目前沒有作用，其預設為0，（v2版沒有這個參數）
             最後一個參數為預留參數，目前沒有作用）
             */
            sqlite3_prepare(db, cSQL, -1, &statement, nil)
            //Step2:準備圖檔資訊
            /*
             Step3:綁定更新指令？所在的圖檔
             第二個參數描述ＳＱＬ指令中“？“所在的位置（注意：此位置從１起算）
             第三個參數為檔案位元資訊，
             第四個參數為檔案長度。
             */
            
            //Step4:準備執行ＳＱＬ指令
            if sqlite3_step(statement) == SQLITE_DONE
            {
                print("~~~~~~~~~~~~~test~~~~~~~~~~~~~~~~~~~")
                //================回寫上一頁的離線資料========================
                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingdate"] = textDate.text!
                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingitem"] = textItem.text
                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingamount"] = Int(textAmount.text!)
                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingtype"] = textType.text
                myTableViewController.arrTable[myTableViewController.currentRow]["memo"] = textMemo.text
                
                print("$$$$$$$$$$$$\(textAmount.text)")
                
                //===========================================================
                
                //製作彈出訊息視窗
                let alert = UIAlertController(title: "資料庫訊息", message: "資料已更新到資料庫!", preferredStyle: .alert)
                //在彈出訊息的視窗加上一顆按鈕
                alert.addAction( UIAlertAction(title: "確定", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            }
            //Step5: 關閉SQL連線指令
            sqlite3_finalize(statement)
            
            
        }
    }
    
    //MARK: - UIPickerViewD
    //    {
    //        if db != nil
    //        {
    //
    //            //準備SQL指令
    //            let sql = "update account set shoppingitem = '\(textItem.text!)',shoppingamount = '\(textAmount.text!)',shoppingtype = '\(textType.text!)',memo = '\(textMemo.text!)' where shoppingdate = '\(textDate.text!)'"
    //            print("~~~~~~~~更新指令:\(sql)")
    //            //將ＳＱＬ指令轉成Ｃ語言字串
    //            let cSQL = sql.cString(using: .utf8)
    //            //宣告儲存指令結果的指令
    //            var statement:OpaquePointer?
    //            /*
    //             Step1:準備查詢
    //             （第三個參數若為正數，則限定SQL指令的長度，負數則不限定SQL指定的長度，
    //             第四個參數為預備標誌-prepareFlag，準備給下一版使用，目前沒有作用，其預設為0，（v2版沒有這個參數）
    //             最後一個參數為預留參數，目前沒有作用）
    //             */
    //            sqlite3_prepare_v3(db, cSQL, -1, 0, &statement, nil)
    //            //Step2:準備圖檔資訊
    //            /*
    //             Step3:綁定更新指令？所在的圖檔
    //             第二個參數描述ＳＱＬ指令中“？“所在的位置（注意：此位置從１起算）
    //             第三個參數為檔案位元資訊，
    //             第四個參數為檔案長度。
    //             */
    //
    //            //Step4:準備執行ＳＱＬ指令
    //            if sqlite3_step(statement) == SQLITE_DONE
    //            {
    //                //================回寫上一頁的離線資料========================
    //                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingdate "] = textDate.text
    //                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingitem"] = textItem.text
    //                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingamount"] = textAmount.text
    //                myTableViewController.arrTable[myTableViewController.currentRow]["shoppingtype"] = textType.text
    //                myTableViewController.arrTable[myTableViewController.currentRow]["memo"] = textMemo.text
    //
    //
    //
    //                //===========================================================
    //
    //                //製作彈出訊息視窗
    //                let alert = UIAlertController(title: "資料庫訊息", message: "資料已更新到資料庫!", preferredStyle: .alert)
    //                //在彈出訊息的視窗加上一顆按鈕
    //                alert.addAction( UIAlertAction(title: "確定", style: .default, handler: nil))
    //                self.present(alert, animated: true, completion: nil)
    //
    //            }
    //            //Step5: 關閉SQL連線指令
    //            sqlite3_finalize(statement)
    //
    //
    //        }
    //    }
    
    //MARK: - UIPickerViewDataSource
    //單一滾輪有幾段(段為Component）
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    //每一段的滾輪有幾筆資料
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        if pickerView.tag == 2//購買項目滾輪
        {
            return arrItem.count
        }
        else if pickerView.tag == 4 //消費方式滾輪
        {
            return arrType.count
        }
        return arrType.count
        
    }
    //MARK:- UIPickerViewDelegate
    //提供PickerView每一段滾輪的每一列文字
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        if pickerView.tag == 2  //購買項目的滾輪
        {
            return arrItem[row]
        }
        else if pickerView.tag == 4 //消費方式的滾輪
        {
            return arrType[row]
        }
        return arrType[row]
    }
    //當選定滾輪的特定資料列時
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        print("滾輪被選定")
        switch pickerView.tag
        {
        case 2: //購買項目文字輸入框，更動為對應滾輪的文字
            textItem.text = arrItem[row]
            
        default:
            textType.text = arrType[row]
        }
    }
    
    
}
