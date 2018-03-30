import Foundation
import CoreBluetooth

public struct DeviceUUIDs
{
    // アドバタイジングするサービスUUID (コントロールサービス)
//    public static let advertisingServiceUUID:CBUUID    = ControlServiceUUID
    
    // Device information service
    public static let DeviceInformationServiceUUID:CBUUID    = {return CBUUID(string: "180A")}()
    public static let ManufacturerNameStringCharUUID:CBUUID  = {return CBUUID(string: "2A29")}()
    public static let HardwareRevisionStringCharUUID:CBUUID  = {return CBUUID(string: "2A27")}()
    public static let FirmwareRevisionStringCharUUID:CBUUID  = {return CBUUID(string: "2A26")}()
    public static let SerialNumberStringCharUUID:CBUUID      = {return CBUUID(string: "2A25")}()
    
    // Battery service
    public static let BatteryServiceUUID:CBUUID    = {return CBUUID(string: "180F")}()
    public static let BatteryLevelCharUUID:CBUUID  = {return CBUUID(string: "2A19")}()

    // Sensor service
    public static let SensorServiceUUID:CBUUID        = {return CBUUID(string: "F0002100-0451-4000-B000-000000000000")}()
    public static let SensorDataCharUUID:CBUUID       = {return CBUUID(string: "F0007100-0451-4000-B000-000000000000")}()
    public static let SensorThresholdCharUUID:CBUUID  = {return CBUUID(string: "F0007200-0451-4000-B000-000000000000")}()
    
    // デバイスが持つべき、サービスUUIDがキー、キャラクタリスティクスの配列、の辞書を返します。
    public static let ServiceUUIDs: [CBUUID: [CBUUID]] = [
        DeviceInformationServiceUUID : [ManufacturerNameStringCharUUID, HardwareRevisionStringCharUUID, FirmwareRevisionStringCharUUID, SerialNumberStringCharUUID],
        BatteryServiceUUID: [BatteryLevelCharUUID],
        SensorServiceUUID: [SensorDataCharUUID, SensorThresholdCharUUID],
    ]
}
