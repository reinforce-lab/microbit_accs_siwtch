
import Foundation
import CoreBluetooth

protocol UARTSerivceDelegate: class
{
    func didUpdate(_ sender: UARTSerivce, data: MicrobitSensorData)
}

struct MicrobitSensorData
{
    let Acceleration: Int
    let HighThreshold: Int
    let LowThreshold: Int
    let P0Switch: Int
    let P1Switch: Int
}

open class UARTSerivce : MicrobitService
{
    weak var delegate:UARTSerivceDelegate?
    
    // Variables
    unowned let device: MicrobitDevice

    let service: CBService
    let readChar: CBCharacteristic
    let writeChar: CBCharacteristic
    // イニシャライザ
    required public init?(device:MicrobitDevice)
    {
        self.device = device
        
        guard let _service   = device.findService(MicrobitUUIDs.NordicUARTServiceUUID) else { return nil }
        guard let _readChar  = device.findCharacteristic(_service, uuid:MicrobitUUIDs.NordicUARTReadCharUUID) else { return nil }
        guard let _writeChar = device.findCharacteristic(_service, uuid:MicrobitUUIDs.NordicUARTWriteCharUUID) else { return nil }

        self.service = _service
        self.readChar = _readChar
        self.writeChar = _writeChar
        
        self.device.setNotify(self.readChar, enabled: true)
    }

    func parse(data: String)
    {
//        debugPrint("\(#function) \(s).")
        // 先頭は":"
        guard data.starts(with: ":") else { return }
        let str = data.dropFirst()
        // ","で分割。
        let items = str.split(separator: ",")
        guard items.count == 5 else { return }
        
        let d = MicrobitSensorData(Acceleration: Int(items[0])!, HighThreshold: Int(items[1])!, LowThreshold: Int(items[2])!, P0Switch: Int(items[3])!, P1Switch: Int(items[4])!)
        DispatchQueue.main.async {
            self.delegate?.didUpdate(self, data: d)
        }
    }
    
    // 値更新通知
    func didUpdateValue(_ characteristic: CBCharacteristic, data: [UInt8])
    {
        switch characteristic.uuid {
        case MicrobitUUIDs.NordicUARTReadCharUUID:
             if let s = String(bytes: data, encoding: String.Encoding.utf8) {
                parse(data: s)
            }
            
        default:
            debugPrint("\(#function): unexpected character: \(characteristic).")
            break
        }
    }
    
    func updateThreshold(highThreshold:Int, lowThreshold:Int)
    {
        // 開始文字列
        self.device.writeValue(self.writeChar, value: Array("0:".utf8))
        // 値
        self.device.writeValue(self.writeChar, value: Array("\(highThreshold)#".utf8))
        // 値
        self.device.writeValue(self.writeChar, value: Array("\(lowThreshold)$".utf8))
    }
}
