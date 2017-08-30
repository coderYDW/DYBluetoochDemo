//
//  ViewController.m
//  DYBluetoochDemo
//
//  Created by mac on 2017/8/29.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ViewController.h"
#import "BluetoothManager.h"

@interface ViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) BluetoothManager *bluetoochManager;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *deviceArray;

@end

@implementation ViewController
- (IBAction)startScan:(id)sender {
    
    [self.bluetoochManager scanPeripheral];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"主页";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"device"];
    
}

#pragma mark - 数据源方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.deviceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"device"];
    
    
    
    return cell;
}

#pragma mark - tableView代理方法
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark - 懒加载蓝牙manager
- (BluetoothManager *)bluetoochManager {
    
    if (_bluetoochManager == nil) {
        _bluetoochManager = [[BluetoothManager alloc] init];
    }
    return _bluetoochManager;
}


@end
