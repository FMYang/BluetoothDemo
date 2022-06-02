//
//  FMCentralManager.m
//  BLECentralModeDemo
//
//  Created by yfm on 2022/6/2.
//

#import "FMCentralManager.h"

@interface FMCentralManager() <CBCentralManagerDelegate>

@property (nonatomic) CBCentralManager *centralManager;
@property (nonatomic, copy) FMCentralManagerDidUpdateStateBlock centralManagerDidUpdateStateBlock;

@end

@implementation FMCentralManager

- (instancetype)initWithQueue:(dispatch_queue_t)queue centralManagerDidUpdateStateBlock:(FMCentralManagerDidUpdateStateBlock)centralManagerDidUpdateStateBlock {
    return [self initWithQueue:queue options:nil centralManagerDidUpdateStateBlock:centralManagerDidUpdateStateBlock];
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue options:(NSDictionary<NSString *, id> *)options centralManagerDidUpdateStateBlock:(FMCentralManagerDidUpdateStateBlock)centralManagerDidUpdateStateBlock {
    if(self = [super init]) {
        _centralManagerDidUpdateStateBlock = centralManagerDidUpdateStateBlock;
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:options];
    }
    return self;
}

#pragma mark - delegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if(self.centralManagerDidUpdateStateBlock) {
        self.centralManagerDidUpdateStateBlock(central);
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if(self.didDiscoverPeripheralBlock) {
        self.didDiscoverPeripheralBlock(central, peripheral, advertisementData, RSSI);
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
}

@end
