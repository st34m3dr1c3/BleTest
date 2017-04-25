//
//  BleService.swift
//  device
//



import Foundation
import CoreBluetooth


//class BleService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, PairingServiceDelegate, NSCoding
class BleService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, PairingServiceDelegate
    
{
    // UUIDs
    let serviceUUID                          = CBUUID(string: "7D170001-1B9E-4DC3-4595-24428868E680")
    let streamingCharacteristicUUID          = CBUUID(string: "7D170002-1B9E-4DC3-4595-24428868E680")
    let commandResponseCharacteristicUUID    =  CBUUID(string: "7D170003-1B9E-4DC3-4595-24428868E680")
    
    let MAX_CONNECTED_SENSORS=4
    
    let CMD_GET_STATUS = 0x01
    let CMD_SET_CLOCK = 0x02
    let CMD_MEASURE = 0x03
    let CMD_LOCATE = 0x04
    let CMD_LED_POWER = 0x05
    let CMD_SET_INTERVAL = 0x06
    let CMD_SET_SINGLE_LED = 0x07
    let CMD_SET_AMPLIFIER = 0x08
    let CMD_RESET = 0x0A
    
    let RSP_GET_STATUS: UInt8 = 0x81
    let RSP_SET_CLOCK: UInt8 = 0x82
    let RSP_MEASURE: UInt8 = 0x83
    let RSP_LOCATE: UInt8 = 0x84
    let RSP_LED_POWER: UInt8 = 0x85
    let RSP_SET_INTERVAL: UInt8 = 0x86
    let RSP_SET_SINGLE_LED: UInt8 = 0x87
    let RSP_SET_AMPLIFIER: UInt8 = 0x88
    let RSP_RESET: UInt8 = 0x8A
    
    var unintentionalDisconnect: [Bool] = [true , true , true , true]
    
    var sensorCount = 0;
    
    var channelAssignment : [UUID] = [NSUUID() as UUID, NSUUID() as UUID, NSUUID() as UUID, NSUUID() as UUID]
    var channelsConnected : [Bool] = [ false, false, false, false ]
    var centralManager : CBCentralManager!
    var sensorPeripheral = [UUID:CBPeripheral]()
    var sensorNames = [UUID:String]()
    
    var charCommandResponse = [UUID:CBCharacteristic]()
    var charStreaming = [UUID:CBCharacteristic]()
    
    var connectionTimingCache = [UUID: Int]()
    
    var connectionTimer = Timer()
    
    
    // Create intended pairing index to be set from Pairing Controller
    var intendedPairingIndex: Int!
    
    
    
    // Keep track of the number of devicees for the uniqueID
    
    var deviceDevicesUniqueId:[UUID:String] = [UUID:String]()
    var reconnectingDevicesUniqueId:[UUID:Int] = [UUID:Int]()
    var deviceState:[UUID:Int]=[UUID:Int]()
    var deviceLed:[UUID:Int]=[UUID:Int]()
    var deviceBattery:[UUID:Int]=[UUID:Int]()
    var deviceAmplifierGain:[UUID:Int]=[UUID:Int]()
    var deviceInterval:[UUID:Int]=[UUID:Int]()
    var deviceLEDEnableStatus:[UUID:[Bool]]=[UUID:[Bool]]()
    
    //Created Shared Class Set
    static let shared = BleService()
    
    //    //Create State Restore Queue
    //    private let queue = DisdeviceQueue(label: "BTQueue")
    
    var observers: [PAWeakRef<AnyObject>] = []
    
    //    override init()
    //    {
    //        super.init()
    //
    //    }
    
    
    func getdeviceState( deviceChannelNumber:Int)->Int{
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        
        
        let deviceId = self.channelAssignment[deviceChannelNumber-1]
        
        if deviceState[deviceId] != nil {
            return deviceState[deviceId]!
        }
        else {
            //Error occured on hardware
            return 99
        }
    }
    
    func getdeviceLedSetting(deviceChannelNumber:Int)->Int{
        
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        
        
        let deviceId = self.channelAssignment[deviceChannelNumber-1]
        
        if deviceLed[deviceId] != nil {
            return deviceLed[deviceId]!
        }
        else {
            //Error occured on hardware
            return 99
        }
    }
    
