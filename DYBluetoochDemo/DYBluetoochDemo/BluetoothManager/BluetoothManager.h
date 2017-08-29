//
//  BluetoothManager.h
//  liancheng
//
//  Created by xingzhi on 16/9/8.
//  Copyright © 2016年 unitedjourney. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef enum : NSUInteger {
    BTValueDiscoverDevice       =   0,  //搜索到设备
    BTValuePowerOn                   ,  //蓝牙开启
    BTValuePowerOff                  ,  //蓝牙关闭
    BTValuePeripheralNotFound        ,  //未连接设备
    BTValueConnectionSuccess         ,  //连接成功
    BTValueConnectionFailure         ,  //连接失败
    BTValueConnectionStop            ,  //断开连接
    BTValueGetService                ,  //获取服务
    BTValueGetCharacteristicsValue   ,  //获取Characteristic
} BTValueType;

@protocol BluetoothManagerDelegate <NSObject>

- (void)bluetoothValueDidExchange:(BTValueType)btValueType withMessage:(NSString *)message;

@end


@interface BluetoothManager : NSObject <CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic, strong) CBService *blueService;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;


/**
    设备号
 */
@property (nonatomic, strong) NSString *deviceNO;
/**
    蓝牙名称
 */
@property (nonatomic, strong) NSString *serialNumber;
/**
    设备key
 */
@property (nonatomic, strong) NSString *deviceKey;

@property (nonatomic, weak) id <BluetoothManagerDelegate> delegate;
@property (nonatomic, assign) BTValueType btValueType;

- (id)init;
/**
    开始扫描
 */
- (void)scanPeripheral;
/**
    结束扫描
 */
- (void)stopScanPeripheral;
/**
    取消扫描
 */
- (void)cancelPeripheral;
/**
    开锁
 */
- (void)openDoor;
/**
    落锁
 */
- (void)lockDoor;
/**
    闪灯
 */
- (void)flashLight;
/**
    获取车辆状态
 */
- (void)getCarStatus;
/**
    用车
 */
- (void)useCar;
/**
    还车
 */
- (void)returnCar;
/**
    开启动力
 */
- (void)startEngine;
/**
    关闭动力
 */
- (void)stopEngine;

@end
