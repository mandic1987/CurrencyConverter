//
//  CurrencyManager.swift
//  Valute
//
//  Created by apple on 4/19/16.
//  Copyright © 2016 iOS Akademija. All rights reserved.
//

import Foundation

enum CurrencyManagerError: ErrorType {
    case InvalidResponse
    case MissingRate(forCurrencyCode: String)
    case NetworkError(error: NSError)
    
    var title: String? {
        switch self {
        case .MissingRate:
            return "Missing Rate"
        case .InvalidResponse:
            return nil
        case .NetworkError:
            return "Internet Connection Issue"
        }
    }
    
    var message: String? {
        switch self {
        case .MissingRate(let cc):
            return "Currency rate for \(cc) is not available at the moment"
        case .InvalidResponse:
            return "Attempt to acquire currency rate was unsuccessful. Please try again later"
        case .NetworkError(let realError):
            return realError.localizedDescription
        }
    }
}

class CurrencyManager {
    
    private var baseCurrency: String = "EUR"
    private var rates = [String: Double]()
    private let yahooNumberFormatter = NSNumberFormatter()
    
    static let sharedManager = CurrencyManager()
    
    private init() {
        rates[baseCurrency] = 1.0
        yahooNumberFormatter.locale = NSLocale(localeIdentifier: "en_US")
        restoreRates()
    }
    
    private var baseURL = "https://download.finance.yahoo.com/d/quotes.csv?f=sb&s="
    
    private func singleConversionURL(sourceCurrency: String, targetCurrency: String) -> NSURL {
        var s = baseURL
        var niz : [String] = []
        
        if sourceCurrency != baseCurrency {
            niz.append(baseCurrency + sourceCurrency + "=X")
        }
        
        if targetCurrency != baseCurrency {
            niz.append(baseCurrency + targetCurrency + "=X")
        }
        
        s += niz.joinWithSeparator(",")
            
        return NSURL(string: s)!
    }
    
    private func saveRates() {
        guard let path = storageFileURL?.path else {
            print("Can't save rates, target file URL is invalid.")
            return
        }
        NSKeyedArchiver.archiveRootObject(self.rates, toFile: path)
    }
    
    private func restoreRates() {
        
        guard let path = storageFileURL?.path else {
            print("Can't restore rates, source file URL is invalid.")
            return
        }
        
        if let restoredRates = NSKeyedUnarchiver.unarchiveObjectWithFile(path) {
            self.rates = restoredRates as! Dictionary<String,Double>
        }
    }
    
    private var storageFileURL: NSURL? {
        let fm = NSFileManager.defaultManager()
        
        guard let folderURL = fm.applicationSupportURL else {return nil}
        guard fm.lookupOrCreateDirectoryAtFileURL(folderURL) else {return nil}
        
        let fileURL = folderURL.URLByAppendingPathComponent("currency.rates")
    
        return fileURL
    }
    
    func rateForCurrency(sourceCC: String, versusCurrencyCode targetCC: String, completionHandler: (returnedSourceCC: String, returnedTargetCC: String, rate: Double?, error: CurrencyManagerError?) -> Void ) {
        
        do {
            
            let rate = try self.calculateRate(forCurrency: sourceCC, versusCurrency: targetCC)
            completionHandler(returnedSourceCC: sourceCC, returnedTargetCC: targetCC, rate: rate, error: nil)
            
            return
            
        } catch {
            
        }
        
        // treba proveriti da nije nil
        let url = singleConversionURL(sourceCC, targetCurrency: targetCC)
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url) { (data, rasponse, error) in
            
            if error != nil {
                completionHandler(returnedSourceCC: sourceCC, returnedTargetCC: targetCC, rate: nil, error: CurrencyManagerError.NetworkError(error: error!))
                return
            }
            
            guard let d = data else {
                completionHandler(returnedSourceCC: sourceCC, returnedTargetCC: targetCC, rate: nil, error: CurrencyManagerError.InvalidResponse)
                return
            }
            guard let res = String(data: d, encoding: NSUTF8StringEncoding) else {
                completionHandler(returnedSourceCC: sourceCC, returnedTargetCC: targetCC, rate: nil, error: error as? CurrencyManagerError)
                return
            }
           
            if res.characters.count == 0 {
                completionHandler(returnedSourceCC: sourceCC, returnedTargetCC: targetCC, rate: nil, error: error as? CurrencyManagerError)
                return
            }
            
            let lines = res.componentsSeparatedByString("\n")
            
            for line in lines {
                guard line.characters.count > 0 else { continue }
                
                let lineParts = line.componentsSeparatedByString(",")
                var rate: Double?
                var currencyCode: String?
                
                guard lineParts.count == 2 else {
                    print("To many (or too few) parts after splitting this line '\(line)' with ','")
                    continue
                }
                
                if let currPart = lineParts.first {
                    currencyCode = currPart.stringByReplacingOccurrencesOfString("\"", withString: "").stringByReplacingOccurrencesOfString("=X", withString: "").stringByReplacingOccurrencesOfString(self.baseCurrency, withString: "")
                }
                
                if let ratePart = lineParts.last {
                    rate = self.yahooNumberFormatter.numberFromString(ratePart)?.doubleValue
                }
                
                guard let safeRate = rate else {
                    print("Could not extract rate from line: \(line)")
                    continue
                }
                
                guard let safeCC = currencyCode else {
                    print("Could not extract currency code from line: \(line)")
                    continue
                }
                
                self.rates[safeCC] = safeRate
            }
            
            do {
                
                let rate = try self.calculateRate(forCurrency: sourceCC, versusCurrency: targetCC)
                completionHandler(returnedSourceCC: sourceCC, returnedTargetCC: targetCC, rate: rate, error: nil)
            
            } catch let rateError {
                
                completionHandler(returnedSourceCC: sourceCC, returnedTargetCC: targetCC, rate: nil, error: rateError as? CurrencyManagerError)
                
            }
            
            self.saveRates()
            
        }
        
        task.resume()
        
    }
    
    private func calculateRate(forCurrency sourceCC: String, versusCurrency targetCC: String) throws -> Double {
        
        guard let sourceRate = self.rates[sourceCC] else {
            throw CurrencyManagerError.MissingRate(forCurrencyCode: sourceCC)
        }
        
        guard let targetRate = self.rates[targetCC] else {
            throw CurrencyManagerError.MissingRate(forCurrencyCode: targetCC)
        }
        
        return targetRate / sourceRate
        
    }
    
}