//
//  ViewController.swift
//  dArbitrage-Hackathon
//
//  Created by Gaurav Shukla on 10/6/18.
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
    override func awakeFromNib() {
        super.awakeFromNib()
        oneExchangePrice.adjustsFontSizeToFitWidth = true
        pairLabel.adjustsFontSizeToFitWidth = true
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    fileprivate var coordinator: KWCoordinator?
    var priceArray = [[String]]()
    var kyberArray = [[String]]()
    var binanceArray = [[String]]()
    @IBOutlet weak var buyTokenTextField: UITextField!
    
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        getKyberPrices(completeFunc: self.getOtherPrices)
    }
    
    @IBAction func buyButtonPressed(_ sender: Any) {
        buyTokens(receiveToken: "ETH", receiveAmount: 0.001604, network: KWEnvironment.ropsten, signer: "", commissionId: "", pinnedTokens: "ETH_KNC_DAI")
    }
    
    func payTokens(receiveAddr : String, receiveToken : String, receiveAmount : Double, network : KWEnvironment,
                   signer : String, commissionId : String, productName : String, productAvatar : String, productAvatarImage : UIImage){
        do {
            self.coordinator = try KWPayCoordinator(
                baseViewController: self,
                receiveAddr : receiveAddr,
                receiveToken: receiveToken,
                receiveAmount: receiveAmount,
                network: network, // ETH network, default ropsten
                signer: signer,
                commissionId: commissionId,
                productName: productName,
                productAvatar: productAvatar,
                productAvatarImage: productAvatarImage
            )
        } catch {}
    }
    
    func swapTokens(network : KWEnvironment,
                    signer : String, commissionId : String){
        do {
            self.coordinator = try KWSwapCoordinator(
                baseViewController: self,
                network: network, // ETH network, default ropsten
                signer: signer,
                commissionId: commissionId
            )
        } catch {}
    }
    
    func buyTokens(receiveToken : String, receiveAmount : Double, network : KWEnvironment,
                   signer : String, commissionId : String, pinnedTokens : String){
        do {
            self.coordinator = try KWBuyCoordinator(
                baseViewController: self,
                receiveToken: receiveToken,
                receiveAmount: receiveAmount,
                network: network, // ETH network, default ropsten
                signer: nil,
                commissionId: nil
            )
            // set delegate to receive transaction data
            self.coordinator?.delegate = self as? KWCoordinatorDelegate
            
            // show the widget
            self.coordinator?.start()
        } catch {}
    }
    
    func getKyberPrices(completeFunc: @escaping () -> Void) {
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
        getBinancePrices(completeFunc: combineMarketData)
    }
    
    func getBinancePrices(completeFunc: @escaping () -> Void) {
        print("getting Binance data")
        showProgress()
        let todoEndpoint: String = "https://api.binance.com/api/v3/ticker/price"
        Alamofire.request(todoEndpoint, method: .get)
            .responseJSON { response in
                //print (response.result.isSuccess)
                if response.result.isSuccess {
                    let json : JSON = JSON(response.result.value!)
                    //print(json)
                    for element in json{
                        //print (element)
                        let eachPrice = [element.1["symbol"].stringValue, element.1["price"].stringValue]
                        self.binanceArray.append(eachPrice)
                    }
                    completeFunc()
                } else {
                    print("Error: \(String(describing: response.result.error))")
                    
                }
        }
    }
    
    func combineMarketData(){
        print("combining data")
        //print(kyberArray)
        for kyberPair in kyberArray{
            let searchString = "\(kyberPair[0])ETH"
            //print(searchString)
            let result = binanceArray.filter { (dataArray:[String]) -> Bool in
                return dataArray.filter({ (string) -> Bool in
                    return string.contains(searchString)
                }).count > 0
            }
            
            if(!result.isEmpty){
                //print(result)
                for binancePair in result{
                    print ("Binance pair \(binancePair)")
                    print("Kyber pair \(kyberPair)")
                    var kyberPairPrice = Double(kyberPair[1])!
                    kyberPairPrice = kyberPairPrice.rounded(toPlaces: 8)
                    let KyperPriceStr = String(format:"%f", kyberPairPrice)
                    let eachPrice = [kyberPair[0], kyberPair[1], binancePair[0], binancePair[1]]
                    priceArray.append(eachPrice)
                }
            }
            
        }
        self.reloadTableData()
    }
    
    func coordinatorDidCancel() {
        // TODO: handle user cancellation
    }
    
    func coordinatorDidFailed(with error: KWError) {
        // TODO: handle errors
    }
    
    func coordinatorDidBroadcastTransaction(with txHash: String) {
        // TODO: poll blockchain to check for transaction's status and validity
    }
    
    //MARK:- TableView functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return priceArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "priceCell", for: indexPath) as! priceTableViewCell
        cell.pairLabel.text = "\(priceArray[indexPath.item][0])/ETH"
        cell.oneExchangePrice.text = priceArray[indexPath.item][1]
        cell.secondExchangePrice.text = priceArray[indexPath.item][3]
        print(priceArray[indexPath.item])
        //cell.textLabel?.textColor = UIColor.flatWhite
        return cell
    }
    
    func reloadTableData(){
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
