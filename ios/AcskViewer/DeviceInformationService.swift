//
//  DeviceInformationService.swift

//
//  Created by AkihiroUehara on 2016/06/11.
//  Copyright © 2016年 AkihiroUehara. All rights reserved.
//

import Foundation
import CoreBluetooth

// デバイス情報サービスを示します。
// プロパティは、KVO準拠です。
// シリアルナンバーは、デバイスの製造時に書き込まれた唯一の識別子です。

open class DeviceInformationService : NSObject, DeviceService //, CustomStringConvertible
{
    // Variables
    unowned let device: Device
    
    // Properties, KVO
    @objc dynamic open fileprivate(set) var manufacturerName: String
    @objc dynamic open fileprivate(set) var hardwareRevision: String
    @objc dynamic open fileprivate(set) var firmwareRevision: String
    @objc dynamic open fileprivate(set) var serialNumber:     String
    
    // イニシャライザ
    required public init?(device:Device)
    {
        self.device = device
        
        guard let service = device.findService(DeviceUUIDs.DeviceInformationServiceUUID) else { return nil }

        // 値を読み出し
        if let char = device.findCharacteristic(service, uuid:DeviceUUIDs.ManufacturerNameStringCharUUID) {
            device.readValue(char)
        }
        if let char = device.findCharacteristic(service, uuid:DeviceUUIDs.HardwareRevisionStringCharUUID) {
            device.readValue(char)
        }
        if let char = device.findCharacteristic(service, uuid:DeviceUUIDs.FirmwareRevisionStringCharUUID) {
            device.readValue(char)
        }
        if let char = device.findCharacteristic(service, uuid:DeviceUUIDs.SerialNumberStringCharUUID) {
            device.readValue(char)
        }

        self.manufacturerName = ""
        self.hardwareRevision = ""
        self.firmwareRevision = ""
        self.serialNumber     = ""
    }
    
    // 値更新通知
    func didUpdateValue(_ characteristic: CBCharacteristic, data: [UInt8])
    {
        switch characteristic.uuid {
        case DeviceUUIDs.ManufacturerNameStringCharUUID:
            if let s = String(bytes: data, encoding: String.Encoding.utf8) {
                self.manufacturerName = s
            }
            
        case DeviceUUIDs.HardwareRevisionStringCharUUID:
            if let s = String(bytes: data, encoding: String.Encoding.utf8) {
                self.hardwareRevision = s
            }
            
        case DeviceUUIDs.FirmwareRevisionStringCharUUID:
            if let s = String(bytes: data, encoding: String.Encoding.utf8) {
                self.firmwareRevision = s
            }
            
        case DeviceUUIDs.SerialNumberStringCharUUID:
            if let s = String(bytes: data, encoding: String.Encoding.utf8) {
                self.serialNumber = s
            }
            
        default:
            debugPrint("\(#function): unexpected character: \(characteristic).")
            break
        }
    }
    
    // CustomStringConvertible
    override open var description: String {
        return "Device information: \n  Manufacturer: \(manufacturerName)\n  Hardware revision:\(hardwareRevision)\n  Firmware revision:\(firmwareRevision)\n  Serial number:\(serialNumber)"
    }
}
