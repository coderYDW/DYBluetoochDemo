//
//  BluetoothManager.m
//  liancheng
//
//  Created by xingzhi on 16/9/8.
//  Copyright © 2016年 unitedjourney. All rights reserved.
//

#import "BluetoothManager.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BluetoothManager ()
{
    CBCentralManager *manager;
    
    NSMutableArray *discoverPeripheralArray;
    
    NSMutableString *carStatusString;
}
@end

@implementation BluetoothManager
@synthesize deviceNO,serialNumber,deviceKey;

- (id)init {
    
    self = [super init];
    if (self) {
        manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        discoverPeripheralArray = [[NSMutableArray alloc] init];
        carStatusString = [NSMutableString string];
//        deviceNO = @"E61636100014";
//        serialNumber = @"UJ_3A49S_93C722";
//        deviceKey = @"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

//        deviceNO = @"123456789017";
//        serialNumber = @"Thread-E60C69AC";
//        deviceKey = @"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    }
    return self;
}


#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@">>>CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@">>>CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@">>>CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@">>>CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@">>>CBCentralManagerStatePoweredOn");
            
            //开始扫描周围的外设
            [central scanForPeripheralsWithServices:nil options:nil];
            if (self.delegate) {
                [self.delegate bluetoothValueDidExchange:BTValuePowerOn withMessage:@"蓝牙已开启"];
            }
            
            break;
        default:
            break;
    }
}

//扫描到设备会进入方法
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    NSString *str = [NSString stringWithFormat:@"扫描到设备:%@",peripheral.name];
    if (self.delegate) {
        [self.delegate bluetoothValueDidExchange:BTValueDiscoverDevice withMessage:str];
    }
    NSLog(@"%@",str);
    //接下连接我们的测试设备，如果你没有设备，可以下载一个app叫lightbule的app去模拟一个设备
    //这里自己去设置下连接规则，我设置的是P开头的设备
    if ([peripheral.name isEqualToString:serialNumber]){

        //找到的设备必须持有它，否则CBCentralManager中也不会保存peripheral，那么CBPeripheralDelegate中的方法也不会被调用！！
        [discoverPeripheralArray addObject:peripheral];
        [central connectPeripheral:peripheral options:nil];
    }
    else {
        
        if ([discoverPeripheralArray containsObject:peripheral]) {
            [central cancelPeripheralConnection:peripheral];
        }
    }

}

//连接到Peripherals-失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSString *str = [NSString stringWithFormat:@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]];
    if (self.delegate) {
        [self.delegate bluetoothValueDidExchange:BTValueConnectionFailure withMessage:str];
    }
    NSLog(@"%@",str);
}

//Peripherals断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSString *str = [NSString stringWithFormat:@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]];
    if (self.delegate) {
        [self.delegate bluetoothValueDidExchange:BTValueConnectionFailure withMessage:str];
    }
    [central scanForPeripheralsWithServices:nil options:nil];
    NSLog(@"%@",str);
}

//连接到Peripherals-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSString *str = [NSString stringWithFormat:@">>>连接到名称为（%@）的设备-成功",peripheral.name];
    if (self.delegate) {
        [self.delegate bluetoothValueDidExchange:BTValueConnectionSuccess withMessage:str];
    }
    NSLog(@"%@",str);
    
    //设置的peripheral委托CBPeripheralDelegate
    [peripheral setDelegate:self];
    //扫描外设Services
    [peripheral discoverServices:nil];
}

//扫描到Services
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    //  NSLog(@">>>扫描到服务：%@",peripheral.services);
    if (error)
    {
        NSLog(@">>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    
    for (CBService *service in peripheral.services) {
        NSLog(@"service:%@",service.UUID);
        if (self.delegate) {
            [self.delegate bluetoothValueDidExchange:BTValueGetService withMessage:[NSString stringWithFormat:@"%@",service.UUID]];
        }
        
        //扫描每个service的Characteristics
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

//扫描到Characteristics
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
    self.peripheral = peripheral;
    self.blueService = service;
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"service:%@ 的 Characteristic: %@",service.UUID,characteristic.UUID);
    }
    
    //获取Characteristic的值
    for (CBCharacteristic *characteristic in service.characteristics){
        {
            [peripheral readValueForCharacteristic:characteristic];
            
            [self notifyCharacteristic:peripheral
                        characteristic:characteristic];
            if(characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse){
                self.characteristic = characteristic;
            }
        }
    }
    
    //搜索Characteristic的Descriptors，
    for (CBCharacteristic *characteristic in service.characteristics){
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
    
    
}

//获取的charateristic的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //打印出characteristic的UUID和值
    //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    if (characteristic.value == NULL)
    {
        NSLog(@"characteristic uuid:%@.",characteristic.UUID);
        
    }
    else
    {
        
        NSString *result = [[NSString alloc] initWithData:characteristic.value  encoding:NSUTF8StringEncoding];
        
        if ([result componentsSeparatedByString:@","].count > 2 &&
            [[result componentsSeparatedByString:@","][2] isEqualToString:@"24"] &&
            [result rangeOfString:@"$E6"].location != NSNotFound &&
            [result rangeOfString:@"\r\n"].location == NSNotFound) {
            [carStatusString appendString:result];
        }
        else if (carStatusString.length > 0 &&
                 [result rangeOfString:@"$E6"].location == NSNotFound &&
                 [result rangeOfString:@"\r\n"].location != NSNotFound) {
            [carStatusString appendString:result];
            if (self.delegate) {
                [self.delegate bluetoothValueDidExchange:BTValueGetCharacteristicsValue withMessage:carStatusString];
            }
            carStatusString = [@"" mutableCopy];
        }
        else {
            
            if (self.delegate) {
                [self.delegate bluetoothValueDidExchange:BTValueGetCharacteristicsValue withMessage:result];
            }
            
        }
        NSLog(@"%@",[NSString stringWithFormat:@"characteristic uuid:%@  value:%@",characteristic.UUID, result]);
    }
}

