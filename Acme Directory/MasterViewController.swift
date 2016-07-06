//
//  MasterViewController.swift
//  Acme Directory
//
//  Created by Steven Beyers on 6/29/16.
//  Copyright © 2016 Captech. All rights reserved.
//

import UIKit
import CoreData
import CoreSpotlight

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    var searchResults: [Employee?]?
    var query: CSSearchQuery?

    lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.dimsBackgroundDuringPresentation = false
        
        return search
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    func filterContent(search text: String) {
        query?.cancel();
        
        var results = [Employee?]()
        
        let escapedString = text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let queryString = "**=\"" + escapedString + "*\"cwdt"
        print(queryString)
        
        query = CSSearchQuery(queryString: queryString, attributes: ["title"])
        query?.foundItemsHandler =  { [weak self](items : [CSSearchableItem]) -> Void in
            
            let mapResults = items.map({ [weak self](item: CSSearchableItem) -> Employee? in
                guard let `self` = self else { return nil }
                
                let employee = self.fetchedResultsController.fetchedObjects?.filter( { $0.username == item.uniqueIdentifier } ).first
                return employee
            })
            
            results.append(contentsOf: mapResults)
        }
        query?.completionHandler = {  [weak self](err) -> Void in
            results.sort(isOrderedBefore: { (employee1: Employee?, employee2: Employee?) -> Bool in
                guard let lastName1 = employee1?.lastName, lastName2 = employee2?.lastName else { return true }
                
                if (lastName1 == lastName2) {
                    guard let firstName1 = employee1?.firstName, firstName2 = employee2?.firstName else { return true }
                    
                    return (firstName1 <= firstName2)
                } else {
                    return lastName1 < lastName2
                }
            })
            
            /* finish processing */
            DispatchQueue.main.async(execute: {
                self?.searchResults = results
                self?.tableView.reloadData()
            })
        }
        query?.start()
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let employee: Employee?
                if searchController.isActive && searchController.searchBar.text != "" {
                    employee = searchResults?[indexPath.row]
                } else {
                    employee = fetchedResultsController.object(at: indexPath)
                }
                
                if let object = employee {
                    let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                    controller.detailItem = object
                    controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                    controller.navigationItem.leftItemsSupplementBackButton = true
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        }
        
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return searchResults?.count ?? 0
        }
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let employee: Employee
        
        if searchController.isActive && searchController.searchBar.text != "" {
            employee = searchResults![indexPath.row]!
        } else {
            employee = self.fetchedResultsController.object(at: indexPath)
        }
        
        self.configureCell(cell, withEmployee: employee)
        return cell
    }

    func configureCell(_ cell: UITableViewCell, withEmployee employee: Employee) {
        var rawName = ""
        if let first = employee.firstName {
            rawName = first
        }
        if let last = employee.lastName {
            rawName = "\(rawName) \(last)"
        }
        let name = NSMutableAttributedString(string: rawName, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 22)])
        if let lastName = employee.lastName {
            let location = (name.string as NSString).range(of: lastName)
            name.setAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 22)], range: location)
        }
        cell.textLabel!.attributedText = name
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<Employee> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let lastNameSort = SortDescriptor(key: "lastName", ascending: true)
        let firstNameSort = SortDescriptor(key: "firstName", ascending: true)
        
        fetchRequest.sortDescriptors = [lastNameSort, firstNameSort]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController<Employee>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: AnyObject, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                self.configureCell(tableView.cellForRow(at: indexPath!)!, withEmployee: anObject as! Employee)
            case .move:
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }

    // MARK: - Handle search results
    func completeSearch(for username: String) {
        let completion = { [weak self] in
            DispatchQueue.main.async(execute: { [weak self] in
                guard let `self` = self else { return }
                
                if let employees = self.fetchedResultsController.fetchedObjects {
                    let usernames = employees.map({ $0.username })
                    if let index = usernames.index(where: { $0 == username }) {
                        let finish = { [weak self] in
                            DispatchQueue.main.async(execute: { [weak self] in
                                self?.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: UITableViewScrollPosition.middle)
                                self?.performSegue(withIdentifier: "showDetail", sender: nil)
                            })
                        }
                        
                        if (self.searchController.isActive) {
                            // stop searching
                            self.searchController.searchBar.text = ""
                            self.searchController.isActive = false
                            self.tableView.reloadData()
                        }
                        
                        if let coordinator = self.transitionCoordinator() {
                            coordinator.animate(alongsideTransition: nil, completion: { _ in
                                finish()
                            })
                        } else {
                            finish()
                        }
                    }
                }
                })
        }
        
        _ = navigationController?.popToRootViewController(animated: false)
        if let coordinator = transitionCoordinator() {
            if navigationController?.viewControllers.count > 1 {
                coordinator.animate(alongsideTransition: nil) { _ in
                    completion()
                }
            } else {
                completion()
            }
        } else {
            completion()
        }
    }
    
    func continueSearch(withString searchString: String) {
        _ = navigationController?.popToRootViewController(animated: true)
        searchController.isActive = true
        searchController.searchBar.text = searchString
    }

}

extension MasterViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContent(search: searchController.searchBar.text!)
    }
    
}

