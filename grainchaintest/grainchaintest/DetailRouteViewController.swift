//
//  DetailRouteViewController.swift
//  grainchaintest
//
//  Created by ADMINISTRADOR on 23/11/19.
//  Copyright © 2019 grainchain. All rights reserved.
//

import UIKit
import MapKit
import SQLite

class DetailRouteViewController: UIViewController {
    
    let locationManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var lblRouteName: UILabel!
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblAltitud: UILabel!
    @IBOutlet weak var lblPresion: UILabel!
    
    //Parametros que se reciben
    var nameRoute = ""
    var idRoute = 0;
    
    //Variables de base de datos
    var database: Connection!
    let routesTable = Table("routes")
    let col_id = Expression<Int>("id")
    
    let coordinatesTable = Table("coordinates")
    //col_id
    let col_latitud = Expression<Double>("latitud")
    let col_longitud = Expression<Double>("longitud")
    let col_id_route = Expression<Int>("id_route")
    let col_timestamp = Expression<NSDate>("created")
    
    var distanceInMeters: Double = 0
    var timerOfRoute: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        lblRouteName.text = nameRoute;
        
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
        initLocation()
        lblDistance.text = "\(round(distanceInMeters)) m"
        lblTime.text = "\(timerOfRoute)"
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
            
            do {
                let coordsQuery: AnySequence<Row> = try database.prepare(self.coordinatesTable.filter(self.col_id_route == idRoute))
                
                var flag: Int = 0
                var history: Int = 0
                let annotation1 = MKPointAnnotation()
                var coordinate0: CLLocation? = CLLocation(latitude: 0.1, longitude: 0.1)
                var coordinate1: CLLocation? = CLLocation(latitude: 0.1, longitude: 0.1)
                
                var cordinateOrigen: CLLocationCoordinate2D? = nil
                var cordinationDestino: CLLocationCoordinate2D? = nil
                //var initDate: Date? = nil
                //var endDate: Date? = nil
                
                for coords in coordsQuery {
                    print("info: \(coords)")
                    if flag == 0 {
                        coordinate0 = CLLocation(latitude: coords[self.col_latitud], longitude: coords[self.col_longitud])
                        coordinate1 = CLLocation(latitude: 0.5, longitude: 0.5)
                    } else {
                        coordinate1 = CLLocation(latitude: coords[self.col_latitud], longitude: coords[self.col_longitud])
                    }
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: coords[self.col_latitud], longitude: coords[self.col_longitud])
                    
                    annotation1.coordinate = CLLocationCoordinate2D(latitude: coords[self.col_latitud], longitude: coords[self.col_longitud])
                    
                    mapView.addAnnotation(annotation)
                    
                    if flag == 0{
                        cordinateOrigen = CLLocationCoordinate2D(latitude: coords[self.col_latitud], longitude: coords[self.col_longitud])
                    } else if flag == 1 {
                        cordinationDestino = CLLocationCoordinate2D(latitude: coords[self.col_latitud], longitude: coords[self.col_longitud])
                        
                        let origenPlaceMark = MKPlacemark(coordinate: cordinateOrigen!)
                        let destinoPlaceMark = MKPlacemark(coordinate: cordinateOrigen!)
                        
                        let directionRequest = MKDirections.Request()
                        directionRequest.source = MKMapItem(placemark: origenPlaceMark)
                        directionRequest.destination = MKMapItem(placemark: destinoPlaceMark)
                        directionRequest.transportType = .walking
                        
                        let directions = MKDirections(request: directionRequest)
                        directions.calculate { (response, error) in
                            guard let directionResponse = response else {
                                if let error = error {
                                    print("Tenemos un error con sus direcciones==\(error.localizedDescription)")
                                }
                                return
                            }
                            let route = directionResponse.routes[0]
                            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                            
                            //let rect = route.polyline.boundingMapRect
                            //self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                        }
                        
                        history = history + 1
                    } else if flag > history {
                        cordinateOrigen = cordinationDestino
                        cordinationDestino = CLLocationCoordinate2D(latitude: coords[self.col_latitud], longitude: coords[self.col_longitud])
                        
                        let origenPlaceMark = MKPlacemark(coordinate: cordinateOrigen!)
                        let destinoPlaceMark = MKPlacemark(coordinate: cordinateOrigen!)
                        
                        let directionRequest = MKDirections.Request()
                        directionRequest.source = MKMapItem(placemark: origenPlaceMark)
                        directionRequest.destination = MKMapItem(placemark: destinoPlaceMark)
                        directionRequest.transportType = .automobile
                        
                        let directions = MKDirections(request: directionRequest)
                        directions.calculate { (response, error) in
                            guard let directionResponse = response else {
                                if let error = error {
                                    print("Tenemos un error con sus direcciones==\(error.localizedDescription)")
                                }
                                return
                            }
                            let route = directionResponse.routes[0]
                            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                            
                            //let rect = route.polyline.boundingMapRect
                            //self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                        }
                        
                        history = history + 1
                    }
                    
                    flag = flag + 1
                }
                let region = MKCoordinateRegion(center: annotation1.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
                mapView.setRegion(region, animated: true)
                distanceInMeters = coordinate0!.distance(from: coordinate1!)
            } catch {
                print(error)
            }
        }
    }
    
    func alertLocation(titulo: String, mensaje: String){
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        let action = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        alerta.addAction(action)
        self.present(alerta, animated: true, completion: nil)
    }
    
    @IBAction func deleteRoute(_ sender: Any) {
        print("DELETE TAPPED")
        let alert = UIAlertController(title: "Borrar Ruta", message: "Se eliminará esta ruta", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
        }))
        alert.addAction(UIAlertAction(title: "OKAY", style: .default, handler: { action in
            switch action.style{
                case .default:
                    print("default")
                    let deleteQueryCoordInfo = self.coordinatesTable.filter(self.col_id_route == self.idRoute)
                    let deleteCoord = deleteQueryCoordInfo.delete()
                    do {
                        try self.database.run(deleteCoord)
                    } catch {
                        print(error)
                    }
                    
                    let deleteQueryRoute = self.routesTable.filter(self.col_id == self.idRoute)
                    let deleteRoute = deleteQueryRoute.delete()
                    do {
                        try self.database.run(deleteRoute)
                    } catch {
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
    
}

extension DetailRouteViewController : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error de localización")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //
    }
}

extension DetailRouteViewController : MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        pin.pinTintColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        
        return pin
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolygonRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        return renderer
    }
}
