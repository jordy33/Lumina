//
//  luminaViewController.m
//  lumina
//
//  Created by Jorge Macias on 8/21/13.
//  Copyright (c) 2013 Jorge Macias. All rights reserved.
//

#import "luminaViewController.h"
static NSString * const kServiceUUID =
@"03031000-0303-0303-0303-030303030303";
static NSString * const kCharacteristicUUID = @"03032003-0303-0303-0303-030303030303";
@interface luminaViewController ()
@property (weak, nonatomic) IBOutlet UIButton *conectar;
@property (weak, nonatomic) IBOutlet UITextView *console;
@property BOOL buttonState;
@property (weak, nonatomic) IBOutlet UILabel *valorRSSI;
@end

@implementation luminaViewController

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            // CoreBluetooth BLE hardware is powered off
            [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Hardware apagado"]];
            break;
        case CBCentralManagerStatePoweredOn:
            // CoreBluetooth BLE hardware is powered on and ready
            [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Hardware listo"]];
            break;
        case CBCentralManagerStateResetting:
            // CoreBluetooth BLE hardware is resetting
            [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Hardware reset"]];
            break;
        case CBCentralManagerStateUnauthorized:
            // CoreBluetooth BLE state is unauthorized
            [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Estado sin autorizar"]];
            break;
        case CBCentralManagerStateUnknown:
            // CoreBluetooth BLE state is unknown 
            [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Estado desconocido"]];
            break;
        case CBCentralManagerStateUnsupported:
            // CoreBluetooth BLE hardware is unsupported on this platform
            [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Esta plataforma no soporta BLE"]];
            break;
        default:
            break;
    }
}
- (IBAction)readRSSIButton:(UIButton *)sender {
    NSString *rssiValue;
    
    if (self.peripheral.isConnected) {
        [self.peripheral readRSSI];
        rssiValue=[NSString stringWithFormat:@"%d",self.peripheral.RSSI.intValue];
        self.valorRSSI.text=rssiValue;
    }
}

- (IBAction)ledSwitch:(UISwitch *)sender {
    unsigned char data;
    if (sender.isOn)
        data = 0x01;
    else
        data = 0x00;
    NSData *paso=[NSData dataWithBytes:&data length:1];
    for ( CBService *service in self.peripheral.services ) {
        for ( CBCharacteristic *characteristic in service.characteristics ) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]])
            {
                /* EVERYTHING IS FOUND, WRITE characteristic ! */
                NSLog(@"Encontre Caracteristica de servicio: %@",characteristic);
                [self.peripheral writeValue:paso forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
            }
        }
    }
        
}

- (IBAction)connectButton:(UIButton *)sender {
 if(!self.buttonState)
 {
    [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Escaneando..."]];
     [sender setTitle:@"Desconectar" forState:UIControlStateNormal];
     self.buttonState=YES;
     [self.manager scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:kServiceUUID] ] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
     //If YES, multiple discoveries of the same peripheral are coalesced into a single discovery event.
 }
 else
 {
    if (self.peripheral.isConnected)
        [self.manager cancelPeripheralConnection:self.peripheral];
    self.buttonState=NO;
         [self.peripheral readRSSI];

 }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // initialize object
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.buttonState=NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    //Do something when a peripheral is discovered.
    [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Encontre periferico"]];
    // Stops scanning for peripheral (saves battery)
    [self.manager stopScan];
    [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Escaneo terminado"]];
    // Connects to the discovered peripheral
    if (self.peripheral != peripheral) {
        self.peripheral = peripheral;
        NSLog(@"Did discover peripheral. peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral, RSSI, peripheral.UUID, advertisementData);
        [self.manager connectPeripheral:peripheral options:nil];
        [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Conectando al periferico"]];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    //Do something after successfull connection.
    // Clears the data that we may already have
    [self.data setLength:0];
    // Sets the peripheral delegate
    [self.peripheral setDelegate:self];
    // Asks the peripheral to discover the service
    [self.peripheral discoverServices:@[ [CBUUID UUIDWithString:kServiceUUID] ]];
    [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Conectado..."]];
     NSLog(@"Connection successfull to peripheral: %@ with UUID: %@",peripheral,peripheral.UUID);
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral     *)peripheral error:(NSError *)error{
    [self.conectar setTitle:@"Conectar" forState:UIControlStateNormal];
    self.peripheral=nil;
    [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Desconectado..."]];
}


- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error {
    NSString *serviceName;
    if (error) {
        [self.conectar setTitle:@"Error al descubrir servicios" forState:UIControlStateNormal];
        return;
    }
    for (CBService *service in aPeripheral.services) {
        serviceName=[NSString stringWithFormat:@"%@:%@",@"Servicio encontrado",service.UUID];
        [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,serviceName]];
        
        // Discovers the characteristics for a given service
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kCharacteristicUUID]] forService:service];
        }
    }
}
/*
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        //[self cleanup];
        return;
    }
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}
*/
@end
