//
//  ViewController.swift
//  Valute
//
//  Created by Aleksandar Vacić on 1.4.16..
//  Copyright © 2016. iOS Akademija. All rights reserved.
//

import UIKit

enum CurrencyPostion {
    case Source
    case Target
}

enum UserDefaultsKey: String {
    case SourceCurrencyCode
    case TargetCurrencyCode
}

class ViewController: UIViewController, CurrencyPickerDelegate {

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var leftcurrencyButton: UIButton!
    @IBOutlet weak var rightCurrencyButton: UIButton!
    
    @IBOutlet weak var leftCurrencyField: UITextField!
    @IBOutlet weak var rightCurrencyField: UITextField!
    
    @IBOutlet weak var decimalButton: UIButton!
    
    
    // Keypad ----- Interface ------ Start
    
    var originalButtonColor: UIColor?

    @IBAction func buttonTouched(sender: UIButton) {
        originalButtonColor = sender.backgroundColor
        
        var r: CGFloat = 1
        var g: CGFloat = 1
        var b: CGFloat = 1
        var a: CGFloat = 0.2
        
        let getSuccess = sender.backgroundColor?.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        guard let success = getSuccess else { return }
        if !success { return }
        
        sender.backgroundColor = UIColor(red: r, green: g, blue: b, alpha: a*2.0)
    }
    
    @IBAction func operatorsButtonTapped(sender: UIButton) {
        restoreBackgroundColorForButton(sender)
        
        var isEquals = false
        let caption = sender.titleForState(.Normal)!
        
        switch caption {
        case "+":
            activeOperation = .Add
        case "-":
            activeOperation = .Subtract
        case "x":
            activeOperation = .Multiply
        case "=":
            isEquals = true
        default:
            activeOperation = .None
        }
        
        if (isEquals) {
            secondOperand = Double(self.sourceTextField.text!)!
            
            var rez = firstOperand
            switch activeOperation {
            case .Add:
                rez += secondOperand
            case .Subtract:
                rez -= secondOperand
            case .Multiply:
                rez *= secondOperand
            default:
                break
            }
            self.sourceTextField.text = String(rez)
            
            updateConversionPanel()
            
        } else if activeOperation != .None {
            firstOperand = Double(self.sourceTextField.text!)!
            self.sourceTextField.text = nil
            
            updateConversionPanel()
        }
    }
    
    @IBAction func numberButtonTapped(sender: UIButton) {
        restoreBackgroundColorForButton(sender)
        
        self.sourceTextField.text = self.sourceTextField.text! + sender.titleForState(.Normal)!
        updateConversionPanel()
    }
    
    @IBAction func decimalButtonTapped(sender: UIButton) {
        restoreBackgroundColorForButton(sender)
        
        guard let str = self.sourceTextField.text else { return }
        guard let decimalSign = sender.titleForState(.Normal) else { return }
        
        if str.containsString(decimalSign) { return }
        
        self.sourceTextField.text = str + decimalSign

    }
    
    @IBAction func deleteButtonTapped(sender: UIButton) {
        restoreBackgroundColorForButton(sender)
        
        guard let str = self.sourceTextField.text else { return }
        guard str.characters.count > 0 else { return }
        var chars = str.characters
        chars.removeLast()
        self.sourceTextField.text = String(chars)
        
        updateConversionPanel()
    }
    
    @IBAction func buttonTouchCancelled(sender: UIButton) {
        restoreBackgroundColorForButton(sender)
    }
    
    func restoreBackgroundColorForButton(sender: UIButton) {
        if let bgColor = originalButtonColor {
            sender.backgroundColor = bgColor
        }
        originalButtonColor = nil
    }
    
    // Keypad ------- Interface ----- End
    
    // Keypad ------- Operations ---- Start
    
    enum ArithmeticOperations {
        case None
        case Add, Subtract, Multiply
        case Equals
    }
    
    var firstOperand = 0.0
    var secondOperand = 0.0
    var activeOperation = ArithmeticOperations.None
    
    // Keypad ----- Operations ------ End
    
