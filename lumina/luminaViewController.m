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
static NSString * const ledUUID =         @"03032000-0303-0303-0303-030303030303";
static NSString * const temperatureUUID = @"03032001-0303-0303-0303-030303030303";
static NSString * const pressureUUID =    @"03032002-0303-0303-0303-030303030303";
@interface luminaViewController ()
@property (weak, nonatomic) IBOutlet UIButton *conectar;
@property (weak, nonatomic) IBOutlet UITextView *console;
@property BOOL buttonState;
@property (weak, nonatomic) IBOutlet UILabel *valorRSSI;
@property (weak, nonatomic) IBOutlet UILabel *valorTemperatura;
@property (weak, nonatomic) IBOutlet UILabel *valorPresion;
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

- (IBAction)readTemperature:(UIButton *)sender {

    if (self.peripheral.isConnected) {

        for ( CBService *service in self.peripheral.services ) {
            for ( CBCharacteristic *characteristic in service.characteristics )
            {
                NSLog(@"Caracteristica: %@",characteristic.UUID);
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:temperatureUUID]])
                {
                    /* Activate Notification ! */
                    [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:pressureUUID]])
                {
                    /* Activate Notification ! */
                    [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
        
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
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:ledUUID]])
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
    //[self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,@"Desconectado..."]];
    [self.console setText:@""];
    self.valorRSSI.text=@"0";
    self.valorTemperatura.text=@"0";
    self.valorPresion.text=@"0";
}


 - (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error {
        if (error) {
            NSLog(@"Error discovering service: %@", [error localizedDescription]);
              return;
        }
        for (CBService *service in aPeripheral.services)
        {
            NSLog(@"Service found with UUID: %@", service.UUID);
            // Discovers the characteristics for a given service
            if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]])
            {
              [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:ledUUID]] forService:service];
              [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:temperatureUUID]] forService:service];
              [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:pressureUUID]] forService:service];
            }
        }
    }



- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        //[self cleanup];
        return;
    }
    if ([service.UUID isEqual:[CBUUID UUIDWithString:temperatureUUID]])
     {
        for (CBCharacteristic *characteristic in service.characteristics)
          {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:temperatureUUID]])
            {
                NSLog(@"Discover characteristics for temperature");
                //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
                [peripheral readValueForCharacteristic:characteristic];
            }
          }
            
    }
    if ([service.UUID isEqual:[CBUUID UUIDWithString:pressureUUID]])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:temperatureUUID]])
            {
                NSLog(@"Discover characteristics for pressure");
                //[peripheral setNotifyValue:YES forCharacteristic:characteristic];
                [peripheral readValueForCharacteristic:characteristic];
            }
        }
        
    }

}


- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSString *rssiValue;
    [self.peripheral readRSSI];
    rssiValue=[NSString stringWithFormat:@"%d",self.peripheral.RSSI.intValue];
    self.valorRSSI.text=rssiValue;
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:temperatureUUID]]) {
        [self.peripheral readValueForCharacteristic:characteristic];
        NSData *data = characteristic.value;
        NSLog(@"UPDATED DATA:%@", data);
        if(data!=nil)
        {
        const unsigned *tokenBytes = [data bytes];

        NSString *hexToken = [NSString stringWithFormat:@"%08x",
                                  ntohl(tokenBytes[0])];

        NSString *t1 = [hexToken substringWithRange:NSMakeRange(0,2)];
        NSString *t2 = [hexToken substringWithRange:NSMakeRange(2,2)];
        NSString *t3 = [hexToken substringWithRange:NSMakeRange(4,2)];
        NSString *t4 = [hexToken substringWithRange:NSMakeRange(6,2)];
           
        unsigned int outVal;
        NSScanner* scanner = [NSScanner scannerWithString:t1];
        [scanner scanHexInt:&outVal];
        unsigned char b0 = outVal;
        //NSLog(@"Dec t1:%d",b0);
        scanner = [NSScanner scannerWithString:t2];
        [scanner scanHexInt:&outVal];
        unsigned char b1 = outVal;
        //NSLog(@"Dec t2:%d",b1);
        scanner = [NSScanner scannerWithString:t3];
        [scanner scanHexInt:&outVal];
         unsigned char b2 = outVal;
        //NSLog(@"Dec t3:%d",b2);
        scanner = [NSScanner scannerWithString:t4];
        [scanner scanHexInt:&outVal];
        unsigned char b3 = outVal;

            unsigned long d;
            unsigned int index;
            index=0;
            
            d =  (b0 << 24) | (b1 << 16)| (b2 << 8) | (b3);
            
            float member = *(float *)&d;
            NSLog(@"Temperatura: %f",member);

         self.valorTemperatura.text=[[NSString alloc] initWithFormat:@"%.2f",member];
     }
    }
 //pressure reading
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:pressureUUID]]) {
        [self.peripheral readValueForCharacteristic:characteristic];
        NSData *data = characteristic.value;
        NSLog(@"UPDATED DATA:%@", data);
        if(data!=nil)
        {
            const unsigned *tokenBytes = [data bytes];
            
            NSString *hexToken = [NSString stringWithFormat:@"%08x",
                                  ntohl(tokenBytes[0])];
            
            NSString *t1 = [hexToken substringWithRange:NSMakeRange(0,2)];
            NSString *t2 = [hexToken substringWithRange:NSMakeRange(2,2)];
            NSString *t3 = [hexToken substringWithRange:NSMakeRange(4,2)];
            NSString *t4 = [hexToken substringWithRange:NSMakeRange(6,2)];
            
            unsigned int outVal;
            NSScanner* scanner = [NSScanner scannerWithString:t1];
            [scanner scanHexInt:&outVal];
            unsigned char b0 = outVal;
            //NSLog(@"Dec t1:%d",b0);
            scanner = [NSScanner scannerWithString:t2];
            [scanner scanHexInt:&outVal];
            unsigned char b1 = outVal;
            //NSLog(@"Dec t2:%d",b1);
            scanner = [NSScanner scannerWithString:t3];
            [scanner scanHexInt:&outVal];
            unsigned char b2 = outVal;
            //NSLog(@"Dec t3:%d",b2);
            scanner = [NSScanner scannerWithString:t4];
            [scanner scanHexInt:&outVal];
            unsigned char b3 = outVal;
            
            unsigned long d;
            unsigned int index;
            index=0;
            
            d =  (b0 << 24) | (b1 << 16)| (b2 << 8) | (b3);
            
            float member = *(float *)&d;
            NSLog(@"Presion: %f",member);
            
            self.valorPresion.text=[[NSString alloc] initWithFormat:@"%.2f",member];
        }
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exits if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:temperatureUUID]]) {
        return;
    }
   
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
        [peripheral readValueForCharacteristic:characteristic];
        NSData *data = characteristic.value;
        NSLog(@"DATOS LUEGO DE NOTIFICACION:%@", data);
    } else { // Notification has stopped
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
}


@end
