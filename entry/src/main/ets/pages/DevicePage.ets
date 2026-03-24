import { router } from '@kit.ArkUI';
import { bleService, BleDevice } from '../services/BleService';

@Entry
@Component
struct DevicePage {
  @State isScanning: boolean = false;
  @State connectedDevice: BleDevice | null = null;
  @State deviceList: BleDevice[] = [];
  @State isConnected: boolean = false;

  aboutToAppear(): void {
    this.isConnected = bleService.getConnectionStatus();
    if (this.isConnected) {
      const deviceId = bleService.getConnectedDeviceId();
      if (deviceId) {
        this.connectedDevice = {
          deviceId: deviceId,
          deviceName: '已连接设备',
          rssi: 0
        };
      }
    }
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('<')
            .fontSize(24)
            .onClick(() => {
              router.back();
            });
          Text('设备管理')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20 });
        }
        .width('90%')
        .margin({ top: 20, bottom: 30 });

        Column() {
          Text('蓝牙状态')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 });

          Row() {
            Circle({ width: 12, height: 12 })
              .fill(this.isConnected ? '#4CAF50' : '#F44336');
            Text(this.isConnected ? '已连接' : '未连接')
              .fontSize(14)
              .margin({ left: 8 });
          }

          if (this.connectedDevice) {
            Text(`已连接: ${this.connectedDevice.deviceName}`)
              .fontSize(12)
              .fontColor('#888888')
              .margin({ top: 5 });
          }
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFE0B2')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Row() {
          Text('设备列表')
            .fontSize(16)
            .fontWeight(FontWeight.Medium);
          Blank();
          if (this.isScanning) {
            LoadingProgress()
              .width(20)
              .height(20);
            Text('扫描中...')
              .fontSize(12)
              .fontColor('#888888')
              .margin({ left: 5 });
          }
        }
        .width('90%')
        .margin({ bottom: 10 });

        if (this.deviceList.length === 0 && !this.isScanning) {
          Text('暂无设备，请点击扫描')
            .fontSize(14)
            .fontColor('#888888')
            .margin({ top: 20 });
        }

        Column({ space: 10 }) {
          ForEach(this.deviceList, (device: BleDevice, index: number) => {
            this.DeviceItem(device, index);
          });
        }
        .width('90%');

        Button(this.isScanning ? '扫描中...' : '扫描设备')
          .width('90%')
          .height(50)
          .backgroundColor('#2196F3')
          .enabled(!this.isScanning)
          .onClick(() => {
            this.scanDevices();
          })
          .margin({ top: 20, bottom: 15 });

        if (this.isConnected) {
          Button('断开连接')
            .width('90%')
            .height(50)
            .backgroundColor('#F44336')
            .onClick(() => {
              this.disconnect();
            })
            .margin({ bottom: 30 });
        }
      }
      .width('100%')
      .backgroundColor('#FFA726');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFA726')
    .scrollBar(BarState.Auto);
  }

  async scanDevices(): Promise<void> {
    this.isScanning = true;
    this.deviceList = [];

    const success = await bleService.startScan((devices: BleDevice[]) => {
      this.deviceList = devices;
    });

    if (!success) {
      console.error('Failed to start BLE scan');
    }

    setTimeout(async () => {
      await bleService.stopScan();
      this.isScanning = false;
    }, 5000);
  }

  async connectDevice(device: BleDevice): Promise<void> {
    const success = await bleService.connect(device.deviceId);
    if (success) {
      this.connectedDevice = device;
      this.isConnected = true;
    }
  }

  async disconnect(): Promise<void> {
    await bleService.disconnect();
    this.connectedDevice = null;
    this.isConnected = false;
  }

  @Builder
  DeviceItem(device: BleDevice, index: number) {
    Row() {
      Column() {
        Text(device.deviceName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium);
        Text(device.deviceId)
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 3 });
        Text(`信号强度: ${device.rssi} dBm`)
          .fontSize(10)
          .fontColor('#AAAAAA')
          .margin({ top: 2 });
      }
      .alignItems(HorizontalAlign.Start);

      Blank();

      if (this.connectedDevice && this.connectedDevice.deviceId === device.deviceId) {
        Text('已连接')
          .fontSize(12)
          .fontColor('#4CAF50');
      } else {
        Button('连接')
          .fontSize(12)
          .height(30)
          .backgroundColor('#2196F3')
          .onClick(() => {
            this.connectDevice(device);
          });
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFE0B2')
    .borderRadius(10);
  }
}