    func getdeviceBattery(deviceChannelNumber:Int)->Int{
        
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        
        
        let deviceId = self.channelAssignment[deviceChannelNumber-1]
        
        if deviceBattery[deviceId] != nil {
            return deviceBattery[deviceId]!
        }
        else {
            //Error occured on hardware
            return 0
        }
    }
    
    func getdeviceGain(deviceChannelNumber:Int)->Int {
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        
        
        
        let deviceId = self.channelAssignment[deviceChannelNumber-1]
        
        if deviceAmplifierGain[deviceId] != nil {
            return deviceAmplifierGain[deviceId]!
        }
        else {
            //Error occured on hardware
            return 0
        }
        
    }
    
    func getdeviceInterval(deviceChannelNumber:Int)->Int {
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        
        
        
        let deviceId = self.channelAssignment[deviceChannelNumber-1]
        
        if deviceInterval[deviceId] != nil {
            return deviceInterval[deviceId]!
        }
        else {
            //Error occured on hardware
            return 0
        }
        
    }
    
    
    
    func getdeviceLEDStatus(deviceChannelNumber:Int)->[Bool] {
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        
        
        let deviceId = self.channelAssignment[deviceChannelNumber-1]
        
        if deviceLEDEnableStatus[deviceId] != nil {
            return deviceLEDEnableStatus[deviceId]!
        }
        else {
            //Error occured on hardware
            return [true, true, true, true]
        }
        
    }
    
    
    
