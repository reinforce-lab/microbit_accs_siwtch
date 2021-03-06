
import Foundation
import CoreBluetooth

protocol SensorSerivceDelegate: class
{
    func didUpdate(_ sender: SensorSerivce, data: SensorData)
    func didThresholdUpdate(_ sender: SensorSerivce, highThreshold: Int, lowThreshold: Int)
}

struct SensorData
{
    let Acceleration: Int
    let HighThresholdOutput: Int
    let LowThresholdOutput:  Int
}

open class SensorSerivce : DeviceService
{
    weak var delegate:SensorSerivceDelegate?
    
    // Variables
    unowned let device: Device

    var thresholdData: [UInt8]?
    var isWriting: Bool = false
    
    let service: CBService
    let dataChar: CBCharacteristic
    let thresholdChar: CBCharacteristic
    // イニシャライザ
    required public init?(device:Device)
    {
        self.device = device
        
        guard let _service   = device.findService(DeviceUUIDs.SensorServiceUUID) else { return nil }
        guard let _dataChar  = device.findCharacteristic(_service, uuid:DeviceUUIDs.SensorDataCharUUID) else { return nil }
        guard let _thresholdChar = device.findCharacteristic(_service, uuid:DeviceUUIDs.SensorThresholdCharUUID) else { return nil }

        self.service = _service
        self.dataChar = _dataChar
        self.thresholdChar = _thresholdChar
        
        self.device.setNotify(self.dataChar, enabled: true)
        self.readThreshold()
    }

    // 値更新通知
    func didUpdateValue(_ characteristic: CBCharacteristic, data: [UInt8])
    {
        switch characteristic.uuid {
        case DeviceUUIDs.SensorDataCharUUID:
            // 8バイト。加速度X,Y,Z, 16ビット整数。閾値HIGH、閾値LOW出力、それぞれ1バイト。
            guard data.count == 8 else { return }
            let x = Int16.unpack(data[0..<2])!
            let y = Int16.unpack(data[2..<4])!
            let z = Int16.unpack(data[4..<6])!
            let mag = sqrt( pow(Double(x), 2) + pow(Double(y), 2) + pow(Double(z), 2) )
            let highOutput = Int(data[6])
            let lowOutput  = Int(data[7])
            let data = SensorData(Acceleration: Int(mag), HighThresholdOutput: highOutput, LowThresholdOutput: lowOutput)
            DispatchQueue.main.async {
                self.delegate?.didUpdate(self, data: data)
            }

        case DeviceUUIDs.SensorThresholdCharUUID:
            guard data.count == 5 else { return }
            // 5バイト。リトルエンディアン、16ビット整数で、high閾値、low閾値。最後の1バイトはチェックサム。
            let highThreshold = Int(Int16.unpack(data[0..<2])!)
            let lowThreshold  = Int(Int16.unpack(data[2..<4])!)
            DispatchQueue.main.async {
                self.delegate?.didThresholdUpdate(self, highThreshold: highThreshold, lowThreshold: lowThreshold)
            }
            
        default:
            debugPrint("\(#function): unexpected character: \(characteristic).")
            break
        }
    }

    func readThreshold()
    {
        self.device.readValue(self.thresholdChar)
    }
    
    func updateThreshold(highThreshold:Int, lowThreshold:Int)
    {
        // 閾値16ビット整数、リトルエンディアン。チェックサムは合計値の下位1バイト。
        var b = [UInt8]()
        
        b += Int16(highThreshold).pack()
        b += Int16(lowThreshold).pack()
        let sum = highThreshold + lowThreshold
        b += [UInt8(sum & 0x0ff)]
        
        assert(b.count == 5)
        
        // 0.1秒ごとに書き込みをまとめる。
        self.thresholdData = b
        if( !self.isWriting ) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                if let data = self.thresholdData {
                    self.device.writeValue(self.thresholdChar, value: data)
                }
                self.isWriting = false
            })
        }
    }
}
