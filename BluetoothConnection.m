//
//  BluetoothConnection.m
//  beanControll
//
//  Created by WatanabeYoichiro on 2014/12/07.
//  Copyright (c) 2014年 YoichiroWatanabe. All rights reserved.
//

#import "BluetoothConnection.h"


@implementation BluetoothConnection 

#pragma mark - Constructor
-(id)init{
    self = [super init];
    if (self) {
        //instantiate CBCentral Manager
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
        _batteryServiceUUID = [CBUUID UUIDWithString:kBatteryServiceUUID];
        _batteryServiceCharacteristicsUUID = [CBUUID UUIDWithString:kBatteryCharUUID];
        
        _scratch1ServiceUUID = [CBUUID UUIDWithString:kScratch1ServiceUUID];
        _scratch1ServiceCharacteristicsUUID = [CBUUID UUIDWithString:kScratch1CharUUID];
    }
    NSLog(@"%s","Initialized");
    return self;
};


#pragma mark - Public methods

-(void)startScanning{
    if (!_isBTPoweredOn || _isScanning) {
        NSLog(@"%s","BT is off or scannning");
        return;
    }
    // BLEデバイスのスキャン時には、検索対象とするサービスを指定することが推奨です
    //NSArray *scanServices = [NSArray arrayWithObjects:_batteryServiceUUID, nil];
    // スキャンにはオプションが指定できます。いまあるオプションは、ペリフェラルを見つけた時に重複して通知するか、の指定です。
    // 近接検出など、コネクションレスでデバイスの状態を取得する用途などでは、これをYESに設定します。デフォルトでNOです。
    NSDictionary *scanOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                                forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    //Start scanning
    [_centralManager scanForPeripheralsWithServices:nil options:scanOptions];
    self.isScanning = YES;
    NSLog(@"%s", "Central Started scanning...");
};

-(CBCharacteristic *)findCharacteristics:(NSArray *)cs uuid:(CBUUID *)uuid
{
    for (CBCharacteristic *c in cs) {
        if ([c.UUID.data isEqualToData:uuid.data]) {
            return c;
        }
    }
    return nil;
}


-(void)stopScanning{
    // if isScanning is NO
    if (!_isScanning) {
        return;
    }
    //if isScanning is YES
    [_centralManager stopScan];
    self.isScanning = NO;
};

-(void)disconnect{
    //if peripheral is not connected
    if (_peripheral == nil) {
        return;
    }
    [_centralManager cancelPeripheralConnection:_peripheral];
};

-(void)disconnectIntrinsic {
    [self stopScanning];
    
    self.isScanning  = NO;
    self.isConnected = NO;
    
    _peripheral = nil;
    _batteryServiceCharacteristics = nil;
    _scratch1ServiceCharacteristics = nil;
    
    self.batteryLevel = 0;
    self.deviceRSSI = 0;
    self.scratch1Data = 0;
}

#pragma mark CBCentralManagerDelegate
//自動で呼び出される系のメソッドはhogehoge Delegateとしてタイミングが決められているので、中身を自分で定義するだけでいい
// optional
/*
 - (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals;
 - (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals;
 
 */
