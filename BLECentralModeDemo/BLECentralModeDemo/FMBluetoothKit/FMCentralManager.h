//
//  FMCentralManager.h
//  BLECentralModeDemo
//
//  Created by yfm on 2022/6/2.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void(^FMCentralManagerDidUpdateStateBlock)(CBCentralManager *centralManager);
typedef void(^FMDidDiscoverPeripheralBlock)(CBCentralManager *centralManager, CBPeripheral *peripheral, NSDictionary<NSString *,id> *advertisementData, NSNumber *RSSI);

NS_ASSUME_NONNULL_BEGIN

@interface FMCentralManager : NSObject

- (instancetype)initWithQueue:(dispatch_queue_t)queue centralManagerDidUpdateStateBlock:(FMCentralManagerDidUpdateStateBlock)centralManagerDidUpdateStateBlock;
- (instancetype)initWithQueue:(dispatch_queue_t)queue options:(nullable NSDictionary<NSString *, id> *)options centralManagerDidUpdateStateBlock:(FMCentralManagerDidUpdateStateBlock)centralManagerDidUpdateStateBlock;
- (void)scan:(NSArray<CBUUID *> *)uuids;
- (void)stopScan;
- (void)connect;
- (void)disconnect;

@property (nonatomic, copy) FMDidDiscoverPeripheralBlock didDiscoverPeripheralBlock;

@end

NS_ASSUME_NONNULL_END
