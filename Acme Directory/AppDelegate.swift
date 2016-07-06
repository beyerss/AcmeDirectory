//
//  AppDelegate.swift
//  Acme Directory
//
//  Created by Steven Beyers on 6/29/16.
//  Copyright © 2016 Captech. All rights reserved.
//

import UIKit
import CoreData
import CoreSpotlight
import MobileCoreServices

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Load default data if needed
        loadAppData()
        // Index data for CoreSpotlight
        indexData()
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.delegate = self

        let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        let controller = masterNavigationController.topViewController as! MasterViewController
        controller.managedObjectContext = self.persistentContainer.viewContext
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Handle Search
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        
        if (userActivity.activityType == CSSearchableItemActionType) {
            // This activity represents an item indexed using Core Spotlight, so restore the context related to the unique identifier.
            // Note that the unique identifier of the Core Spotlight item is set in the activity’s userInfo property for the key CSSearchableItemActivityIdentifier.
            guard let userInfo = userActivity.userInfo, username = userInfo[CSSearchableItemActivityIdentifier] as? String else { return false }
            
            let splitViewController = self.window!.rootViewController as! UISplitViewController
            let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
            let controller = masterNavigationController.viewControllers[0] as! MasterViewController
            controller.completeSearch(for: username)
        }
        
        return true
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.detailItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Acme_Directory")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - Initial App Data
    func loadAppData() {
        // has app data been loaded
        if !UserDefaults.standard().bool(forKey: "hasDataBeenLoaded") {
            
            // get the URL for the local json file
            let employeeJsonURL = Bundle.main().urlForResource("employees", withExtension: "json")
            // make sure the url was built properly
            if let url = employeeJsonURL {
                // pull the file into an NSData object
                let jsonData = try? Data(contentsOf: url)
                
                if let jsonData = jsonData {
                    // create an error placeholder
                    // serialize the json into an array
                    do {
                        let employees = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as! [[String: AnyObject]]
                        
                        for employeeDict in employees {
                            let employee = Employee(context: self.persistentContainer.viewContext)
                            employee.firstName = employeeDict["firstName"] as? String
                            employee.lastName = employeeDict["lastName"] as? String
                            employee.department = employeeDict["department"] as? String
                            employee.email = employeeDict["email"] as? String
                            employee.phoneNumber = employeeDict["phone"] as? String
                            employee.username = employeeDict["username"] as? String
                        }
                        
                        saveContext()
                    } catch {
                        print("Exception!")
                    }
                }
            }
            
            UserDefaults.standard().set(true, forKey: "hasDataBeenLoaded")
        }
    }
    
    func indexData() {
        let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
        
        do {
            let employees = try persistentContainer.viewContext.fetch(fetchRequest)
            var searchableItems = [CSSearchableItem]()
            
            for employee in employees {
                let searchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
                
                var name = ""
                if let first = employee.firstName {
                    name = first
                }
                if let last = employee.lastName {
                    name = "\(name) \(last)"
                }
                searchableItemAttributeSet.title = name
                searchableItemAttributeSet.identifier = employee.username
                if let title = employee.department {
                    searchableItemAttributeSet.contentDescription = title
                }
                if let email = employee.email {
                    searchableItemAttributeSet.emailAddresses = [email]
                }
                if let phone = employee.phoneNumber {
                    searchableItemAttributeSet.supportsPhoneCall = NSNumber(value: true)
                    searchableItemAttributeSet.phoneNumbers = [phone]
                    searchableItemAttributeSet.instantMessageAddresses = [phone]
                }
                
                // Create CSSearchableItem for employee
                let employeeItem = CSSearchableItem(uniqueIdentifier: employee.username, domainIdentifier: "Acme Employees", attributeSet: searchableItemAttributeSet)
                // expire one year from now - If the app is not used for a year then the search results will no longer show but it is also very unlikely that the user will search for an employee after a year of not using the app
                employeeItem.expirationDate = Date(timeInterval: 60 * 60 * 24 * 365, since: Date())
                searchableItems.append(employeeItem)
            }
            
            // Add all items to the index
            CSSearchableIndex.default().indexSearchableItems(searchableItems, completionHandler: { (error: NSError?) in
                if let error = error {
                    print("Error indexing searchable items: \(error), \(error.userInfo)")
                }
            })
        } catch {
            let nserror = error as NSError
            print("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}

