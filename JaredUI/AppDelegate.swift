//
//  AppDelegate.swift
//  JaredUI
//
//  Created by Zeke Snider on 4/5/16.
//  Copyright © 2016 Zeke Snider. All rights reserved.
//

import Cocoa
import Contacts

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let Router = PluginManager()
    let Server = JaredWebServer(configurationURL: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Jared")
        .appendingPathComponent("config.json"))

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let messageDatabaseURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Messages").appendingPathComponent("chat.db")
        let viewController = NSApplication.shared.keyWindow?.contentViewController as? ViewController
		let dbHandler = DatabaseHandler(router: Router.router, databaseLocation: messageDatabaseURL, diskAccessDelegate: viewController)
        if (!dbHandler.authorizationError) {
            dbHandler.start()
        }
		
        // If this is the first run of the application, request access
        // to contacts to pull sender info
        if(CNContactStore.authorizationStatus(for: CNEntityType.contacts) == .notDetermined) {
            CNContactStore().requestAccess(for: CNEntityType.contacts, completionHandler: {_,_ in })
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

