//
//  StopLoader.swift
//  Kotsu
//
//  Created by Philipp Voigt on 2018/06/22.
//  Copyright © 2018 Ubiquitous Computing Systems Laboratory. All rights reserved.
//

import Foundation


class StopLoader {
    
    static let instance: StopLoader = StopLoader()
    
    static let defaults:[Stop] = [
        Stop(id: 560, nameEN: "NAIST", nameJP: "奈良先端科学技術大学院大学"),
        Stop(id: 558, nameEN: "Takayama Science Town", nameJP: "高山サイエンスタウン", visible: false),
        Stop(id: 2610, nameEN: "Gakken-Kita-Ikoma Station", nameJP: "学研北生駒駅"),
        Stop(id: -1, nameEN: "Gakuemmae Station", nameJP: "学園前駅"),
        Stop(id: 37, nameEN: "Kintetsu Nara Station", nameJP: "近鉄奈良駅"),
        Stop(id: -6, nameEN: "JR Nara Station", nameJP: "ＪＲ奈良駅"),
        Stop(id: 631, nameEN: "Chiku Center", nameJP: "地区センター"),
        Stop(id: 632, nameEN: "Shiki-no-Mori Kōen", nameJP: "四季の森公園"),
        Stop(id: -14, nameEN: "Gakken-Nara-Tomigaoka Station", nameJP: "学研奈良登美ヶ丘駅"),
        Stop(id: -5601, nameEN: "Takanohara Station", nameJP: "高の原駅"),
        Stop(id: 606, nameEN: "Keihanna Plaza", nameJP: "けいはんなプラザ"),
        
        Stop(id: 100001, nameEN: "Kansai Airport Terminal 1", nameJP: "関西空港第1ターミナル"),
        Stop(id: 100002, nameEN: "Kansai Airport Terminal 2", nameJP: "関西空港第2ターミナル"),
        
        Stop(id: 604, nameEN: "Gyoen Station", nameJP: "祝園駅", visible: false),
        Stop(id: 625, nameEN: "Kano-no-Kita 2-Chome", nameJP: "鹿ノ台北二丁目", visible: false)
    ]
    
    
    private var allStops: [Stop] = []
    private var allConnections: [Connection] = []
    
    
    init() {
        let stopData = UserDefaults.standard.data(forKey: "stops")
        if stopData != nil {
            do {
                let stops = try JSONDecoder().decode([Stop].self, from: stopData!)
                allStops = stops
            } catch {
                allStops = StopLoader.defaults
            }
        } else {
            allStops = StopLoader.defaults
        }
        
        let connectionData = UserDefaults.standard.data(forKey: "connections")
        if connectionData != nil {
            do {
                let connections = try JSONDecoder().decode([Connection].self, from: connectionData!)
                allConnections = connections
            } catch {}
        }
        
        let stopURL = "https://mphsoft.uber.space/api/kotsu/stop"
        URLSession.shared.dataTask(with: URL(string: stopURL)!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }
            
            guard let items = try? JSONDecoder().decode([StopItem].self, from: data) else { return }
            
            var stops: [Stop] = []
            for item in items {
                let stop = Stop(id: item.code, nameEN: item.nameEN, nameJP: item.nameJP, visible: item.visible)
                stops.append(stop)
            }
            
            if stops.count > 0 {
                let stopData = try! JSONEncoder().encode(stops)
                UserDefaults.standard.set(stopData, forKey: "stops")
                self.allStops = stops
            }
        }).resume()
        
        let connectionURL = "https://mphsoft.uber.space/api/kotsu/connection"
        URLSession.shared.dataTask(with: URL(string: connectionURL)!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }
            
            guard let items = try? JSONDecoder().decode([ConnectionItem].self, from: data) else { return }
            
            var connections: [Connection] = []
            for item in items {
                guard let from = StopLoader.instance.getStop(id: item.from.code) else { continue }
                guard let to = StopLoader.instance.getStop(id: item.to.code) else { continue }
                
                let connection = Connection(from: from, to: to)
                connections.append(connection)
            }
            
            if connections.count > 0 {
                let connectionData = try! JSONEncoder().encode(connections)
                UserDefaults.standard.set(connectionData, forKey: "connections")
                self.allConnections = connections
            }
        }).resume()
    }
    
    
    func getAll() -> [Stop] {
        return allStops.filter({$0.visible == true})
    }
    
    func getStop(id: Int) -> Stop? {
        let stops = allStops.filter({$0.id == id})
        return stops.count > 0 ? stops[0] : nil
    }
    
    
    func getConnections(from: Stop) -> [Stop] {
        if allConnections.count == 0 {
            var connections : [Stop] = []
            for stop in allStops {
                if stop.visible && stop.id != from.id {
                    connections.append(stop)
                }
            }
            return connections
        } else {
            var connections : [Stop] = []
            for connection in allConnections {
                if connection.from.id == from.id {
                    if connection.to.visible && connection.to.id != from.id {
                        connections.append(connection.to)
                    }
                }
            }
            return connections
        }
    }
    
    
    struct StopItem : Codable {
        let code: Int
        let nameEN: String
        let nameJP: String
        let visible: Bool
    }
    
    struct ConnectionItem : Codable {
        let from, to : ConnectionEndpoint
    }
    struct ConnectionEndpoint : Codable {
        let code : Int
    }
    
}
