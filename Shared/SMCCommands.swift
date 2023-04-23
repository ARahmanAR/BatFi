//
//  SMCCommands.swift
//  BatFi
//
//  Created by Adam on 16/04/2023.
//

import Foundation

enum SMCChargingCommand: Codable {
    case forceDischarging
    case auto
    case inhibitCharging
}