//搜索到Characteristic的Descriptors
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    //打印出Characteristic和他的Descriptors
    NSLog(@"characteristic uuid:%@",characteristic.UUID);
    for (CBDescriptor *d in characteristic.descriptors) {
        NSLog(@"Descriptor uuid:%@",d.UUID);
    }
    
}
//获取到Descriptors的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    //打印出DescriptorsUUID 和value
    //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
    NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
}

//写数据
-(void)writeCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic
                     value:(NSData *)value{
    
    //打印出 characteristic 的权限
    NSLog(@"%lu", (unsigned long)characteristic.properties);

    //只有 characteristic.properties 有write的权限才可以写
    if(characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse){
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
        
    }else{
        NSLog(@"该字段不可写！");
    }
}

//设置通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    
}

//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

//停止扫描并断开连接
-(void)disconnectPeripheral:(CBCentralManager *)centralManager
                 peripheral:(CBPeripheral *)peripheral{
    //停止扫描
    [centralManager stopScan];
    //断开连接
    [centralManager cancelPeripheralConnection:peripheral];
}

#pragma mark - Action
- (void)scanPeripheral {
    
    [manager scanForPeripheralsWithServices:nil options:nil];
}

- (void)stopScanPeripheral {
    
    [manager stopScan];
}

- (void)cancelPeripheral {
    
    for (CBPeripheral *peripheral in discoverPeripheralArray) {
        self.deviceNO = nil;
        self.serialNumber = nil;
        self.deviceKey = nil;
        [manager cancelPeripheralConnection:peripheral];
        [manager stopScan];
    }
}

- (void)openDoor {
    
    if (manager.state == CBCentralManagerStatePoweredOff) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bluetoothValueDidExchange:withMessage:)]) {
            
            [self.delegate bluetoothValueDidExchange:BTValuePowerOff withMessage:@"请在系统设置中打开蓝牙"];
            return;
        }
    }
    
    if (discoverPeripheralArray && discoverPeripheralArray.count > 0) {
        int count = 0;
        for (int i = 0; i < discoverPeripheralArray.count; i ++) {
            
            CBPeripheral *peripheral = [discoverPeripheralArray objectAtIndex:i];
            
            if ([peripheral.name isEqualToString:serialNumber]) {
                
                if (self.characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
                    
                    NSString *string = [NSString stringWithFormat:@"AT+B01+%@+%@\r\n",deviceNO,deviceKey];

                    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
                    [self writeCharacteristic:self.peripheral characteristic:self.characteristic value:data];
                }
                else {
                    
                    [self showProgressHUDTip];
                }
                break;
            }
            else {
                count ++;
                continue;
            }
        }
        if (count == discoverPeripheralArray.count) {
            [self scanPeripheral];
            [self showProgressHUDTip];
        }
    }
    else {
        
        [self scanPeripheral];
        [self showProgressHUDTip];
    }
}

- (void)lockDoor {
    
    if (manager.state == CBCentralManagerStatePoweredOff) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bluetoothValueDidExchange:withMessage:)]) {
            
            [self.delegate bluetoothValueDidExchange:BTValuePowerOff withMessage:@"请在系统设置中打开蓝牙"];
            return;
        }
    }
    if (discoverPeripheralArray && discoverPeripheralArray.count > 0) {
        int count = 0;
        for (int i = 0; i < discoverPeripheralArray.count; i ++) {
            
            CBPeripheral *peripheral = [discoverPeripheralArray objectAtIndex:i];
            
            if ([peripheral.name isEqualToString:serialNumber]) {
                
                if (self.characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
                    
                    NSString *string = [NSString stringWithFormat:@"AT+B81+%@+%@\r\n",deviceNO,deviceKey];
                    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
                    [self writeCharacteristic:self.peripheral characteristic:self.characteristic value:data];
                }
                else {
                    
                    [self showProgressHUDTip];
                }
                break;
            }
            else {
                count ++;
                continue;
            }
        }
        if (count == discoverPeripheralArray.count) {
            [self scanPeripheral];
            [self showProgressHUDTip];
        }
    }
    else {
        
        [self scanPeripheral];
        [self showProgressHUDTip];
    }
}

