//
//  RealTimeHealthRequest.swift
//  WAYVI Watch App
//
//  Created by 성호은 on 5/28/25.
//

import Foundation

struct RealTimeHealthRequest: Codable {
    let timestamp: String
    let heartRate: Double
    let stepCount: Int
    let activeEnergyBurned: Int
    let runningSpeed: [Double]
    let accel: [Double]
    let gyro: [Double]
}
