//
//  luminaViewController.h
//  lumina
//
//  Created by Jorge Macias on 8/21/13.
//  Copyright (c) 2013 Jorge Macias. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface luminaViewController : UIViewController  
<CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic,strong)
    CBPeripheral *peripheral;
@property (nonatomic,strong)
CBCharacteristic *characteristic;
@property(retain, readonly) NSString *name;
@property(readonly) BOOL isConnected;
@property(retain, readonly) NSNumber *RSSI;

@end



