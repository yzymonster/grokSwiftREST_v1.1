//
//  DetailViewController.swift
//  grokSwiftREST
//
//  Created by Christina Moulton on 2015-10-20.
//  Copyright © 2015 Teak Mobile Inc. All rights reserved.
//

import UIKit
import SafariServices
import BRYXBanner

class DetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet weak var tableView: UITableView!
  var isStarred: Bool?
  var alertController: UIAlertController?
  var notConnectedBanner: Banner?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    self.configureView()
  }
  
  override func viewWillDisappear(animated: Bool) {
    if let existingBanner = self.notConnectedBanner {
      existingBanner.dismiss()
    }
    super.viewWillDisappear(animated)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  var gist: Gist? {
    didSet {
      // Update the view.
      self.configureView()
    }
  }
  
  func configureView() {
    // Update the user interface for the detail item.
    if let _: Gist = self.gist {
      fetchStarredStatus()
      if let detailsView = self.tableView {
        detailsView.reloadData()
      }
    }
  }
  
  // MARK: - Stars
  
  func fetchStarredStatus() {
    if let gistId = gist?.id {
      GitHubAPIManager.sharedInstance.isGistStarred(gistId, completionHandler: {
        result in
        if let error = result.error {
          print(error)
          if error.domain == NSURLErrorDomain {
            if error.code == NSURLErrorUserAuthenticationRequired {
              self.alertController = UIAlertController(title:
                "Could not get starred status", message: error.description,
                preferredStyle: .Alert)
              // add ok button
              let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
              self.alertController?.addAction(okAction)
              self.presentViewController(self.alertController!, animated:true,
                  completion: nil)
            } else if error.code == NSURLErrorNotConnectedToInternet {
                // show not connected error & tell em to try again when they do have a connection
                // check for existing banner
                if let existingBanner = self.notConnectedBanner {
                  existingBanner.dismiss()
                }
                self.notConnectedBanner = Banner(title: "No Internet Connection",
                  subtitle: "Can not display starred status. " +
                  "Try again when you're connected to the internet",
                  image: nil,
                  backgroundColor: UIColor.orangeColor())
                self.notConnectedBanner?.dismissesOnSwipe = true
                self.notConnectedBanner?.show(duration: nil)
            }
          }
        }
        
        if let status = result.value where self.isStarred == nil { // just got it
          self.isStarred = status
          self.tableView?.insertRowsAtIndexPaths(
            [NSIndexPath(forRow: 2, inSection: 0)],
            withRowAnimation: .Automatic)
        }
      })
    }
  }
  
  func starThisGist() {
    if let gistId = gist?.id {
      GitHubAPIManager.sharedInstance.starGist(gistId, completionHandler: {
        (error) in
        if let error = error {
          print(error)
          if error.domain == NSURLErrorDomain &&
            error.code == NSURLErrorUserAuthenticationRequired {
              self.alertController = UIAlertController(title: "Could not star gist",
                message: error.description, preferredStyle: .Alert)
          } else {
            self.alertController = UIAlertController(title: "Could not star gist",
              message: "Sorry, your gist couldn't be starred. " +
              "Maybe GitHub is down or you don't have an internet connection.",
              preferredStyle: .Alert)
          }
          // add ok button
          let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
          self.alertController?.addAction(okAction)
          self.presentViewController(self.alertController!, animated:true, completion: nil)
        } else {
          self.isStarred = true
          self.tableView.reloadRowsAtIndexPaths(
            [NSIndexPath(forRow: 2, inSection: 0)],
            withRowAnimation: .Automatic)
        }
      })
    }
  }
  
  func unstarThisGist() {
    if let gistId = gist?.id {
      GitHubAPIManager.sharedInstance.unstarGist(gistId, completionHandler: {
        (error) in
        if let error = error {
          print(error)
          if error.domain == NSURLErrorDomain &&
            error.code == NSURLErrorUserAuthenticationRequired {
              self.alertController = UIAlertController(title: "Could not unstar gist",
                message: error.description, preferredStyle: .Alert)
          } else {
            self.alertController = UIAlertController(title: "Could not unstar gist",
              message: "Sorry, your gist couldn't be unstarred. " +
              " Maybe GitHub is down or you don't have an internet connection.",
              preferredStyle: .Alert)
          }
          // add ok button
          let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
          self.alertController?.addAction(okAction)
          self.presentViewController(self.alertController!, animated:true, completion: nil)
        } else {
          self.isStarred = false
          self.tableView.reloadRowsAtIndexPaths(
            [NSIndexPath(forRow: 2, inSection: 0)],
            withRowAnimation: .Automatic)
        }
      })
    }
  }
  
  // MARK: - Table view data source and delegate
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 2
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      if let _ = isStarred {
        return 3
      }
      return 2
    } else {
      return gist?.files?.count ?? 0
    }
  }
  
  func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      return "About"
    } else {
      return "Files"
    }
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        cell.textLabel?.text = gist?.description
      } else if indexPath.row == 1 {
        cell.textLabel?.text = gist?.ownerLogin
      } else {
        if let starred = isStarred {
          if starred {
            cell.textLabel?.text = "Unstar"
          } else {
            cell.textLabel?.text = "Star"
          }
        }
      }
    } else {
      if let file = gist?.files?[indexPath.row] {
        cell.textLabel?.text = file.filename
        // TODO: add disclosure indicators
      }
    }
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.section == 0 {
      if indexPath.row == 2 { // star or unstar
        if let starred = isStarred {
          if starred {
            // unstar
            unstarThisGist()
          } else {
            // star
            starThisGist()
          }
        }
      }
    } else if indexPath.section == 1 {
      if let file = gist?.files?[indexPath.row],
        urlString = file.raw_url,
        url = NSURL(string: urlString) {
          let safariViewController = SFSafariViewController(URL: url)
          safariViewController.title = file.filename
          self.navigationController?.pushViewController(safariViewController, animated: true)
      }
    }
  }
}

