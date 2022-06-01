//
//  ViewController.m
//  BLCentralVC
//
//  Created by yfm on 2022/5/30.
//
//  中心模式
/**
 1.启动中央管理器
 2.发现并连接正在广播的外围设备
 3.连接到外围设备后探索外围设备上的数据
 4.向外围服务的特征值发送读写请求
 5.订阅特征值以在更新时得到通知
 */

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

NSString *const SERVICE_UUID = @"C477CBCA-BBA8-42EF-A5F9-782BF2E09822";
NSString *const WRITE_UUID = @"CDB49AF3-6B35-4102-AEE7-7398D1C46210";
NSString *const NOTIFY_UUID = @"CDB49AF3-6B35-4102-AEE7-7398D1C46211";

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) CBCentralManager *centralManager;
@property (nonatomic) CBPeripheral *connectedPeripheral;
@property (nonatomic) CBService *service;
@property (nonatomic) CBCharacteristic *writeCharacteristic;
@property (nonatomic) CBCharacteristic *notifyCharacteristic;

@property (nonatomic) NSMutableArray<CBPeripheral *> *discoverPeripherals;
@property (nonatomic) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _discoverPeripherals = @[].mutableCopy;
    [self startUpCentralManager];
    
    CGRect rect = self.view.bounds;
    rect.size = CGSizeMake(rect.size.width, rect.size.height - 400);
    self.tableView = [[UITableView alloc] initWithFrame:rect];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];
}

// 1.启动中央管理器
- (void)startUpCentralManager {
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

// 2.发现并连接正在广播的外围设备
- (void)discoverDevice {
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]
                                                options:nil];
}

- (BOOL)existPeripheral:(CBPeripheral *)peripheral {
    BOOL exist = NO;
    for(CBPeripheral *p in self.discoverPeripherals) {
        if([p.name isEqualToString:peripheral.name]) {
            exist = YES;
        }
    }
    
    return exist;
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if(central.state == CBManagerStatePoweredOn) {
        [self discoverDevice];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    // 3.连接到外围设备后探索外围设备上的数据
    NSLog(@"%@", peripheral.name);
    if(peripheral.name.length > 0) {
        if(![self existPeripheral:peripheral]) {
            [self.discoverPeripherals addObject:peripheral];
            [self.tableView reloadData];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"已连接");
    self.connectedPeripheral = peripheral;
    self.connectedPeripheral.delegate = self;
    
    // 探索外围设备上的数据
    CBUUID *serviceUUID = [CBUUID UUIDWithString:SERVICE_UUID];
    [self.connectedPeripheral discoverServices:@[serviceUUID]];
    
    [self.centralManager stopScan];
    [self.tableView reloadData];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"断开连接");
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"连接失败");
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for(CBService *service in peripheral.services) {
        if([service.UUID.UUIDString isEqualToString:SERVICE_UUID]) {
            self.service = service;
            
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:WRITE_UUID],
                                                  [CBUUID UUIDWithString:NOTIFY_UUID]]
                                     forService:self.service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for(CBCharacteristic *characteristic in service.characteristics) {
        if([characteristic.UUID.UUIDString isEqualToString:WRITE_UUID]) {
            NSLog(@"发现write特征 %@", characteristic);
            self.writeCharacteristic = characteristic;
        } else if([characteristic.UUID.UUIDString isEqualToString:NOTIFY_UUID]) {
            NSLog(@"发现notify特征 %@", characteristic);
            self.notifyCharacteristic = characteristic;
        }
    }
    // 5.订阅特征值以在更新时得到通知
    if(self.notifyCharacteristic) {
        [peripheral setNotifyValue:YES forCharacteristic:self.notifyCharacteristic];
    }
}

//当订阅一个特征的值时，外围设备会调用该委托方法
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if(error) {
        NSLog(@"Error changing notification state %@ %@", error, characteristic);
    }
}

// 成功订阅值后，外围设备会在值发生更改时通知您的应用
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSData *data = characteristic.value;
    NSLog(@"外设特征值更新 特征=%@ 值=%@", characteristic, data);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if(error) {
        NSLog(@"Error writing characteristic value: %@", [error localizedDescription]);
    } else {
        NSLog(@"写外设值成功 %@", characteristic);
//        [peripheral readValueForCharacteristic:characteristic]; // 读特征值，会响应didUpdateValueForCharacteristic方法
    }
}

- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
    NSLog(@"peripheralIsReadyToSendWriteWithoutResponse");
}

#pragma mark -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.discoverPeripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    CBPeripheral *peripheral = self.discoverPeripherals[indexPath.row];
    cell.textLabel.text = peripheral.name;
    if(peripheral.state == CBPeripheralStateConnected) {
        cell.textLabel.textColor = UIColor.redColor;
    } else {
        cell.textLabel.textColor = UIColor.blackColor;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBPeripheral *peripheral = self.discoverPeripherals[indexPath.row];
    if(peripheral.state == CBPeripheralStateDisconnected) {
        [self.centralManager connectPeripheral:peripheral options:nil];
    } else {
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
    [self.tableView reloadData];
}

#pragma mark -
static int i = 0;
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    Byte byte[] = {i};
    NSData *data = [NSData dataWithBytes:byte length:1];
    // 向中心发送数据，更新特征值
    [self.connectedPeripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
    i++;
}

@end
