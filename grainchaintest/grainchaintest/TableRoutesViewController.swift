//
//  TableRoutesViewController.swift
//  grainchaintest
//
//  Created by ADMINISTRADOR on 23/11/19.
//  Copyright © 2019 grainchain. All rights reserved.
//

import UIKit
import SQLite

class TableRoutesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //Variables de base de datos
    var database: Connection!
    let routesTable = Table("routes")
    let col_id = Expression<Int>("id")
    let col_name = Expression<String?>("name")
    let col_status = Expression<Int?>("status")

    @IBOutlet weak var myTable: UITableView!
    
    var routesArray = [String]()
    var routesIDsArray = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Manejo de la BD
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("users").appendingPathExtension("sqlite3")
            
            let database = try Connection(fileUrl.path)
            self.database = database
        } catch {
            print(error)
        }
        
        listRoutes()
        
        myTable.dataSource = self
        myTable.delegate = self
    }
    
    func listRoutes(){
        print("LIST TAPPED")
        do {
            let routesQuery: AnySequence<Row> = try database.prepare(self.routesTable.filter(self.col_status == 1))
            for route in routesQuery {
                routesArray.append(route[self.col_name]!)
                routesIDsArray.append(route[self.col_id])
                print("RouteName: \(route[self.col_name])")
            }
        } catch {
            print(error)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        
        cell.textLabel!.text = routesArray[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DetailRouteViewController {
            //print(routesArray[(myTable.indexPathForSelectedRow?.row)!])
            destination.nameRoute = routesArray[(myTable.indexPathForSelectedRow?.row)!]
            destination.idRoute = routesIDsArray[(myTable.indexPathForSelectedRow?.row)!]
            myTable.deselectRow(at: myTable.indexPathForSelectedRow!, animated: true)
        }
    }

}
