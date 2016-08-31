//
//  FileManagerExtensions.swift
//  Valute
//
//  Created by apple on 5/2/16.
//  Copyright © 2016 iOS Akademija. All rights reserved.
//

import Foundation

extension NSFileManager {
    
    // Application's home (top-level) directory
    var homeURL: NSURL? {
        return NSURL(fileURLWithPath: NSHomeDirectory())
    }
    
    //	Put user data in `Documents/`. User data generally includes any files you might want to expose to the user—anything you might want the user to create, import, delete or edit.
    var documentsURL: NSURL? {
        let paths = URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return paths.first
    }
    
    //  Put app-created support files in the `Library/Application support/` directory. In general, this directory includes files that the app uses to run but that should remain hidden from the user. This directory can also include data files, configuration files, templates and modified versions of resources loaded from the app bundle.
    var applicationSupportURL: NSURL? {
        let paths = URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        return paths.first
    }
    
    //	Put temporary data in the `tmp/` directory. Temporary data comprises any data that you do not need to persist for an extended period of time. Remember to delete those files when you are done with them so that they do not continue to consume space on the user’s device. The system will periodically purge these files when your app is not running; therefore, you cannot rely on these files persisting after your app terminates.
    var temproraryURL: NSURL? {
        return NSURL(fileURLWithPath: NSTemporaryDirectory())
    }
    
    //	Put data cache files in the `Library/Caches/` directory. Cache data can be used for any data that needs to persist longer than temporary data, but not as long as a support file. Generally speaking, the application does not require cache data to operate properly, but it can use cache data to improve performance. Examples of cache data include (but are not limited to) database cache files and transient, downloadable content. Note that the system may delete the `Caches/` directory to free up disk space, so your app must be able to re-create or download these files as needed.
    var cacheURL: NSURL? {
        let paths = URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask)
        return paths.first?.URLByAppendingPathComponent("Caches/")
    }
    
    func lookupOrCreateDirectoryAtFileURL(url: NSURL) -> Bool {
        
        guard let path = url.path else { return false }
        var isDirectory: ObjCBool = false
        
        if self.fileExistsAtPath(path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return true
            }
            return false
        }
        
        do {
            try self.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            print(error)
            return false
        }
        
        return true
    }
    
}