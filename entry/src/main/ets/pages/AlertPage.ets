import { router } from '@kit.ArkUI';
import { dataManager, SensorData, AlertThreshold, AlertRecord } from '../services/DataManager';

interface AlertItem {
  name: string;
  minValue: number;
  maxValue: number;
  currentValue: number;
  unit: string;
  isAlert: boolean;
}

@Entry
@Component
struct AlertPage {
  @State alertList: AlertItem[] = [];
  @State alertHistory: AlertRecord[] = [];

  aboutToAppear(): void {
    this.initAlertList();
    this.alertHistory = dataManager.getAlertHistory();

    dataManager.setDataCallback((data: SensorData) => {
      this.updateCurrentValues(data);
    });

    dataManager.setAlertCallback((alert: AlertRecord) => {
      this.alertHistory = dataManager.getAlertHistory();
    });
  }

  private initAlertList(): void {
    const thresholds = dataManager.getThresholds();
    const currentData = dataManager.getCurrentData();
    
    const nameMap: (name: string) => string = (name: string) => {
      if (name === 'temperature') return '温度';
      if (name === 'humidity') return '湿度';
      if (name === 'soilMoisture') return '土壤湿度';
      if (name === 'lightLevel') return '光照强度';
      if (name === 'waterLevel') return '水位';
      if (name === 'co2') return 'CO2浓度';
      return name;
    };

    const getValue = (name: string): number => {
      if (name === 'temperature') return currentData.temperature;
      if (name === 'humidity') return currentData.humidity;
      if (name === 'soilMoisture') return currentData.soilMoisture;
      if (name === 'lightLevel') return currentData.lightLevel;
      if (name === 'waterLevel') return currentData.waterLevel;
      if (name === 'co2') return currentData.co2;
      return 0;
    };

    const newList: AlertItem[] = [];
    for (let i = 0; i < thresholds.length; i++) {
      const t = thresholds[i];
      const value = getValue(t.name);
      const newItem: AlertItem = {
        name: nameMap(t.name),
        minValue: t.minValue,
        maxValue: t.maxValue,
        currentValue: value,
        unit: t.unit,
        isAlert: value < t.minValue || value > t.maxValue
      };
      newList.push(newItem);
    }
    this.alertList = newList;
  }

  private updateCurrentValues(data: SensorData): void {
    const newList: AlertItem[] = [];
    for (let i = 0; i < this.alertList.length; i++) {
      const item = this.alertList[i];
      let value = item.currentValue;
      
      if (item.name === '温度') value = data.temperature;
      else if (item.name === '湿度') value = data.humidity;
      else if (item.name === '土壤湿度') value = data.soilMoisture;
      else if (item.name === '光照强度') value = data.lightLevel;
      else if (item.name === '水位') value = data.waterLevel;
      else if (item.name === 'CO2浓度') value = data.co2;

      const newItem: AlertItem = {
        name: item.name,
        minValue: item.minValue,
        maxValue: item.maxValue,
        currentValue: value,
        unit: item.unit,
        isAlert: value < item.minValue || value > item.maxValue
      };
      newList.push(newItem);
    }
    this.alertList = newList;
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
          Text('阈值预警')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20 });
        }
        .width('90%')
        .margin({ top: 20, bottom: 30 });

        Column() {
          Text('预警状态')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 });

          Row() {
            ForEach(this.alertList, (item: AlertItem) => {
              Circle({ width: 12, height: 12 })
                .fill(item.isAlert ? '#F44336' : '#4CAF50')
                .margin({ right: 5 });
            });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center);

          Text(this.hasAlert() ? '存在异常' : '系统正常')
            .fontSize(14)
            .fontColor(this.hasAlert() ? '#F44336' : '#4CAF50')
            .margin({ top: 5 });
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFE0B2')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Column({ space: 10 }) {
          ForEach(this.alertList, (item: AlertItem, index: number) => {
            this.AlertItemCard(item, index);
          });
        }
        .width('90%');

        Button('刷新数据')
          .width('90%')
          .height(50)
          .backgroundColor('#2196F3')
          .onClick(() => {
            this.initAlertList();
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

  hasAlert(): boolean {
    for (let i = 0; i < this.alertList.length; i++) {
      if (this.alertList[i].isAlert) {
        return true;
      }
    }
    return false;
  }

  private updateThreshold(index: number, minVal: number, maxVal: number): void {
    const item = this.alertList[index];
    const nameToKey = (name: string): string => {
      if (name === '温度') return 'temperature';
      if (name === '湿度') return 'humidity';
      if (name === '土壤湿度') return 'soilMoisture';
      if (name === '光照强度') return 'lightLevel';
      if (name === '水位') return 'waterLevel';
      if (name === 'CO2浓度') return 'co2';
      return name;
    };
    dataManager.updateThreshold(nameToKey(item.name), minVal, maxVal);
  }

  @Builder
  AlertItemCard(item: AlertItem, index: number) {
    Column() {
      Row() {
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium);
        Blank();
        if (item.isAlert) {
          Text('异常')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#F44336')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(10);
        }
      }
      .width('100%');

      Row() {
        Text(`当前: ${item.currentValue.toFixed(1)}${item.unit}`)
          .fontSize(14);
        Blank();
        Text(`范围: ${item.minValue}-${item.maxValue}${item.unit}`)
          .fontSize(12)
          .fontColor('#888888');
      }
      .width('100%')
      .margin({ top: 8 });

      Row() {
        Text('下限:')
          .fontSize(12);
        TextInput({ text: item.minValue.toString() })
          .type(InputType.Number)
          .width(60)
          .height(30)
          .fontSize(12)
          .onChange((value: string) => {
            const minVal = parseInt(value) || 0;
            this.alertList[index].minValue = minVal;
            this.updateThreshold(index, minVal, item.maxValue);
          });
        Text('上限:')
          .fontSize(12)
          .margin({ left: 10 });
        TextInput({ text: item.maxValue.toString() })
          .type(InputType.Number)
          .width(60)
          .height(30)
          .fontSize(12)
          .onChange((value: string) => {
            const maxVal = parseInt(value) || 0;
            this.alertList[index].maxValue = maxVal;
            this.updateThreshold(index, item.minValue, maxVal);
          });
      }
      .width('100%')
      .margin({ top: 10 });
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFE0B2')
    .borderRadius(10);
  }
}
