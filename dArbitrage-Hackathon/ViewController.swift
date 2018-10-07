//
//  ViewController.swift
//  dArbitrage-Hackathon
//
//  Created by Hammad Tariq on 10/6/18.
//  Copyright © 2018 uk.co.iologics. All rights reserved.
//

import UIKit
import KyberWidget
import Alamofire
import SwiftyJSON
import MBProgressHUD

class priceTableViewCell: UITableViewCell {
    
    @IBOutlet weak var differenceLabel: UILabel!
    @IBOutlet weak var pairLabel: UILabel!
    @IBOutlet weak var oneEchangeLabel: UILabel!
    @IBOutlet weak var secondExchangeLabel: UILabel!
    @IBOutlet weak var oneExchangePrice: UILabel!
    @IBOutlet weak var secondExchangePrice: UILabel!
    @IBOutlet weak var statusLight: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        oneExchangePrice.adjustsFontSizeToFitWidth = true
        oneEchangeLabel.adjustsFontSizeToFitWidth = true
        differenceLabel.adjustsFontSizeToFitWidth = true
        pairLabel.adjustsFontSizeToFitWidth = true
        secondExchangePrice.adjustsFontSizeToFitWidth = true
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var selectedCell: IndexPath = []
    var priceArray = [[String]]()
    var kyberArray = [[String]]()
    var bancorArray = [[String]]()
    //let supportedTokens = ["ETH", "KNC", "OMG", "SNT", "ELF", "POWR", "MANA", "BAT", "REQ", "GTO", "RDN", "APPC", "ENG", "SALT", "BQX", "ADX", "AST", "RCN", "ZIL", "DAI", "LINK", "IOST", "STORM", "BBO", "COFI", "MOC", "BITX"]
    let supportedTokens = ["ETH", "KNC", "OMG", "SNT", "ELF", "POWR", "MANA", "BAT", "REQ", "GTO", "RCN", "DAI", "STORM", "BBO"]
    @IBOutlet weak var buyTokenTextField: UITextField!
    
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        getKyberPrices(completeFunc: self.getOtherPrices)
    }
    
    @IBAction func profileButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "goToProfile", sender: self)
    }
    
    func getKyberPrices(completeFunc: @escaping () -> Void) {
        showProgress()
        let todoEndpoint: String = "https://tracker.kyber.network/api/tokens/pairs"
        Alamofire.request(todoEndpoint, method: .get)
            .responseJSON { response in
                //print (response.result.isSuccess)
                if response.result.isSuccess {
                    let json : JSON = JSON(response.result.value!)
                    //print(json)
                    for element in json{
                        //print (element)
                        let eachPrice = ["\(element.1["symbol"].stringValue)", element.1["currentPrice"].stringValue]
                        self.kyberArray.append(eachPrice)
                    }
                    completeFunc()
                    
                } else {
                    print("Error: \(String(describing: response.result.error))")
                    
                }
        }
    }
    
    func getOtherPrices(){
        
        let group = DispatchGroup()
        
        for token in supportedTokens{
            group.enter()
            let urlString: String = "https://api.bancor.network/0.1/currencies/\(token)/ticker?fromCurrencyCode=ETH&displayCurrencyCode=ETH"
            Alamofire.request(urlString, method: .get)
                .responseJSON { response in
                    //print (response.result.isSuccess)
                    if response.result.isSuccess {
                        let json : JSON = JSON(response.result.value!)
                        print(json)
                        for element in json{
                            //print (element)
                            let eachPrice = [element.1["symbol"].stringValue, element.1["price"].stringValue]
                            self.bancorArray.append(eachPrice)
                        }
                        group.leave()
                    } else {
                        print("Error: \(String(describing: response.result.error))")
                        
                    }
            }
        }
        
        
        group.notify(queue: .main) {
            print("all requests done")
            self.combineMarketData()
        }
    }
    
    func combineMarketData(){
        print("combining data")
        //print(kyberArray)
        for kyberPair in kyberArray{
            if supportedTokens.contains(kyberPair[0]) {
                let searchString = "\(kyberPair[0])"
                //print(searchString)
                let result = bancorArray.filter { (dataArray:[String]) -> Bool in
                    return dataArray.filter({ (string) -> Bool in
                        return string.contains(searchString)
                    }).count > 0
                }
                
                if(!result.isEmpty){
                    //print(result)
                    for bancorPair in result{
                        //print ("bancor pair \(bancorPair)")
                        //print("Kyber pair \(kyberPair)")
                        
                        
                        let tradePair = kyberPair[0]
                        var buyExchangePrice = ""
                        var sellExchangePrice = ""
                        var buyExchangeLabel = ""
                        var sellExchangeLabel = ""
                        var percentageLabel = ""
                        let kyberPairPrice = Double(kyberPair[1])!
                        let bancorPairPrice = Double(bancorPair[1])!
                        if kyberPairPrice < bancorPairPrice {
                            
                            
                            let difference = bancorPairPrice - kyberPairPrice
                            let average = (kyberPairPrice + bancorPairPrice)/2
                            let percentageIncrease = (difference/average)*100
                            
                            buyExchangeLabel = "Kyber"
                            buyExchangePrice = String(format: "%.8f", kyberPairPrice)
                            sellExchangeLabel = "Bancor"
                            sellExchangePrice = String(format: "%.8f", bancorPairPrice)
                            percentageLabel = "\(percentageIncrease.rounded(toPlaces: 3))"
                            
                        }else {
                            
                            
                            
                            let difference = kyberPairPrice - bancorPairPrice
                            let average = (kyberPairPrice + bancorPairPrice)/2
                            let percentageIncrease = (difference/average)*100
                            buyExchangeLabel = "Bancor"
                            buyExchangePrice = String(format: "%.8f", bancorPairPrice)
                            sellExchangeLabel = "Kyber"
                            sellExchangePrice = String(format: "%.8f", kyberPairPrice)
                            percentageLabel = "\(percentageIncrease.rounded(toPlaces: 3))"
                        }
                        let eachPrice = [tradePair, percentageLabel, buyExchangeLabel, buyExchangePrice, sellExchangeLabel, sellExchangePrice]
                        priceArray.append(eachPrice)
                    }
            }
            
            }
            
        }
        self.reloadTableData()
    }
    
    //MARK:- TableView functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return priceArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "priceCell", for: indexPath) as! priceTableViewCell
        cell.pairLabel.text = "\(priceArray[indexPath.item][0])/ETH"
        cell.differenceLabel.text = "\(priceArray[indexPath.item][1])%"
        cell.oneEchangeLabel.text = priceArray[indexPath.item][2]
        cell.oneExchangePrice.text = priceArray[indexPath.item][3]
        cell.secondExchangeLabel.text = priceArray[indexPath.item][4]
        cell.secondExchangePrice.text = priceArray[indexPath.item][5]
        let priceDouble = Double(priceArray[indexPath.item][1]) ?? 1.00
        if priceDouble < 1.00 {
            cell.statusLight.image = UIImage(named: "red_light")
        }else{
            cell.statusLight.image = UIImage(named: "green_light")
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("This cell from the chat list was selected: \(indexPath.row)")
        selectedCell = indexPath
        print(priceArray[indexPath.item])
        let selectedArray = priceArray[indexPath.item]
        let defaults = UserDefaults.standard
        defaults.set(selectedArray, forKey: "selectedPair")
        
        performSegue(withIdentifier: "goToDetails", sender: self)
    }
    
    func reloadTableData(){
        priceArray = priceArray.sorted(by: { $0[1] > $1[1] })
        print(priceArray)
        MBProgressHUD.hide(for: self.view, animated: true)
        tableView.reloadData()
    }
    
    func showProgress(){
        let loadingNotification = MBProgressHUD.showAdded(to: view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Loading"
    }
    
}
extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
