//
//  ViewController.swift
//  grainchaintest
//
//  Created by ADMINISTRADOR on 21/11/19.
//  Copyright © 2019 grainchain. All rights reserved.
//

import UIKit
import MapKit
import SQLite

class ViewController: UIViewController {

    let locationManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var lblLatitud: UILabel!
    @IBOutlet weak var lblLongitud: UILabel!
    
    //Variables de base de datos
    var database: Connection!
    
    let routesTable = Table("routes")
    let col_id = Expression<Int>("id")
    let col_name = Expression<String?>("name")
    let col_status = Expression<Int?>("status")
    
    let coordinatesTable = Table("coordinates")
    //col_id
    let col_latitud = Expression<Double>("latitud")
    let col_longitud = Expression<Double>("longitud")
    let col_id_route = Expression<Int>("id_route")
    let col_timestamp = Expression<Date>("created")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        
        //Manejo de la BD
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("users").appendingPathExtension("sqlite3")
            
            let database = try Connection(fileUrl.path)
            self.database = database
        } catch {
            print(error)
        }
        
        createTables()
    }
    
    @IBAction func btn_findme(_ sender: Any) {
        //Aqui llamaremos a guardar la ruta
        initLocation()
        
        let row = try! database.pluck(self.routesTable.filter(self.col_status == 0))
        //print("Lista de rutas")
        if row != nil {
            //print("Tiene datos")
            let alert = UIAlertController(title: "Save New Route", message: nil, preferredStyle: .alert)
            alert.addTextField { (tf) in tf.placeholder = "Name of Route" }
            let action = UIAlertAction(title: "Save", style: .default) { (_) in
                let routeNameString = alert.textFields?.last?.text
                
                let id_route = row?[self.col_id]
                let route = self.routesTable.filter(self.col_id == id_route!)
                let updateRoute = route.update(self.col_name <- routeNameString, self.col_status <- 1)
                do {
                    try self.database.run(updateRoute)
                    print("Update route")
                    self.listRoutes()
                } catch {
                    print(error)
                }
            }
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Alerta", message: "La aplicación comenzara a grabar tu ruta", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                switch action.style{
                    case .default:
                        print("default")
                    
                    case .cancel:
                        print("cancel")

                    case .destructive:
                        print("destructive")
                }
            }))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                switch action.style{
                    case .default:
                        //print("default")
                        let insertRoute = self.routesTable.insert(self.col_name <- "test", self.col_status <- 0)
                        do{
                            try self.database.run(insertRoute)
                            print("Insert Route")
                            self.listRoutes()
                        } catch{
                            print(error)
                        }
                    break

                    case .cancel:
                        print("cancel")

                    case .destructive:
                        print("destructive")
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
        //listCoordinates()
    }
    
    func initLocation() {
        let permiso = CLLocationManager.authorizationStatus()
        
        if permiso == .notDetermined{
            locationManager.requestWhenInUseAuthorization()
        } else if permiso == .denied{
            alertLocation(titulo: "Error de localización", mensaje: "Actualmente tiene denegada la localización del dispositivo")
        } else if permiso == .restricted{
            alertLocation(titulo: "Error de localización", mensaje: "Actualmente tiene restringida la localizción del dispositivo")
        } else {
            guard let currentCoordinate = locationManager.location?.coordinate else { return }
            
            let region = MKCoordinateRegion(center: currentCoordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func alertLocation(titulo: String, mensaje: String){
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        let action = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        alerta.addAction(action)
        self.present(alerta, animated: true, completion: nil)
    }
    
    func createTables(){
        print("CREATE TAPEDS")
    
        let createTableRoutes = routesTable.create { (table1) in
            table1.column(col_id, primaryKey: true)
            table1.column(col_name)
            table1.column(col_status)
        }
        
        let createTableCoordinates = coordinatesTable.create { (table2) in
            table2.column(col_id, primaryKey: true)
            table2.column(col_latitud)
            table2.column(col_longitud)
            table2.column(col_id_route)
            table2.column(col_timestamp)
        }
        
        do {
            try self.database.run(createTableRoutes)
            print("Created Table Routes")
        } catch {
            print(error)
        }
        
        do{
            try self.database.run(createTableCoordinates)
            print("Created Table Coordinates")
        } catch {
            print(error)
        }
    }
    
    func listRoutes(){
        print("LIST TAPPED")
        
        do {
            let routeslist = try self.database.prepare(self.routesTable)
            for info in routeslist {
                //print("routeId: \(info[self.col_id]), name: \(info[self.col_name]), status: \(info[self.col_status])")
            }
        } catch{
            print(error)
        }
    }
    
    func listCoordinates(){
        print("LIST TAPPED")
        
        do {
            let coordinateslist = try self.database.prepare(self.coordinatesTable)
            for info in coordinateslist {
                print("coordinateId: \(info[self.col_id]), latitud: \(info[self.col_latitud]), longitud: \(info[self.col_longitud]), id_route: \(info[self.col_id_route]), created: \(info[self.col_timestamp])")
            }
        } catch{
            print(error)
        }
    }
    
}

extension ViewController : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error de localización")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
    
        let userCoord = newLocation.coordinate
        let latitud = Double(userCoord.latitude)
        let longitud = Double(userCoord.longitude)
        
        let latSt = (latitud < 0) ? "S" : "N"
        let lonSt = (longitud < 0) ? "O" : "E"
                
        lblLatitud.text = "\(latSt) \(latitud)"
        lblLongitud.text = "\(lonSt) \(longitud)"
        
        let altitud = newLocation.altitude
        var altitudSt = "\(altitud) m"
        
        let precisionH = newLocation.horizontalAccuracy
        var precisionSt = "\(precisionH) m"
        
        let row = try! database.pluck(self.routesTable.filter(self.col_status == 0))
        //print("Lista de rutas")
        if row != nil {
            let id_route = row?[self.col_id]
            let insertCoordinates = self.coordinatesTable.insert(self.col_latitud <- latitud, self.col_longitud <- longitud, self.col_id_route <- id_route!, self.col_timestamp <- Date())
            
            do{
                try self.database.run(insertCoordinates)
                print("Insert Coordinates")
                listCoordinates()
            } catch{
                print(error)
            }
        }
    }
}
