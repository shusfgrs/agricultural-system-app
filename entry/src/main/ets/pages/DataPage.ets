import { router } from '@kit.ArkUI';
import { dataManager, SensorData } from '../services/DataManager';
import { bleService } from '../services/BleService';

@Entry
@Component
struct DataPage {
  @State isConnected: boolean = false;
  @State temperature: number = 25;
  @State humidity: number = 65;
  @State soilMoisture: number = 45;
  @State lightLevel: number = 300;
  @State waterLevel: number = 75;
  @State co2: number = 450;

  aboutToAppear(): void {
    this.isConnected = bleService.getConnectionStatus();
    
    const initialData = dataManager.getCurrentData();
    this.temperature = initialData.temperature;
    this.humidity = initialData.humidity;
    this.soilMoisture = initialData.soilMoisture;
    this.lightLevel = initialData.lightLevel;
    this.waterLevel = initialData.waterLevel;
    this.co2 = initialData.co2;

    dataManager.setDataCallback((data: SensorData) => {
      this.temperature = data.temperature;
      this.humidity = data.humidity;
      this.soilMoisture = data.soilMoisture;
      this.lightLevel = data.lightLevel;
      this.waterLevel = data.waterLevel;
      this.co2 = data.co2;
      this.isConnected = bleService.getConnectionStatus();
    });
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
          Text('环境数据查询')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20 });
        }
        .width('90%')
        .margin({ top: 20, bottom: 30 });

        Column() {
          Text('设备状态')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 });

          Row() {
            Text('蓝牙状态: ')
              .fontSize(14);
            Text(this.isConnected ? '已连接' : '未连接')
              .fontSize(14)
              .fontColor(this.isConnected ? '#4CAF50' : '#F44336')
              .fontWeight(FontWeight.Medium);
          }

          if (!this.isConnected) {
            Text('当前为模拟数据模式')
              .fontSize(12)
              .fontColor('#FF9800')
              .margin({ top: 5 });
          }
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFE0B2')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Text('当前环境数据')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 15 });

        Column({ space: 10 }) {
          this.DataItem('温度', `${this.temperature.toFixed(1)}°C`, '环境温度');
          this.DataItem('湿度', `${this.humidity.toFixed(0)}%`, '空气湿度');
          this.DataItem('土壤湿度', `${this.soilMoisture.toFixed(0)}%`, '土壤水分含量');
          this.DataItem('CO2浓度', `${this.co2.toFixed(0)}ppm`, '二氧化碳浓度');
          this.DataItem('光照强度', `${this.lightLevel.toFixed(0)}lux`, '光照强度');
          this.DataItem('水位', `${this.waterLevel.toFixed(0)}%`, '水箱水位');
        }
        .width('90%');

        Button('刷新数据')
          .width('90%')
          .height(50)
          .backgroundColor('#2196F3')
          .onClick(() => {
            const data = dataManager.getCurrentData();
            this.temperature = data.temperature;
            this.humidity = data.humidity;
            this.soilMoisture = data.soilMoisture;
            this.lightLevel = data.lightLevel;
            this.waterLevel = data.waterLevel;
            this.co2 = data.co2;
          })
          .margin({ top: 20, bottom: 30 });
      }
      .width('100%')
      .backgroundColor('#FFA726');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFA726')
    .scrollBar(BarState.Auto);
  }

  @Builder
  DataItem(title: string, value: string, desc: string) {
    Row({ space: 10 }) {
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium);
        Text(desc)
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 3 });
      }
      .alignItems(HorizontalAlign.Start)
      .align(Alignment.Center);

      Blank();

      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .align(Alignment.Center);
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFE0B2')
    .borderRadius(10)
    .alignItems(VerticalAlign.Center);
  }
}