//notify chaneged BT's switch state on or off
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch ([_centralManager state]) {
        case CBCentralManagerStatePoweredOff:
            // Bluetoothの電源がOffのとき、iOSが、ONが必要なメッセージと設定画面に飛ぶダイアログを、アプリ起動時に自動表示してくれる
            self.isBTPoweredOn  = NO;
            self.isScanning    = NO;
            self.isConnected    = NO;
            break;
        case CBCentralManagerStatePoweredOn:
            self.isBTPoweredOn  = YES;
            NSLog(@"%s","BTPoweredOn");
            break;
        case CBCentralManagerStateResetting:
            break;
        case CBCentralManagerStateUnauthorized:
            //Tell user the app is not allowed
            break;
        case CBCentralManagerStateUnknown:
            //Bad news, wait for another event
            break;
        case CBCentralManagerStateUnsupported:
            //BLE is not supported for this device
            break;

    }
    
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (_peripheral != nil) {
        NSLog(@"%s", "Already connected");
        return;
    }
    NSLog(@"%s", "Discovered peripheral");
    
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if (localName != nil) {
        //ターゲットを発見、接続します
        //この時点でperipheralはcentral managerに保持されていません。少なくとも接続が完了するまでの間、peripheralをアプリ側で保持します。
        //接続処理はタイムアウトしません。接続に失敗すれば centralManager:didFailToConnectPeripheral:error: が呼ばれます。
        //接続処理を中止するには、peripheralを開放するか、明示的に cancelPeripheralConnection を呼び出します。
        _peripheral = peripheral;
        [central connectPeripheral:_peripheral options:nil];
        [self stopScanning];
    } else {
        NSLog(@"%s","Device name is nil");
        NSLog(@"%@", localName);
    }
}

//Connect to peripheral
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"%s", "Connected to peripheral");
    NSLog(@"%s", "Searching services");
    _peripheral.delegate = self;
    self.isConnected = YES;
    [peripheral discoverServices:[NSArray arrayWithObjects:_batteryServiceUUID, _scratch1ServiceUUID,
                                  nil]];
}

//Failed to connect to peripheral
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral
                error:(NSError *)error{
    //Reset all properties
    NSLog(@"%s","Failed to connect");
    [self disconnectIntrinsic];
}

//Disconnected with peripheral
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                error:(NSError *)error {
    [self disconnectIntrinsic];
}

#pragma mark CBPeripheralDelegate
//Searching characteristics on found Services
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        if ([service.UUID.data isEqualToData:_batteryServiceUUID.data]) {
            [peripheral discoverCharacteristics:[NSArray arrayWithObjects:_batteryServiceCharacteristicsUUID, nil] forService:service]; //ここ間違えてて1時間はまった
            NSLog(@"%s", "Discovered battery service");
        } else if ([service.UUID.data isEqualToData:_scratch1ServiceUUID.data]){
            [peripheral discoverCharacteristics:[NSArray arrayWithObjects:_scratch1ServiceCharacteristicsUUID, nil] forService:service];
            NSLog(@"%s", "Discovered scratch1 service");
        }
    }//end for
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if ([service.UUID.data isEqualToData:_batteryServiceUUID.data]) {
        _batteryServiceCharacteristics = [self findCharacteristics:service.characteristics uuid:_batteryServiceCharacteristicsUUID];
        [peripheral readValueForCharacteristic:_batteryServiceCharacteristics];
        NSLog(@"%s", "Discovered battery characteristics");
    } else if ([service.UUID.data isEqualToData:_scratch1ServiceUUID.data]){
        _scratch1ServiceCharacteristics= [self findCharacteristics:service.characteristics uuid:_scratch1ServiceCharacteristicsUUID];
        [peripheral readValueForCharacteristic:_scratch1ServiceCharacteristics];
        NSLog(@"%s", "Discovered scratch1 characteristics");
    }
}
-(void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    self.deviceRSSI = peripheral.RSSI;
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error{
    uint8_t b;
    if (characteristic == _batteryServiceCharacteristics) {
        [characteristic.value getBytes:&b length:1];
        self.batteryLevel = b;
        NSLog(@"%d",self.batteryLevel);
    } else if (characteristic == _scratch1ServiceCharacteristics){
        //something...
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error{
    NSLog(@"%s","Send data to peripheral");
}



#pragma mark - Private methods
//Send data to peripheral and lit up LED
-(void)litUpLED{
    ushort value = 1;
    NSMutableData *data = [NSMutableData dataWithBytes:&value length:2];
    [_peripheral writeValue:data forCharacteristic:_scratch1ServiceCharacteristics type:CBCharacteristicWriteWithoutResponse];
};

@end
