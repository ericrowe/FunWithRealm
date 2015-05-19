//
//  ViewController.swift
//  FunWithRealm
//
//  Created by Eric Rowe on 5/5/15.
//  Copyright (c) 2015 Eric Rowe. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var tableView : UITableView!
    
    var results : RLMResults?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.contentInset = UIEdgeInsets(top: 22, left: 0, bottom: 0, right: 0)
        
        var lastUpdateDate = NSUserDefaults.standardUserDefaults().objectForKey("lastUpdateDate") as? NSDate
        
        println(lastUpdateDate!.timeIntervalSinceNow)
        
        if lastUpdateDate == nil || lastUpdateDate!.timeIntervalSinceNow < -5 {
            println("Updating Wunderground data")
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: "gotWundergroundData:",
                name: wundergroundRequestNotification,
                object: nil)
            
            RESTRequestManager().loadDictionaryFromServer(
                "http://api.wunderground.com/api/\(kWundergroundKey)/hourly10day/q/CO/Colorado_Springs.json",
                notificationName: wundergroundRequestNotification)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func gotWundergroundData(notification:NSNotification) {
        println("Got Wunderground Data!")
        if var userInfo : NSDictionary = notification.userInfo {
            if var request = userInfo.objectForKey("sender") as? RESTRequestManager {
                var forecast: NSArray = request.results?.objectForKey("hourly_forecast") as! NSArray;
                
                var realm = RLMRealm.defaultRealm()
                realm.beginWriteTransaction()
                
                realm.deleteAllObjects()
                
                println(forecast)
                
                for obj : AnyObject in forecast {
                    if let thisForecast = obj as? NSDictionary {
                        var time = thisForecast.objectForKey("FCTTIME") as! NSDictionary
                        var prettyTime = time.objectForKey("pretty") as! String
                        
                        var condition = thisForecast.objectForKey("condition") as! String
                        
                        var temp = thisForecast.objectForKey("temp") as! NSDictionary
                        var tempEnglish = temp.objectForKey("english") as! String
                        var tempMetric = temp.objectForKey("metric") as! String
                        
                        var newForecast = Forecast.createInRealm(realm, withValue: [prettyTime, condition,[tempEnglish.toInt()!,tempMetric.toInt()!]])
                    }
                }
                
                realm.commitWriteTransaction()
                
                NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "lastUpdateDate")
                
                results = nil
                tableView.reloadData()
            }
        }
        
        
    }
    
    
    
    
    
    
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("weatherCell") as! WeatherCell

        if (results == nil) {
            results = Forecast.allObjects()
        }
        
        if indexPath.row < Int(results!.count) {
            var forecast = results!.objectAtIndex(UInt(indexPath.row)) as! Forecast
            cell.conditionsLabel.text = forecast.condition!
            cell.tempLabel.text = "\(forecast.temp.english)º F"
            cell.timeLabel.text = forecast.prettyTime
        }
        
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(Forecast.allObjects().count)
    }
    
    
    
    
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                if (results == nil) {
                    results = Forecast.allObjects()
                }
                
                if indexPath.row < Int(results!.count) {
                    var forecast = results!.objectAtIndex(UInt(indexPath.row)) as! Forecast
                    (segue.destinationViewController as! DetailViewController).detailItem = "\(forecast.prettyTime), \(forecast.condition)"
                }
            }
        }
    }

}

class WeatherCell: UITableViewCell {
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var conditionsLabel: UILabel!
    @IBOutlet var tempLabel: UILabel!
}