    func startup()
    {
        if(self.centralManager==nil){
            self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: " Central "])
            // self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey : "CBCentralManagerRestorationKey"])
        }
        
        //PairingViewController
        
    }
    
    
    
    
    func startScanning()
    {
        let uuids: [CBUUID] = [serviceUUID]
        self.centralManager.scanForPeripherals(withServices: uuids, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        
        self.connectionTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(connectionTimerAction), userInfo: nil, repeats: true)
    }
    
    
    func connectionTimerAction() {
        
        if !self.connectionTimingCache.isEmpty {
            
            for key in self.connectionTimingCache.keys {
                
                
                
                if (self.connectionTimingCache[key]! >= 0) {
                    if !self.deviceDevicesUniqueId.keys.contains(key) {
                        self.connectionTimingCache[key]! -= 1
                    }
                }
                else {
                    print ("device out of range or powered off")
                    let peripheral = self.sensorPeripheral[key]
                    self.connectionTimingCache.removeValue(forKey: key)
                    //self.sensorPeripheral.removeValue(forKey: key)
                    
                    if peripheral != nil {
                        
                        
                        self.centralManager.cancelPeripheralConnection(self.sensorPeripheral[key]!)
                        
                        
                        self.removePeripheralData(peripheral: peripheral!)
                        
                        
                        
                        
                    }
                    
                    
                }
                
                //print(self.connectionTimingCache)
                
                
            }
            
            
        }
        
        
        
        if !self.deviceDevicesUniqueId.isEmpty {
            
            for key in self.deviceDevicesUniqueId.keys {
                
                let peripheral = self.sensorPeripheral[key]
                
                //print ("connected peripheral state is \(peripheral?.state)")
                
                //peripheral?.readRSSI()
                if peripheral?.state != CBPeripheralState.connected {
                    self.removePeripheralData(peripheral: peripheral!)
                    self.connectionTimingCache.removeValue(forKey: key)
                }
                
            }
            
        }
        
        
        //print ("connection cache is \(self.connectionTimingCache)")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print ("RSSI is \(RSSI)")
        print ("error is \(error)")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        
        if central.state != .poweredOn
        {
            return
        }
        self.startScanning()
        
        
        //////Preservation + Restoration code////////
        
        let keysArray = Array(self.deviceDevicesUniqueId.keys)
        for i in 0..<keysArray.count {
            if let peripheral = self.sensorPeripheral[keysArray[i]]{
                
                print("peripheral exists")
                
                if let services = peripheral.services {
                    
                    print("services exist")
                    
                    if let serviceIndex = services.index(where: {$0.uuid == serviceUUID}) {
                        
                        print("serviceUUID exists within services")
                        
                        let transferService = services[serviceIndex]
                        let characteristicUUID = streamingCharacteristicUUID
                        
                        if let characteristics = transferService.characteristics {
                            
                            print("characteristics exist within serviceUUID")
                            
                            if let characteristicIndex = characteristics.index(where: {$0.uuid == characteristicUUID}) {
                                
                                print("characteristcUUID exists within serviceUUID")
                                
                                let characteristic = characteristics[characteristicIndex]
                                
                                if !characteristic.isNotifying {
                                    
                                    print("subscribe if not notifying already")
                                    peripheral.setNotifyValue(true, for: characteristic)
                                }
                                else {
                                    
                                    print("invoke discover characteristics")
                                    peripheral.discoverCharacteristics([characteristicUUID], for: transferService)
                                }
                                
                            }
                            
                            
                        }
                        
                    }
                    else {
                        print("invoke discover characteristics")
                        peripheral.discoverServices([serviceUUID])
                    }
                    
                }
                
            }
        }
    }
    
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        
        self.connectionTimingCache.updateValue(8, forKey: peripheral.identifier)
        
        
        if(self.sensorPeripheral[peripheral.identifier] == nil){
            
            print("BLE Found peripheral")
            
            print("peripheral is \(peripheral)")
            
            
            
            guard let peripheralName = peripheral.name else {
                print ("peripheral name error ")
                return
            }
            
            
            self.sensorPeripheral.updateValue(peripheral, forKey: peripheral.identifier)
            self.sensorNames.updateValue(peripheral.name!, forKey: peripheral.identifier)
            self.sensorPeripheral[peripheral.identifier]?.delegate = self
            
            
            print("Device found - UUID is \(peripheral.identifier)")
            
            handleDidAddDevice()
            
            
            
            //////Handle automatic reconnect if it is a previously connected device that failed unintentionally
            
            
            
            if self.reconnectingDevicesUniqueId.keys.contains(peripheral.identifier) {
                
                //see if nothing else is connected to the original channel
                if self.channelsConnected[self.reconnectingDevicesUniqueId[peripheral.identifier]!] == false {
                    
                    print ("reconnecting device if needed")
                    //Issue reconnect command if not already
                    if (peripheral.state != .connecting) || (peripheral.state != .connected) {
                        self.intendedIndex(index: self.reconnectingDevicesUniqueId[peripheral.identifier]!)
                        self.centralManager.connect(peripheral, options: nil)
                    }
                    
                    
                }
                    //if something is connected, then forget about previous connection
                else {
                    self.reconnectingDevicesUniqueId.removeValue(forKey: peripheral.identifier)
                }
                
            }
            
            
        }else{
            // Already connected to the peripheral
            // print("BLE peripheral already connected")
            
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        print("test: connected to sensor")
        
        // Just connected to the peripheral now discover the services in the peripheral
        peripheral.discoverServices(nil)
        
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        
        self.connectionTimingCache.updateValue(8, forKey: peripheral.identifier)
        print ("analyzing services")
        for service in peripheral.services!
        {
            let thisService = service
            
            if (thisService.uuid == serviceUUID)
            {
                // Service has been discovered, find the characteristics for the service
                peripheral.discoverCharacteristics(nil, for: thisService)
            }
        }
    }
    
    
    func intendedIndex (index: Int) {
        print("setting intended index as \(index)")
        intendedPairingIndex = index
    }
    
    func setUnintentionalDisconnectStatus (status:Bool, index: Int) {
        self.unintentionalDisconnect[index] = status
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        self.connectionTimingCache.updateValue(8, forKey: peripheral.identifier)
        var foundCmdChar = false
        
        // Find the peripheral position in the array to match where the characteristics are matched
        if(self.sensorPeripheral[peripheral.identifier] != nil){
            
            for charateristic in service.characteristics!
            {
                let thisCharacteristic = charateristic
                
                if (thisCharacteristic.uuid == streamingCharacteristicUUID)
                {
                    self.charStreaming.updateValue(thisCharacteristic, forKey: peripheral.identifier)
                }
                else if (thisCharacteristic.uuid == commandResponseCharacteristicUUID)
                {
                    self.sensorPeripheral[peripheral.identifier]?.setNotifyValue(true, for: thisCharacteristic)
                    self.charCommandResponse.updateValue(thisCharacteristic, forKey: peripheral.identifier)
                    print ("discovered command response is \(thisCharacteristic)")
                    foundCmdChar=true
                }
                
            }
            
            // Determine what the ID is for the device
            if(foundCmdChar){
                getStatus(uuid: peripheral.identifier)
                
            }
        }
        
        
        
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        
        self.removePeripheralData(peripheral: peripheral)
        
        if(sensorCount>0){
            sensorCount -= 1
        }
        
    }
    
    
    
    func removePeripheralData ( peripheral: CBPeripheral) {
        
        if self.sensorPeripheral.keys.contains(peripheral.identifier) {
            self.sensorPeripheral.removeValue(forKey: peripheral.identifier)
        }
        
        if self.sensorNames.keys.contains(peripheral.identifier) {
            self.sensorNames.removeValue(forKey: peripheral.identifier)
        }
        
        if self.charStreaming.keys.contains(peripheral.identifier) {
            self.charStreaming.removeValue(forKey: peripheral.identifier)
        }
        
        
        if self.charCommandResponse.keys.contains(peripheral.identifier) {
            self.charCommandResponse.removeValue(forKey: peripheral.identifier)
        }
        
        
        
        if self.deviceDevicesUniqueId.keys.contains(peripheral.identifier){
            self.deviceDevicesUniqueId.removeValue(forKey: peripheral.identifier)
        }
        
        
        if self.channelAssignment.contains(peripheral.identifier){
            let index = self.channelAssignment.index(of: peripheral.identifier)
            
            self.channelsConnected[index!] = false
            
            //handle unintentional disconnect
            if self.unintentionalDisconnect[index!] == true {
                
                print ("unintentional disconnect detected")
                
                self.reconnectingDevicesUniqueId.updateValue(index!, forKey: peripheral.identifier)
                
                //Issue reconnect command
                print ("issuing reconnect command")
                centralManager.connect(peripheral, options: nil)
                
            }
                
            else {
                self.channelAssignment[index!] = NSUUID() as UUID
                self.unintentionalDisconnect[index!] = true
            }
            
        }
        
        handleDidRemoveDevice()
    }
    
    
    private func getUUIDKeyForValue (value: String, dictionary: [UUID:String]) -> UUID {
        let keyArray = Array(dictionary.keys)
        var targetedUUID:UUID = UUID()
        for i in 0 ..< keyArray.count{
            if dictionary[keyArray[i]] == value {
                targetedUUID = keyArray[i]
            }
        }
        return targetedUUID
    }
    
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        self.connectionTimingCache.updateValue(8, forKey: peripheral.identifier)
        
        if (characteristic.uuid == streamingCharacteristicUUID)
            
        {
            
            guard let deviceId = deviceDevicesUniqueId[peripheral.identifier] else {
                print ("deviceID error")
                return
            }
            
            guard let dataRaw = characteristic.value else {
                print ("rawdata error")
                return
            }
            
            let data = dataRaw as! Data
            
            let key = getUUIDKeyForValue(value: deviceId, dictionary: BleService.shared.deviceDevicesUniqueId)
            guard let channel = channelAssignment.index(of: key) else {
                print ("channel assignment error")
                print ("channel assignment dict is \(channelAssignment)")
                print ("key is \(key)")
                return
            }
            print ("channel assignment dict is \(channelAssignment)")
            print ("key is \(key)")
            //
            //            let connecteddeviceID = BleService.shared.sensorNames[BleService.shared.channelAssignment[channel]]
            //  print ("connecteddeviceID is \(connecteddeviceID)")
            //let truncateddeviceID = String(connecteddeviceID!.characters.suffix(4))
            
            
            var deviceData = PAdeviceData.deviceData(from: data, device: deviceId, channel: Int32(channel) )
            
            //var deviceData = PAdeviceData.deviceData(from: data, device: truncateddeviceID, channel: Int32(channel) )
            
            // TODO: sometimes device provides invalid timestamp
            //
            
            
            //            deviceData.oxygen = PAdeviceDataPostProcessor.calculateOxygen(data: deviceData)
            //
            //            if deviceData.oxygen >= 0 {
            //deviceData.timestamp = NSDate()
            
            
            handleDidReceiveData(data: deviceData)
            
            print("BLE Service Streaming Data Found for device " + deviceId)
            // }
            
        }
        if (characteristic.uuid == commandResponseCharacteristicUUID)
        {
            guard let data = characteristic.value else {
                print("characteristic error")
                return
            }
            
            // Check for response back first byte of the data
            var responseCode: UInt8 = 0
            if let value = UInt8(data: data.subdata(in: 0 ..< 1)) {
                responseCode = value
            }
            
            switch(responseCode){
            case RSP_GET_STATUS:
                
                print("BLE Status Response")
                
                // Construct a byte array for the unique id set it initally with all zeros
                // var byteArray = [UInt8](repeating: 0x0, count: 8)
                // var range:NSRange=NSMakeRange(1, 8);
                // Read the unique id into the array
                // data.copyBytes(to: &byteArray, from: range)
                
                //                guard UInt8(data: data.subdata(in: 1 ..< 9)) != nil else {
                //                    return
                //                }
                
                let byteArray = data.subdata(in: 1 ..< 9).toArray(type: UInt8.self)
                // Convert the hex values into a string
                var hexString = "" as String
                for value in byteArray {
                    hexString += NSString(format: "%02x", value) as String
                }
                
                // Get the state
                var state: UInt8 = 0
                // range.location=9
                // range.length=1
                if let value = UInt8(data: data.subdata(in: 9 ..< 10)) {
                    state = value
                }
                
                // Get the LED Setting
                var led: UInt8 = 0
                // range.location=10
                // range.length=1
                if let value = UInt8(data: data.subdata(in: 10 ..< 11)) {
                    led = value
                }
                
                //Get the Battery Level
                var battery: UInt8 = 0
                // range.location=10
                // range.length=1
                if data.count >= 12 {
                    if let value = UInt8(data: data.subdata(in: 11 ..< 12)) {
                        battery = value
                    }
                }
                
                //Get Amplifier Gain Level
                var amplifier: UInt8 = 0
                if data.count >= 13 {
                    if let value = UInt8(data: data.subdata(in: 12 ..< 13)) {
                        amplifier = value
                        
                    }
                }
                
                // Get Sampling Interval
                
                var interval: Int = 0
                var intervalString = "" as String
                if data.count >= 15 {
                    
                    //                    guard UInt8(data: data.subdata(in: 13 ..< 15)) != nil else {
                    //                        return
                    //                    }
                    
                    let intervalArray = data.subdata(in: 13 ..< 15).toArray(type: UInt8.self)
                    // Convert the hex values into a string
                    
                    for value in intervalArray {
                        intervalString += NSString(format: "%02x", value) as String
                    }
                }
                
                interval = (Int(intervalString, radix: 16)!)/256
                print ("sampling interval is \(interval)")
                //interval = Int(intervalString)!
                
                // print ("interval is \(interval)")
                
                
                //interval = Int(hexString)!
                
                
                //                var interval: Int = 1
                //                if data.count >= 15 {
                //                    if let value = Int(data: data.subdata(in: 13 ..< 15)) {
                //                        interval = value
                //                    }
                //                    print ("interval is \(interval)")
                //                }
                
                
                
                //Get LED Enable Status
                var enabledStatus: UInt8 = 0
                var LED1:Bool = true
                var LED2:Bool = true
                var LED3:Bool = true
                var LED4:Bool = true
                
                if data.count >= 16 {
                    if let value = UInt8(data: data.subdata(in: 15 ..< 16)) {
                        enabledStatus = value
                        
                    }
                    
                    let firstString = String(enabledStatus, radix:2)
                    
                    let enabledString = firstString.leftPadding(toLength: 4, withPad: "0")
                    
                    print ("LED status string is \(enabledString)")
                    
                    let index4 = enabledString.index(enabledString.startIndex, offsetBy: 0)
                    let index3 = enabledString.index(enabledString.startIndex, offsetBy: 1)
                    let index2 = enabledString.index(enabledString.startIndex, offsetBy: 2)
                    let index1 = enabledString.index(enabledString.startIndex, offsetBy: 3)
                    
                    if enabledString[index1] == "0" {
                        LED1 = false
                    }
                    if enabledString[index2] == "0" {
                        LED2 = false
                    }
                    if enabledString[index3] == "0" {
                        LED3 = false
                    }
                    if enabledString[index4] == "0" {
                        LED4 = false
                    }
                    
                }
                
                // Update values to store the state for each device
                self.deviceState.updateValue(Int(state), forKey: peripheral.identifier)
                self.deviceLed.updateValue(Int(led), forKey: peripheral.identifier)
                self.deviceBattery.updateValue(Int(battery), forKey: peripheral.identifier)
                self.deviceAmplifierGain.updateValue(Int(amplifier), forKey: peripheral.identifier)
                self.deviceInterval.updateValue(Int(interval), forKey: peripheral.identifier)
                self.deviceLEDEnableStatus.updateValue([LED1, LED2, LED3, LED4], forKey: peripheral.identifier)
                
                
                
                
                
                
                // Check if this device id has been added before
                
                
                if !self.deviceDevicesUniqueId.keys.contains(peripheral.identifier) {
                    
                    print("device ID: " + hexString)
                    
                    self.deviceDevicesUniqueId.updateValue(hexString, forKey: peripheral.identifier)
                    
                    //remove auto-reconnect protocol if in place
                    
                    if self.reconnectingDevicesUniqueId.keys.contains(peripheral.identifier) {
                        self.reconnectingDevicesUniqueId.removeValue(forKey: peripheral.identifier)
                    }
                    
                    
                    print ("unique device devices are \(self.deviceDevicesUniqueId)")
                    
                    if(!self.channelAssignment.contains(peripheral.identifier)){
                        // There is no channel assigned yet, find out where it can be added
                        var isChannelFoundEmpty=false
                        
                        
                        // Pair to intended index
                        self.channelAssignment[self.intendedPairingIndex]=peripheral.identifier
                        self.channelsConnected[self.intendedPairingIndex] = true
                        
                        print ("channel assignment is \(self.channelAssignment)")
                        isChannelFoundEmpty = true
                        
                        
                        
                    }else{
                        // Channel could have been assigned from a previous connect
                    }
                    
                    
                    // Set notification to get data updates
                    self.sensorPeripheral[peripheral.identifier]?.setNotifyValue(true, for: self.charStreaming[peripheral.identifier]!)
                    
                    self.sensorCount += 1
                    // Send updates to anyone listening to see if there new items
                    handleDidAddDevice()
                    
                    if(sensorCount <= MAX_CONNECTED_SENSORS){
                        // self.startScanning()
                    }
                }
                
                // Send updates to anyone listening for the status updates
                handleDidReceiveStatus()
                
            case RSP_SET_CLOCK:
                print("BLE Set Clock Response")
                
            case RSP_MEASURE:
                print("BLE Measure Response")
                // Get the status
                getStatus(uuid: peripheral.identifier)
                
            case RSP_LED_POWER:
                print("BLE LED Response")
                // Get the status
                getStatus(uuid: peripheral.identifier)
                
                
            case RSP_LOCATE:
                print("BLE Locate Response")
                // Get the status
                getStatus(uuid: peripheral.identifier)
                
            case RSP_SET_INTERVAL:
                print("BLE Interval Response")
                // Get the interval
                getStatus(uuid: peripheral.identifier)
                
            case RSP_SET_AMPLIFIER:
                print ("BLE Interval Response")
                // Get the interval
                getStatus(uuid: peripheral.identifier)
                
            case RSP_SET_SINGLE_LED:
                print ("BLE Interval Response")
                // Get the interval
                getStatus(uuid: peripheral.identifier)
                
            case RSP_RESET:
                print ("BLE Reset Response")
                getStatus(uuid: peripheral.identifier)
                
                
            default:
                print("Invalid Response Code")
                
            }
            
            
            
        }
    }
    
    
    
    
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if(characteristic.uuid == commandResponseCharacteristicUUID){
            // Check response codes
            print("Command Response Received")
        }
    }
    
    func getStatus(uuid:UUID){
        
        //  let translatedIndex = self.indexTranslate.index(of: indexOfItem)
        var dataInteger=NSInteger(CMD_GET_STATUS)
        let dataToSend:NSData=NSData(bytes: &dataInteger, length: 1)
        
        if self.charCommandResponse[uuid] != nil {
            self.sensorPeripheral[uuid]?.writeValue(dataToSend as Data, for: self.charCommandResponse[uuid]!, type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    
    
    func setClock(uuid:UUID){
        
        //let translatedIndex = self.indexTranslate.index(of: indexOfItem)
        var dataInteger=NSInteger(CMD_SET_CLOCK)
        // Get the current unix time
        var date:Int32 = Int32(NSDate().timeIntervalSince1970)
        date = date.byteSwapped
        
        let dataToSend = NSMutableData(bytes: &dataInteger, length: 1)
        dataToSend.append(&date, length: 4)
        print("BLE Set Clock "+String(describing: dataToSend))
        
        if self.charCommandResponse[uuid] != nil {
            self.sensorPeripheral[uuid]?.writeValue(dataToSend as Data, for: self.charCommandResponse[uuid]!, type: CBCharacteristicWriteType.withoutResponse)
        }
        
    }
    
    
    func setSampling(isSamplingOn:Bool, channelNumber:Int){
        
        //let translatedIndex = self.indexTranslate.index(of: channelNumber)
        
        var dataInteger=NSInteger(CMD_MEASURE)
        // Get the current unix time
        var date:Int32 = Int32(NSDate().timeIntervalSince1970)
        date = date.byteSwapped
        
        var value:UInt8
        let dataToSend=NSMutableData(bytes: &dataInteger, length: 1)
        if(isSamplingOn){
            value=0x1
            dataToSend.append(&value, length: 1)
        }else{
            value=0x0
            dataToSend.append(&value, length: 1)
        }
        
        dataToSend.append(&date, length: 4)
        
        print("BLE Set Measure/Clock "+String(describing: dataToSend))
        
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        let deviceId = self.channelAssignment[channelNumber-1]
        
        
        if self.sensorPeripheral.keys.contains(deviceId){
            if self.charCommandResponse[deviceId] != nil {
                self.sensorPeripheral[deviceId]?.writeValue(dataToSend as Data, for: self.charCommandResponse[deviceId]!, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
        
    }
    
    func setLocating(isLoactingOn:Bool, channelNumber:Int){
        
        var dataInteger=NSInteger(CMD_LOCATE)
        
        /*
         // Get the current unix time
         var date:Int32 = Int32(NSDate().timeIntervalSince1970)
         date = date.byteSwapped
         */
        
        var value:UInt8
        let dataToSend=NSMutableData(bytes: &dataInteger, length: 1)
        if(isLoactingOn){
            value=0x1
            dataToSend.append(&value, length: 1)
        }else{
            value=0x0
            dataToSend.append(&value, length: 1)
        }
        
        //   dataToSend.appendBytes(&date, length: 4)
        
        // print("BLE Set Measure/Clock "+String(dataToSend))
        
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        let deviceId = self.channelAssignment[channelNumber-1]
        
        if self.sensorPeripheral.keys.contains(deviceId){
            if self.charCommandResponse[deviceId] != nil {
                if self.charCommandResponse[deviceId] != nil {
                    self.sensorPeripheral[deviceId]?.writeValue(dataToSend as Data, for: self.charCommandResponse[deviceId]!, type: CBCharacteristicWriteType.withoutResponse)
                }
            }
        }
        
    }
    
    func setLedPower(powerValue:UInt8, channelNumber:Int){
        
        var value = powerValue
        var dataInteger=NSInteger(CMD_LED_POWER)
        let dataToSend=NSMutableData(bytes: &dataInteger, length: 1)
        dataToSend.append(&value, length: 1)
        
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        let deviceId = self.channelAssignment[channelNumber-1]
        if self.sensorPeripheral.keys.contains(deviceId){
            if self.charCommandResponse[deviceId] != nil {
                self.sensorPeripheral[deviceId]?.writeValue(dataToSend as Data, for: self.charCommandResponse[deviceId]!, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
        
    }
    
    func setSampleInterval(interval: Int, channelNumber:Int) {
        var samplingInterval = interval.littleEndian
        var dataInteger = NSInteger(CMD_SET_INTERVAL)
        let dataToSend = NSMutableData(bytes: &dataInteger, length: 1)
        dataToSend.append(&samplingInterval, length:2)
        
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        let deviceId = self.channelAssignment[channelNumber-1]
        if self.sensorPeripheral.keys.contains(deviceId){
            if self.charCommandResponse[deviceId] != nil {
                self.sensorPeripheral[deviceId]?.writeValue(dataToSend as Data, for: self.charCommandResponse[deviceId]!, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
    }
    
    func setAmplifierGain(gain: UInt8, channelNumber:Int) {
        var value = gain
        var dataInteger=NSInteger(CMD_SET_AMPLIFIER)
        let dataToSend=NSMutableData(bytes: &dataInteger, length: 1)
        dataToSend.append(&value, length: 1)
        
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        let deviceId = self.channelAssignment[channelNumber-1]
        if self.sensorPeripheral.keys.contains(deviceId){
            if self.charCommandResponse[deviceId] != nil {
                self.sensorPeripheral[deviceId]?.writeValue(dataToSend as Data, for: self.charCommandResponse[deviceId]!, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
    }
    
    
    
    
    func setSingleLED(isOn: Bool, ledNumber: UInt8, channelNumber:Int){
        
        var dataInteger=NSInteger(CMD_SET_SINGLE_LED)
        
        let dataToSend=NSMutableData(bytes: &dataInteger, length: 1)
        
        var powerValue = ledNumber
        dataToSend.append(&powerValue, length: 1)
        
        var value:UInt8
        
        if(isOn){
            value = UInt8(1)
            dataToSend.append(&value, length: 1)
        }else{
            value = UInt8(0)
            dataToSend.append(&value, length: 1)
        }
        
        let deviceId = self.channelAssignment[channelNumber-1]
        if self.sensorPeripheral.keys.contains(deviceId){
            if self.charCommandResponse[deviceId] != nil {
                self.sensorPeripheral[deviceId]?.writeValue(dataToSend as Data, for: self.charCommandResponse[deviceId]!, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
        
    }
    
    
    func setAllLED(isOn: Bool, channelNumber:Int){
        
        var dataInteger=NSInteger(CMD_SET_SINGLE_LED)
        
        let dataToSend=NSMutableData(bytes: &dataInteger, length: 1)
        
        var powerValue = 0xFF
        dataToSend.append(&powerValue, length: 1)
        
        var value:UInt8
        
        if(isOn){
            value=0x1
            dataToSend.append(&value, length: 1)
        }else{
            value=0x2
            dataToSend.append(&value, length: 1)
        }
        
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        let deviceId = self.channelAssignment[channelNumber-1]
        if self.sensorPeripheral.keys.contains(deviceId){
            if self.charCommandResponse[deviceId] != nil {
                self.sensorPeripheral[deviceId]?.writeValue(dataToSend as Data, for: self.charCommandResponse[deviceId]!, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
    }
    
    func resetdevice(fullReset: Bool, channelNumber:Int) {
        var value:UInt8 = 0
        if fullReset == true {
            value = UInt8(1)
        }
        else {
            value = UInt8(0)
        }
        var dataInteger=NSInteger(CMD_RESET)
        let dataToSend=NSMutableData(bytes: &dataInteger, length: 1)
        dataToSend.append(&value, length: 1)
        
        // Get the channel number, subtract 1 since from UI perspecitve things start at 1 not 0
        let deviceId = self.channelAssignment[channelNumber-1]
        if self.sensorPeripheral.keys.contains(deviceId){
            if self.charCommandResponse[deviceId] != nil {
                self.sensorPeripheral[deviceId]?.writeValue(dataToSend as Data, for: self.charCommandResponse[deviceId]!, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
    }
    
    
    
    
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        
        
        if let peripheralsObject = dict[CBCentralManagerRestoredStatePeripheralsKey] {
            let peripherals = peripheralsObject as! Array<CBPeripheral>
            
            print ("starting restorestate code")
            if peripherals.count > 0 {
                
                for i in 0 ..< peripherals.count {
                    print ("starting restorecheck")
                    if self.deviceDevicesUniqueId.keys.contains(peripherals[i].identifier) {
                        print ("check 0")
                        peripherals[i].delegate = self
                    }
                }
            }
        }
        
        
        
    }
    
    
    
    
    
}