    var currencyRate: Double? {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.updateConversionPanel()
            }
        }
    }
    
    var numberFormatter: NSNumberFormatter!
    
    var sourceTextField: UITextField {
        return leftCurrencyField
    }
    
    var targetTextField: UITextField {
        return rightCurrencyField
    }
    
    var sourceCurrencyButton: UIButton {
        return leftcurrencyButton
    }
    
    var targetCurrencyButton: UIButton {
        return rightCurrencyButton
    }
    
    var sourceCurrency: String!
    var targetCurrency: String!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        fetchConversionRate()
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        setupInitialCurrencyCode()
        
        numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = .DecimalStyle
        numberFormatter.maximumFractionDigits = 2
        
        self.navigationItem.title = "Currency Controller"
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "?", style: .Done, target: self, action: #selector(ViewController.aboutTappedButton(_:)))
        
        setupCurrencyButton(self.leftcurrencyButton, withCurrencyCode: self.sourceCurrency)
        setupCurrencyButton(self.rightCurrencyButton, withCurrencyCode: self.targetCurrency)
        
        self.sourceTextField.text = nil
        self.targetTextField.text = nil
        
        setupDecimalButton()
	
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        
    }
    
    func setupInitialCurrencyCode() {
        let def = NSUserDefaults.standardUserDefaults()
        
        if let str = def.stringForKey(UserDefaultsKey.SourceCurrencyCode.rawValue) {
            self.sourceCurrency = str
        } else {
            self.sourceCurrency = "EUR"
        }
        
        if let str = def.stringForKey(UserDefaultsKey.TargetCurrencyCode.rawValue) {
            self.targetCurrency = str
        } else {
            self.targetCurrency = "USD"
        }
        
    }
    
    func saveCurrencyCodes() {
        let def = NSUserDefaults.standardUserDefaults()
        def.setObject(self.sourceCurrency, forKey: UserDefaultsKey.SourceCurrencyCode.rawValue)
        def.setObject(self.targetCurrency, forKey: UserDefaultsKey.TargetCurrencyCode.rawValue)
    
    }
    
    func fetchConversionRate() {
        
        let manager = CurrencyManager.sharedManager
        manager.rateForCurrency(sourceCurrency, versusCurrencyCode: targetCurrency) { (returnedSourceCC, returnedTargetCC, rate, error) in
            
            if self.sourceCurrency != returnedSourceCC { return }
            if self.targetCurrency != returnedTargetCC { return }
            
            if let err = error {
                dispatch_async(dispatch_get_main_queue(), {
                    let ac = UIAlertController(title: String(err), message: nil, preferredStyle: .Alert)
                    let ok = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    ac.addAction(ok)
                    self.presentViewController(ac, animated: true, completion: nil)
                })
            }
            
            guard let localRate = rate else { return }
            
            self.currencyRate = localRate
        }
    }
    
    func convertAmount(amount: Double) -> Double? {
        guard let rate = currencyRate else { return nil }
        return rate * amount
    }
    
    func updateConversionPanel() {
        guard self.sourceTextField.text != nil else {
            self.sourceTextField.text  = nil
            return
        }
        
        guard let sourceValue = Double(self.sourceTextField.text!) else {
            self.targetTextField.text = nil
            return
        }
        
        guard let result = convertAmount(sourceValue) else {
            self.sourceTextField.text = nil
            return
        }
        
        self.targetTextField.text = self.numberFormatter.stringFromNumber(result)
    }
    
   	func setupDecimalButton() {
        
        guard let decimalSign = NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) else { return }
        
        let decimalCharacter = decimalSign as! String
        
        if decimalCharacter.characters.count == 0 { return }
        
        self.decimalButton.setTitle(decimalCharacter, forState: .Normal)
        
    }

    
    func currencyPickerController(picker: CurrencyPicker, didSelectCurrency currencyCode: String, forPosition pos: CurrencyPostion) {
        
        saveCurrencyCodes()
        
        switch pos {
        case .Target:
            self.sourceCurrency = currencyCode
        case .Source:
            self.targetCurrency = currencyCode
        }
        
        setupCurrencyButton(sourceCurrencyButton, withCurrencyCode: self.sourceCurrency)
        setupCurrencyButton(targetCurrencyButton, withCurrencyCode: self.targetCurrency)
        
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
    func aboutTappedButton(sender: UIBarButtonItem) {
        
    }
    
    func setupCurrencyButton(btn: UIButton, withCurrencyCode currencyCode: String) {
        btn.setTitle(currencyCode, forState: .Normal)
        
        if let contryCode = contryCodeForCurrencyCode(currencyCode) {
            btn.setImage(UIImage.init(named: contryCode), forState: .Normal)
        } else {
            btn.setImage(nil, forState: .Normal)
        }
    }

    @IBAction func curencyButton(sender: UIButton) {
        let vc = CurrencyPicker(nibName: nil, bundle: nil)
        vc.delegate = self
        
        if leftcurrencyButton == sender {
            vc.originPosition = .Target
        } else {
            vc.originPosition = .Source
        }
        
        self.showViewController(vc, sender: self)
    }
}

extension UIViewController {
        
    func contryCodeForCurrencyCode(currencyCode: String) -> String? {
       
        switch currencyCode {
        case "USD":
            return "us"
        case "EUR":
            return "eu"
        case "GBP":
                return "gb"
        case "EUR":
            return "eu"
        case "AUD":
            return "au"
        default:
            break
        }
        
        for contryCode in NSLocale.ISOCountryCodes() {
            let localeIdentifier = NSLocale.localeIdentifierFromComponents([NSLocaleCountryCode: contryCode])
            let locale = NSLocale(localeIdentifier: localeIdentifier)
                
            if let cc = locale.objectForKey(NSLocaleCurrencyCode) {
                    
                if (cc as! String == currencyCode) {
                    return contryCode.lowercaseString
                        
                }
                    
            }
            
        }
            
        return nil
            
    }
        
}