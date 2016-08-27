//
//  BluetoothConnection.h
//  beanControll
//
//  Created by WatanabeYoichiro on 2014/12/07.
//  Copyright (c) 2014年 YoichiroWatanabe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define kTargetDeviceName       @"Bean"

#define kBatteryServiceUUID     @"180F"
#define kBatteryCharUUID        @"2A19"

#define kScratch1ServiceUUID    @"A495FF20-C5B1-4B44-B512-1370F02D74DE"
#define kScratch1CharUUID       @"A495FF21-C5B1-4B44-B512-1370F02D74DE"

@interface BluetoothConnection : NSObject
//Cental status
@property(nonatomic)BOOL isBTPoweredOn;
@property(nonatomic)BOOL isScanning;
@property(nonatomic)BOOL isConnected;

//RSSI
@property(nonatomic)NSNumber *deviceRSSI;

//Peripheral status
@property(nonatomic)int batteryLevel;
@property(nonatomic)int scratch1Data;

-(void)startScanning;
-(void)stopScanning;
-(void)litUpLED;
-(void)disconnect;
-(void)disconnectIntrinsic;


@end

//Delegateに関する変数は別で書かないと、Delegateが動かない
@interface BluetoothConnection() <CBCentralManagerDelegate, CBPeripheralDelegate>{
    //Central,Peripheral
    CBCentralManager *_centralManager;
    CBPeripheral *_peripheral;
    
    //UUID
    CBUUID *_batteryServiceUUID;
    CBUUID *_scratch1ServiceUUID;
    CBUUID *_batteryServiceCharacteristicsUUID;
    CBUUID *_scratch1ServiceCharacteristicsUUID;
    
    //Characteristics
    CBCharacteristic *_batteryServiceCharacteristics;
    CBCharacteristic *_scratch1ServiceCharacteristics;
}
@end