- (void)flashLight {

    if (manager.state == CBCentralManagerStatePoweredOff) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bluetoothValueDidExchange:withMessage:)]) {
            
            [self.delegate bluetoothValueDidExchange:BTValuePowerOff withMessage:@"请在系统设置中打开蓝牙"];
            return;
        }
    }
    if (discoverPeripheralArray && discoverPeripheralArray.count > 0) {
        int count = 0;
        for (int i = 0; i < discoverPeripheralArray.count; i ++) {
            
            CBPeripheral *peripheral = [discoverPeripheralArray objectAtIndex:i];
            
            if ([peripheral.name isEqualToString:serialNumber]) {
                
                if (self.characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
                    
                    NSString *string = [NSString stringWithFormat:@"AT+B06+%@+%@\r\n",deviceNO,deviceKey];
                    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
                    [self writeCharacteristic:self.peripheral characteristic:self.characteristic value:data];
                }
                else {
                    
                    [self showProgressHUDTip];
                }
                break;
            }
            else {
                count ++;
                continue;
            }
        }
        if (count == discoverPeripheralArray.count) {
            [self scanPeripheral];
            [self showProgressHUDTip];
        }
    }
    else {
        
        [self scanPeripheral];
        [self showProgressHUDTip];
    }
}
/**
    获取车辆24状态指令
 */
- (void)getCarStatus {
    
    if (self.characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        
        NSString *string = @"ATSTAT\r\n";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self writeCharacteristic:self.peripheral characteristic:self.characteristic value:data];
    }
}
/**
    用车指令
 */
- (void)useCar {
    
    if (manager.state == CBCentralManagerStatePoweredOff) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bluetoothValueDidExchange:withMessage:)]) {
            
            [self.delegate bluetoothValueDidExchange:BTValuePowerOff withMessage:@"请在系统设置中打开蓝牙"];
            return;
        }
    }
    if (self.characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        
        NSString *string = [NSString stringWithFormat:@"ATVEBR=%@\r\n",self.deviceKey];
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self writeCharacteristic:self.peripheral characteristic:self.characteristic value:data];
    }
}
/**
    还车指令
 */
- (void)returnCar {
    
    if (manager.state == CBCentralManagerStatePoweredOff) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bluetoothValueDidExchange:withMessage:)]) {
            
            [self.delegate bluetoothValueDidExchange:BTValuePowerOff withMessage:@"请在系统设置中打开蓝牙"];
            return;
        }
    }
    if (discoverPeripheralArray && discoverPeripheralArray.count > 0) {
        int count = 0;
        for (int i = 0; i < discoverPeripheralArray.count; i ++) {
            
            CBPeripheral *peripheral = [discoverPeripheralArray objectAtIndex:i];
            
            if ([peripheral.name isEqualToString:serialNumber]) {
                
                if (self.characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
                    
                    NSString *string = @"ATVERT\r\n";
                    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
                    [self writeCharacteristic:self.peripheral characteristic:self.characteristic value:data];
                }
                else {
                    
                    [self showProgressHUDTip];
                }
                break;
            }
            else {
                count ++;
                continue;
            }
        }
        if (count == discoverPeripheralArray.count) {
            [self scanPeripheral];
            [self showProgressHUDTip];
        }
    }
    else {
        
        [self scanPeripheral];
        [self showProgressHUDTip];
    }
}
/**
    开启动力
    若设定成功，则返回
    >$E6,0123456789AB,3E,2,OK\r\n
    设置失败或者不可识别的状态，则返回:
    >$E6,0123456789AB,3E,9,ERR0R:122\r\n
 */
- (void)startEngine {

    if (self.characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        
        NSString *string = @"ATENGON\r\n";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self writeCharacteristic:self.peripheral characteristic:self.characteristic value:data];
    }
}
/**
    关闭动力
 */
- (void)stopEngine {
    
    if (self.characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        
        NSString *string = @"ATENGOFF\r\n";
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self writeCharacteristic:self.peripheral characteristic:self.characteristic value:data];
    }
}
/**
    弹窗提示蓝牙未连接
 */
- (void)showProgressHUDTip {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(bluetoothValueDidExchange:withMessage:)]) {
        
        [self.delegate bluetoothValueDidExchange:BTValuePeripheralNotFound withMessage:@"蓝牙订单失败"];
        return;
    }
}

@end
