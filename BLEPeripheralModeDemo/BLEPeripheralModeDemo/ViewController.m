//
//  ViewController.m
//  BLPeripheralVC
//
//  Created by yfm on 2022/5/30.
//
//  外设模式

/**
 1.启动外围设备管理器对象
 2.在本地外围设备上设置服务和特征
 3.将服务和特征发布到设备的本地数据库
 4.广播服务
 5.响应来自中心的读写请求
 6.将更新的特征值发送到订阅中心
 */

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

NSString *const SERVICE_UUID = @"C477CBCA-BBA8-42EF-A5F9-782BF2E09822";
NSString *const WRITE_UUID = @"CDB49AF3-6B35-4102-AEE7-7398D1C46210";
NSString *const NOTIFY_UUID = @"CDB49AF3-6B35-4102-AEE7-7398D1C46211";

@interface ViewController () <CBPeripheralManagerDelegate>
@property (nonatomic) CBPeripheralManager *peripheralManager;
@property (nonatomic) CBMutableService *service;
@property (nonatomic) CBMutableCharacteristic *writeCharateristic;
@property (nonatomic) CBMutableCharacteristic *notifyCharateristic;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self startUpPeripheralManager];
}

// 1.启动外围设备管理器对象
- (void)startUpPeripheralManager {
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

// 2.在本地外围设备上设置服务和特征
- (void)setupServiceAndCharateristic {
    self.writeCharateristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:WRITE_UUID] properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    self.notifyCharateristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:NOTIFY_UUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    self.service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:SERVICE_UUID] primary:YES];
    self.service.characteristics = @[self.writeCharateristic,
                                     self.notifyCharateristic];
}

// 3.将服务和特征发布到设备的本地数据库
- (void)publishServiceAndCharateristic {
    [self.peripheralManager addService:self.service];
}

// 4.广播服务
- (void)startAdvertise {
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[self.service.UUID]}];
}

#pragma mark - delegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if(peripheral.state == CBManagerStatePoweredOn) {
        [self setupServiceAndCharateristic];
        [self publishServiceAndCharateristic];
        [self startAdvertise];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if(error) {
        NSLog(@"Error advertising: %@", [error localizedDescription]);
    }
}

// 6.将更新的特征值发送到订阅中心
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"Central subscribed to characteristic %@", characteristic);
}

// 5.响应来自中心的读写请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    NSLog(@"didReceiveReadRequest");
    if(request.characteristic.properties & CBCharacteristicPropertyRead) {
        if([request.characteristic.UUID isEqual:self.notifyCharateristic.UUID]) {
            if(request.offset > self.notifyCharateristic.value.length) {
                [self.peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
                return;
            }
            
            request.value = [self.notifyCharateristic.value subdataWithRange:NSMakeRange(request.offset, self.notifyCharateristic.value.length - request.offset)];
            
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        } else if([request.characteristic.UUID isEqual:self.writeCharateristic.UUID]){
            if(request.offset > self.writeCharateristic.value.length) {
                [self.peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
                return;
            }
            
            request.value = [self.writeCharateristic.value subdataWithRange:NSMakeRange(request.offset, self.writeCharateristic.value.length - request.offset)];
            
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        }
    } else {
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorReadNotPermitted];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
    NSLog(@"didReceiveWriteRequests %@", requests);
    CBATTRequest *request = requests.firstObject;
    if(request.characteristic.properties & CBCharacteristicPropertyWrite) {
        CBMutableCharacteristic *c = (CBMutableCharacteristic *)request.characteristic;
        c.value = request.value;
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        [self.peripheralManager updateValue:request.value forCharacteristic:request.characteristic onSubscribedCentrals:@[request.central]];
    } else {
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorReadNotPermitted];
    }
}

#pragma mark -
static int i = 0;
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    Byte byte[] = {i};
    NSData *data = [NSData dataWithBytes:byte length:1];
    // 向中心发送数据，更新特征值
    [self.peripheralManager updateValue:data forCharacteristic:self.notifyCharateristic onSubscribedCentrals:nil];
    i++;
}

@end
