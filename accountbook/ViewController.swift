

import UIKit
import Foundation
import SQLite3

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource,UIScrollViewDelegate {
    
    
    
    
    
    
    //宣告資料庫連線指標
    var db:OpaquePointer?   //存放資料庫連線的資料
    var currentItem = "💄化妝品"
    var currentType = "💰現金"
    
    //紀錄上一頁表格控制器的執行實體
    weak var myTableViewController:MyTableViewController!
    
    @IBOutlet weak var table: UITableView!
    //記錄單一資料行
    var dicRow = [String:Any?]()
    //紀錄查詢到的資料表，用陣列的形式記錄起來（新增後離線資料集）
    var tableArr =  [[String:Any?]]()
    
    @IBOutlet weak var shoppingDate: UITextField!
    @IBOutlet weak var shoppingMemo: UITextView!
    var viewFrame:CGFloat!
    
    var datePicker:UIDatePicker!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var shoppingDetail: UIView!
    
    var checkPoint:CheckPoint = .point
    var valueHasTyping:Bool = false
    var userIsInTyping:Bool = false
    var operating = Operating()
    
    //MARK: view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewFrame = self.view.frame.height
        //向通知中心註冊鍵盤彈出通知
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        //向通知中心註冊鍵盤收合通知
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let dateToolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.width, height: 40))
        dateToolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        
        dateToolBar.barStyle = UIBarStyle.blackTranslucent
        dateToolBar.tintColor = UIColor.white
        dateToolBar.backgroundColor = UIColor.black
        let memoToolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.width, height: 40))
        memoToolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        
        memoToolBar.barStyle = UIBarStyle.blackTranslucent
        memoToolBar.tintColor = UIColor.white
        memoToolBar.backgroundColor = UIColor.black
        let okBarBtn =  UIBarButtonItem(title: "確定", style: .done, target: self, action: #selector(ViewController.donePressed))
        let doneBarBtn =  UIBarButtonItem(title: "確定", style: .done, target: self, action: #selector(ViewController.donePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let selectDateLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width / 3, height: self.view.frame.size.height))
        
        selectDateLabel.font = UIFont(name: "System", size: 16)
        selectDateLabel.backgroundColor = UIColor.clear
        selectDateLabel.textColor = UIColor.white
        selectDateLabel.text = "請選擇日期"
        selectDateLabel.textAlignment = NSTextAlignment.center
        var memoToolLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width / 3, height: self.view.frame.size.height))
        memoToolLabel.font = UIFont(name: "System", size: 16)
        memoToolLabel.backgroundColor = UIColor.clear
        memoToolLabel.textColor = UIColor.white
        memoToolLabel.text = "✏️我的消費小筆記"
        memoToolLabel.textAlignment = NSTextAlignment.center
        let dateBtn = UIBarButtonItem(customView: selectDateLabel)
        let memoBtn = UIBarButtonItem(customView: memoToolLabel)
        memoToolBar.setItems([memoBtn,flexSpace,doneBarBtn], animated: true)
        
        dateToolBar.setItems([dateBtn,flexSpace,okBarBtn], animated: true)
        scroll.delegate = self
        scroll.isPagingEnabled = true
        scroll.contentSize = shoppingDetail.frame.size
        table.delegate = self
        table.dataSource = self
        shoppingItem.delegate = self
        shoppingItem.dataSource = self
        shoppingType.delegate = self
        shoppingType.dataSource = self
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.locale = NSLocale(localeIdentifier: "zh_TW") as Locale
        shoppingDate.inputView = datePicker
        shoppingDate.inputAccessoryView = dateToolBar
        shoppingMemo.inputAccessoryView = memoToolBar
        shoppingDate.text = DateFormat(selectDate: Date())
        datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        //===================資料庫相關程式====================================
        if let delegate = UIApplication.shared.delegate as? AppDelegate
        {
            //由應用程式代理的實體，取得資料庫連線
            db = delegate.db
        }
        //==================================================================
        getData()
        
        ////=======設定下拉更新元件==============
        //為表格增加更新元件
        self.table.refreshControl = UIRefreshControl()
        //設定下拉更新元件對應的value change事件，與呼叫的函式
        self.table.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        self.table.reloadData()
    }//viewDidLoad()
    
    @IBOutlet weak var display: UILabel!
    //MARK: 小數點顯示2位，第3取4捨5入
    enum CheckPoint {
        case pointZero
        case pointOne
        case pointTwo
        case pointThree
        case point
    }
    func CheckValue(_ checkValue:Double) {
        var temp = checkValue
        if (round(temp) != temp) {
            temp = checkValue * 10
            if(round(temp) != temp) {
                temp = checkValue * 100
                if(round(temp) != temp) {
                    checkPoint = .pointThree
                    
                } else {
                    checkPoint = .pointTwo }
            } else {
                checkPoint = .pointOne }
        } else {
            checkPoint = .pointZero }
    }
    
    
    var displayValue: Double{
        get{
            if(display != nil ){
                return Double(display.text!)!
            } else {
                return 0
            }
        }
        set{
            if(round(newValue) == newValue){
                display.text = String(Int(newValue))
            }
            else{
                display.text = String(newValue)
            }
            CheckValue(_: newValue)
            switch checkPoint {
            case .pointZero:
                display.text = String(Int(newValue))
            case .pointOne:
                display.text = String(format: "%.1f", (newValue))
            case .pointTwo:
                display.text = String(format: "%.2f", (newValue))
            case .pointThree:
                display.text = String(format: "%.2f", (round(newValue*100)/100))
            default:
                display.text = String(newValue)
            }
        }
    }
    
    @IBAction func pressedNum(_ sender: UIButton) {
        if let pressedNum = sender.currentTitle {
            if display.text!.count <= 8 || !userIsInTyping {
                if (pressedNum == "." && !userIsInTyping) {
                    display.text = "0."
                    userIsInTyping = true
                } else if (pressedNum == "." && display.text!.contains(".")  && userIsInTyping ) {
                    display.text = display.text
                } else if (pressedNum == "." && display.text == "0") {
                    display.text = "0."
                } else {
                    if(userIsInTyping) && display.text != "0" {
                        display.text = display.text! + pressedNum
                    }else{
                        display.text = pressedNum
                        userIsInTyping = true
                    }
                }
            }
            valueHasTyping = true
        }
    }
    
    
    struct Operating {
        var resultValue:Double = 0
        var bindingValue:Double = 0
        var bindingOperate:String = ""
        
        mutating func resulet(_ operate:String ,value secondValue:Double)->Double{
            if(bindingOperate == ""){
                bindingValue = secondValue
                bindingOperate = operate
                resultValue = secondValue
            }
            else{
                switch bindingOperate{
                case "+":
                    resultValue = bindingValue + secondValue
                case "-":
                    resultValue = bindingValue - secondValue
                case "×":
                    resultValue = bindingValue * secondValue
                case "÷":
                    resultValue = bindingValue / secondValue
                default:
                    break
                }
                bindingValue = resultValue
                bindingOperate = operate
            }
            if(operate == "="){
                bindingOperate = ""
            }
            return resultValue
        }
        
        mutating func resetBind(){
            bindingValue = 0
            bindingOperate = ""
        }
    }
    
    
    @IBAction func operate(_ sender: UIButton) {
        if let operate = sender.currentTitle{
            switch operate{
            case "+","-","×","÷","=":
                if(valueHasTyping){
                    displayValue = operating.resulet(operate, value: displayValue)
                    userIsInTyping = false
                    valueHasTyping = false
                } else{
                    operating.bindingOperate = operate
                }
            case "AC":
                displayValue = 0
                operating.resetBind()
                userIsInTyping = false
                valueHasTyping = false
            case "←":
                if display.text!.count >= 2 {
                    display.text!.remove(at: display.text!.index(before: display.text!.endIndex))
                } else {
                    displayValue = 0
                    operating.resetBind()
                    userIsInTyping = false
                    valueHasTyping = false
                }
            default:
                break
            }
        }
    }
    //MARK: - 自定函式
    //    由下拉更新元件所觸發的事件
    @objc func handleRefresh()
    {
        
        print("下拉更新")
        
        //step1.重新讀取來源資料庫的資料到離線資料集(arrTable)
        getData()
        //step2.更新表格資料
        self.table.reloadData()
        //step3.停止下拉更新元件的更新狀態
        self.table.refreshControl?.endRefreshing()
        
        
    }
    
    func getData(){
        tableArr.removeAll()
        if db != nil
        {
            
            let sql = "select time, shoppingdate,shoppingitem,shoppingamount,shoppingtype,memo from account order by time DESC"
            //將SQL指令由swift的字串，轉換成C語言字串（即字串陣列）
            let cSql = sql.cString(using: .utf8)!
            
            //宣告儲存查詢結果的變數
            var statement: OpaquePointer?
            /*準備查詢
             （第三個參數若為正數，則限定SQL指令的長度，負數則不限定SQL指定的長度，
             第四個參數為預備標誌-prepareFlag，準備給下一版使用，目前沒有作用，其預設為0，（v2版沒有這個參數）
             最後一個參數為預留參數，目前沒有作用）
             */
            
            sqlite3_prepare(db, cSql, -1, &statement, nil)
            //sqlite3_prepare_v2(db, cSql, -1, &statement, nil) -1是不限指令輸入的長度
            //如果可以讀到一筆資料，則執行迴圈
            while sqlite3_step(statement) == SQLITE_ROW
            {
                //先清空字典
                dicRow.removeAll()
                //讀取第０欄
                let time = sqlite3_column_text(statement, 0)
                //將第０欄資料由Ｃ語言字串，轉換成SWIFT字串
                let strTime = String(cString: time!)
                //將第0欄存入字典
                dicRow["time"] = strTime
                
                //讀取第０欄
                let shoppingdate = sqlite3_column_text(statement, 1)
                //將第０欄資料由Ｃ語言字串，轉換成SWIFT字串
                let strDate = String(cString: shoppingdate!)
                //將第0欄存入字典
                dicRow["shoppingdate"] = strDate
                
                //讀取第1欄
                let shoppingitem = sqlite3_column_text(statement, 2)
                //將第1欄資料由Ｃ語言字串，轉換成SWIFT字串
                let stritem = String(cString: shoppingitem!)
                //將第1欄存入字典
                dicRow["shoppingitem"] = stritem
                
                print("購買時間：\(strDate)，購買項目：\(stritem)")
                
                //讀取第2欄
                let shoppingamount = sqlite3_column_int(statement, 3)
                //將第2欄存入字典
                dicRow["shoppingamount"] = Int(shoppingamount)
                
                print("購買時間：\(strDate)，購買項目：\(stritem),購買金額:\(Int(shoppingamount))")
                
                //讀取第3欄
                let shoppingtype = sqlite3_column_text(statement, 4)
                //將第3欄資料由Ｃ語言字串，轉換成SWIFT字串
                let strtype = String(cString: shoppingtype!)
                //將第3欄存入字典
                dicRow["shoppingtype"] = strtype
                
                print("購買時間：\(strDate)，購買項目：\(stritem),購買金額:\(Int(shoppingamount)),付款方式：\(strtype)")
                
                
                //讀取第4欄
                let memo = sqlite3_column_text(statement, 5)
                let strMemo = String(cString: memo!)
                //將第4欄存入字典
                dicRow["memo"] = strMemo
                
                
                
                
                
                print("當筆字典：\(dicRow)")
                //將當筆字典存入陣列
                tableArr.append(dicRow)
               
            }// while 迴圈結尾
            print("從資料庫取得的離線資料集：\(tableArr)")
            
            //            }
            
            
            //Step5: 關閉SQL連線指令
            sqlite3_finalize(statement)
            table.reloadData()
        }
    }
    @objc func datePickerChanged(datePicker:UIDatePicker) {
        //        print(datePicker.date)
        //        shoppingDate.text = (datePicker.date as! String)
        shoppingDate.text = DateFormat(selectDate: datePicker.date)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        //收鍵盤的時間
        // UIView.animate(withDuration: 2){
        //收起鍵盤的編輯狀態
        self.view.endEditing(true)
        // }
        
    }
    //    @IBAction func editingDidBegin(_ sender: UITextField) {
    //        sender.keyboardType = .default
    //    }
    //    @IBAction func didEndOnExit(_ sender: UITextField) {
    ////        print("按下虛擬鍵盤的return鍵")
    //    }
    
    //鍵盤彈出時由通知中心呼叫的函式
    @objc func keyBoardWillShow(_ sender:Notification){
        //        print("鍵盤彈出\(sender.userInfo!)")
        //取得虛擬鍵盤的高度
        if let keyboardHeight = (sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            UIView.animate(withDuration: 0.5, delay: 0.0, animations: {(self.view.frame.origin.y = 0 - keyboardHeight)}, completion: nil)
            
            
        }
    }
    //鍵盤收合時由通知中心呼叫的函式
    @objc func keyBoardWillHide(){
        self.view.frame.origin.y = 0
    }
    @IBAction func addbutton(_ sender: UIButton)
    {
        
        if db != nil
        {
            
            var d:Date = Date()
            var time:DateFormatter = DateFormatter()
            time.dateFormat = "YYYY-MM-dd HH:mm:ss"
            var timeCurrent = time.string(from: d)
            print("===================\(time.string(from: d))")
            
            
            //準備SQL指令
            let sql = "insert into account(time, shoppingdate,shoppingitem,shoppingamount,shoppingtype,memo) values ('\(timeCurrent)','\(shoppingDate.text!)','\(currentItem)',\(display.text!),'\(currentType)','\(shoppingMemo.text!)')"
            
            print("~~~~~~~~新增指令:\(sql)")
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
                //================回寫上一頁的離線資料========================
                //Step1.新準備要新增的一本字典
                let newRow:[String:Any?] = [ "time":timeCurrent,"shoppingdate":shoppingDate.text!,"shoppingitem":"\(currentItem)","shoppingamount":display.text!,"shoppingtype":"\(currentType)","memo":shoppingMemo.text!]
                print("這邊這邊\(newRow)")
                //myTableViewController.arrTable.append(newRow)
                /*
                 //Step2.決定新字典回寫上一頁的離線資料的位置
                 for (index,item) in myTableViewController.arrTable.enumerated()
                 {
                 
                 if timeCurrent < (item["time"]! as! String)
                 {
                 myTableViewController.arrTable.insert(newRow, at: index)
                 break
                 }
                 
                 }
                 */
            }
            
            //===========================================================
            
            //製作彈出訊息視窗
            let alert = UIAlertController(title: "資料庫訊息", message: "資料已新增一筆到資料庫!", preferredStyle: .alert)
            //在彈出訊息的視窗加上一顆按鈕
            alert.addAction( UIAlertAction(title: "確定", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        /*
         //            if db != nil
         //            {
         let sql2 = "select time, shoppingdate,shoppingitem,shoppingamount,shoppingtype,memo from account order by time"
         //將SQL指令由swift的字串，轉換成C語言字串（即字串陣列）
         let cSql = sql2.cString(using: .utf8)!
         
         //宣告儲存查詢結果的變數
         var statement2: OpaquePointer?
         /*準備查詢
         （第三個參數若為正數，則限定SQL指令的長度，負數則不限定SQL指定的長度，
         第四個參數為預備標誌-prepareFlag，準備給下一版使用，目前沒有作用，其預設為0，（v2版沒有這個參數）
         最後一個參數為預留參數，目前沒有作用）
         */
         
         sqlite3_prepare_v3(db, cSql, -1, 0, &statement2, nil)
         //sqlite3_prepare_v2(db, cSql, -1, &statement, nil) -1是不限指令輸入的長度
         //如果可以讀到一筆資料，則執行迴圈
         while sqlite3_step(statement2) == SQLITE_ROW
         {
         //先清空字典
         dicRow.removeAll()
         //讀取第０欄
         let time = sqlite3_column_text(statement2, 0)
         //將第０欄資料由Ｃ語言字串，轉換成SWIFT字串
         let strTime = String(cString: time!)
         //將第0欄存入字典
         dicRow["time"] = strTime
         
         //讀取第０欄
         let shoppingdate = sqlite3_column_text(statement2, 1)
         //將第０欄資料由Ｃ語言字串，轉換成SWIFT字串
         let strDate = String(cString: shoppingdate!)
         //將第0欄存入字典
         dicRow["shoppingdate"] = strDate
         
         //讀取第1欄
         let shoppingitem = sqlite3_column_text(statement2, 2)
         //將第1欄資料由Ｃ語言字串，轉換成SWIFT字串
         let stritem = String(cString: shoppingitem!)
         //將第1欄存入字典
         dicRow["shoppingitem"] = stritem
         
         print("購買時間：\(strDate)，購買項目：\(stritem)")
         
         //讀取第2欄
         let shoppingamount = sqlite3_column_int(statement2, 3)
         //將第2欄存入字典
         dicRow["shoppingamount"] = Int(shoppingamount)
         
         print("購買時間：\(strDate)，購買項目：\(stritem),購買金額:\(Int(shoppingamount))")
         
         //讀取第3欄
         let shoppingtype = sqlite3_column_text(statement2, 4)
         //將第3欄資料由Ｃ語言字串，轉換成SWIFT字串
         let strtype = String(cString: shoppingtype!)
         //將第3欄存入字典
         dicRow["shoppingtype"] = strtype
         
         print("購買時間：\(strDate)，購買項目：\(stritem),購買金額:\(Int(shoppingamount)),付款方式：\(strtype)")
         
         
         //讀取第4欄
         let memo = sqlite3_column_text(statement2, 5)
         let strMemo = String(cString: memo!)
         
         dicRow["memo"] = strMemo
         
         
         
         
         print("當筆字典：\(dicRow)")
         //將當筆字典存入陣列
         tableArr.append(dicRow)
         }// while 迴圈結尾
         print("從資料庫取得的離線資料集：\(tableArr)")
         
         //            }
         
         
         
         //Step5: 關閉SQL連線指令
         sqlite3_finalize(statement)
         table.reloadData()
         }
         */
        displayValue = 0
        shoppingMemo.text = ""
        
        getData()
        self.table.reloadData()
        
    }
    //MARK: TableView處理
    @IBOutlet weak var shoppingItem: UITableView!
    var itemList = ["💄化妝品","🍟外食","👜服飾","💰收入","🍆食品","🚦交通罰單","🍩零食","🍺飲料","🍱外賣","💡日用品","📠辦公用品","🔑房租","🏠房屋貸款","🚌巴士","🚕計程車","🎮娛樂","🛋家具","📷家電","🐶寵物用品","🎁禮物","💈理髮","📱電話費","🖥上網費","📺有線電視費","🔌電費","💦水費","🔥煤氣費","💊醫療","⛽️汽油","🅿️停車費","🚗汽車","🎫收費道路費","📕教育","✈️旅行","💼商務旅行","💪健身","🍼寶寶","📑保險費","","","","",]
    @IBOutlet weak var shoppingType: UITableView!
    
    var typeList = ["💰現金","💳信用卡","🏧轉帳","💸其他"]
    
    func DateFormat(selectDate:Date)->String {
        //             selectDate = Date()
        var date = DateFormatter()
        date.dateFormat = "YYYYMMdd"
        //            print(date.string(from: selectDate))
        return date.string(from: selectDate)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        switch tableView {
        case shoppingItem:
            return itemList.count
        case shoppingType:
            return typeList.count
        case table:
            
            return  3
        default:
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == shoppingItem
        {
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "ItemCell")
            cell.textLabel!.text = "\(itemList[indexPath.row])"
            return cell
        } else if tableView == shoppingType {
            let cell: UITableViewCell =  UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "TypeCell")
            
            cell.textLabel!.text = "\(typeList[indexPath.row])"
            return cell
        } else {
            
            //////////////////////////
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "accountlistCell", for: indexPath) as! accountlistCell  //必須先轉型才點得到下面的
            
            var currDic = tableArr[indexPath.row]
            
            print("currDic目前的數值是～～～～～～\(currDic)")
            
            //取得儲存格上顯示的資料
            
            
            cell.lblItem2.text = currDic["shoppingitem"] as? String
            cell.lblDate2.text = currDic["shoppingdate"] as? String
            
            cell.lblAmount2.text = "\(currDic["shoppingamount"] as! Int)"
            /*
             let cell: UITableViewCell =  UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "accountlistCell")
             
             cell.textLabel!.text = "\(tableArr[indexPath.row])"
             */
            return cell
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // print("第\(indexPath.row)列\(tableViewList[indexPath.row])被點選 ")
        if tableView == shoppingItem {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            currentItem = itemList[indexPath.row]
            //            print("@@@@@@@@@@@@@%%%%%\(currentItem)")
        }else if tableView == shoppingType{
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            currentType = typeList[indexPath.row]
            //            print("###########\(currentType)")
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @objc func donePressed(sender: UIBarButtonItem) {
        
        shoppingDate.resignFirstResponder()
        shoppingMemo.resignFirstResponder()
        
    }
    
    
}//UIViewController

