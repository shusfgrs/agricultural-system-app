import { router } from '@kit.ArkUI';
import { dataManager, SensorData, IrrigationConfig } from '../services/DataManager';

@Entry
@Component
struct IrrigationPage {
  @State isIrrigationOn: boolean = false;
  @State waterLevel: number = 75;
  @State soilMoisture: number = 45;
  @State temperature: number = 25;
  @State humidity: number = 65;
  @State autoMode: boolean = true;
  @State targetMoisture: number = 50;
  @State cropType: string = 'vegetable';
  @State estimatedWater: number = 0;
  @State estimatedDuration: number = 0;
  @State tankWaterLevel: number = 80;
  @State pumpEfficiency: number = 85;
  @State dayIrrigation: number = 1200;
  @State hourIrrigation: number = 150;
  @State recommendedEfficiency: number = 88;
  @State remainingTime: number = 180;

  aboutToAppear(): void {
    const config = dataManager.getIrrigationConfig();
    this.isIrrigationOn = config.isOn;
    this.autoMode = config.autoMode;
    this.targetMoisture = config.targetMoisture;
    // 修复：从DataManager读取保存的值
    this.tankWaterLevel = config.tankWaterLevel;
    this.pumpEfficiency = config.pumpEfficiency;

    const stats = dataManager.getIrrigationStats();
    this.dayIrrigation = stats.dayIrrigation;
    this.hourIrrigation = stats.hourIrrigation;
    this.recommendedEfficiency = stats.recommendedEfficiency;
    this.remainingTime = stats.remainingTime;

    const currentData = dataManager.getCurrentData();
    this.waterLevel = currentData.waterLevel;
    this.soilMoisture = currentData.soilMoisture;
    this.temperature = currentData.temperature;
    this.humidity = currentData.humidity;

    dataManager.setDataCallback((data: SensorData) => {
      this.waterLevel = data.waterLevel;
      this.soilMoisture = data.soilMoisture;
      this.temperature = data.temperature;
      this.humidity = data.humidity;
      this.calculateWater();
    });

    this.calculateWater();
  }

  build() {
    Scroll() {
      Column() {
        // 标题栏
        Row() {
          Text('<')
            .fontSize(24)
            .onClick(() => {
              router.back();
            });
          Text('智能灌溉')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20 });
        }
        .width('90%')
        .margin({ top: 20, bottom: 30 });

        // 第一行：温度和湿度显示
        Row() {
          // 温度显示方块
          Column() {
            this.InfoSquare('当前温度', `${this.temperature.toFixed(1)}°C`, 'temperature');
            Button('刷新')
              .width('100%')
              .height(30)
              .fontSize(12)
              .backgroundColor('#FF7043') // 胡萝卜色
              .onClick(() => {
                this.refreshTemperature();
              })
              .margin({ top: 8 });
          }
          .width('45%')
          .margin({ right: '5%' });

          // 湿度显示方块
          Column() {
            this.InfoSquare('当前湿度', `${this.humidity.toFixed(1)}%`, 'humidity');
            Button('刷新')
              .width('100%')
              .height(30)
              .fontSize(12)
              .backgroundColor('#2196F3')
              .onClick(() => {
                this.refreshHumidity();
              })
              .margin({ top: 8 });
          }
          .width('45%');
        }
        .width('90%')
        .margin({ bottom: 20 });

        // 水箱水量和水泵能效在同一行显示
        Row({ space: 10 }) {
          // 水箱水量滑块
          Column() {
            Text('水箱水量')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 });

            Row() {
              Text('当前水量: ')
                .fontSize(14);
              Text(`${this.tankWaterLevel}%`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold);
            }
            .width('100%')
            .margin({ bottom: 10 });

            Slider({
              value: this.tankWaterLevel,
              min: 0,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
              .blockColor('#2196F3')
              .trackColor('#BBDEFB')
              .onChange((value: number) => {
                this.tankWaterLevel = Math.round(value);
                dataManager.setIrrigationConfig({ tankWaterLevel: this.tankWaterLevel });
                this.updateRemainingTime();
              });
          }
          .width('48%')
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10);

          // 水泵能效滑块（灌溉控制）
          Column() {
            Row() {
              Text('水泵能效')
                .fontSize(16)
                .fontWeight(FontWeight.Medium);
              Blank();
              Text(this.pumpEfficiency === 0 ? '灌溉关闭' : '灌溉开启')
                .fontSize(12)
                .fontColor(this.pumpEfficiency === 0 ? '#F44336' : '#4CAF50')
                .fontWeight(FontWeight.Bold);
            }
            .width('100%')
            .margin({ bottom: 15 });

            Row() {
              Text('当前能效: ')
                .fontSize(14);
              Text(`${this.pumpEfficiency}%`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold);
            }
            .width('100%')
            .margin({ bottom: 10 });

            Slider({
              value: this.pumpEfficiency,
              min: 0,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
              .blockColor('#2196F3') // 蓝色
              .trackColor('#BBDEFB')
              .onChange((value: number) => {
                this.pumpEfficiency = Math.round(value);
                dataManager.setIrrigationConfig({ 
                  pumpEfficiency: this.pumpEfficiency,
                  isOn: this.pumpEfficiency > 0
                });
                this.updateIrrigationStatus();
                this.updateRecommendedEfficiency();
              });
          }
          .width('48%')
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10);
        }
        .width('90%')
        .margin({ bottom: 20 });

        // 灌溉信息显示方块
        Column() {
          Text('灌溉信息')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 15 });

          // 第一行：灌溉水量自适应算法（不可编辑）
          Row() {
            Text('灌溉水量自适应算法')
              .fontSize(14)
              .fontColor('#333333')
              .width('100%');
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 });

          // 第二行：过去一天灌溉水量
          Row() {
            Text('过去一天灌溉水量:')
              .fontSize(14)
              .fontColor('#333333')
              .width('65%');
            Row() {
              TextInput({ text: this.dayIrrigation.toString() })
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2196F3')
                .width('60%')
                .backgroundColor('#FFFFFF')
                .borderRadius(4)
                .padding(4)
                .onChange((text: string) => {
                  const numericValue = parseInt(text);
                  if (!isNaN(numericValue)) {
                    this.dayIrrigation = numericValue;
                    dataManager.updateIrrigationStats({ dayIrrigation: this.dayIrrigation });
                  }
                });
              Text('ml')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ left: 4 })
                .width('40%');
            }
            .width('35%');
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 });

          // 第三行：过去一小时灌溉水量
          Row() {
            Text('过去一小时灌溉水量:')
              .fontSize(14)
              .fontColor('#333333')
              .width('65%');
            Row() {
              TextInput({ text: this.hourIrrigation.toString() })
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2196F3')
                .width('60%')
                .backgroundColor('#FFFFFF')
                .borderRadius(4)
                .padding(4)
                .onChange((text: string) => {
                  const numericValue = parseInt(text);
                  if (!isNaN(numericValue)) {
                    this.hourIrrigation = numericValue;
                    dataManager.updateIrrigationStats({ hourIrrigation: this.hourIrrigation });
                  }
                });
              Text('ml')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ left: 4 })
                .width('40%');
            }
            .width('35%');
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 });

          // 第四行：推荐水泵能效
          Row() {
            Text('推荐水泵能效:')
              .fontSize(14)
              .fontColor('#333333')
              .width('65%');
            Row() {
              TextInput({ text: this.recommendedEfficiency.toString() })
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2196F3')
                .width('60%')
                .backgroundColor('#FFFFFF')
                .borderRadius(4)
                .padding(4)
                .onChange((text: string) => {
                  const numericValue = parseInt(text);
                  if (!isNaN(numericValue)) {
                    this.recommendedEfficiency = numericValue;
                    dataManager.updateIrrigationStats({ recommendedEfficiency: this.recommendedEfficiency });
                  }
                });
              Text('%')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ left: 4 })
                .width('40%');
            }
            .width('35%');
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 });

          // 第五行：预计水箱可灌溉时长
          Row() {
            Text('预计水箱可灌溉时长:')
              .fontSize(14)
              .fontColor('#333333')
              .width('65%');
            Row() {
              TextInput({ text: this.remainingTime.toString() })
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2196F3')
                .width('60%')
                .backgroundColor('#FFFFFF')
                .borderRadius(4)
                .padding(4)
                .onChange((text: string) => {
                  const numericValue = parseInt(text);
                  if (!isNaN(numericValue)) {
                    this.remainingTime = numericValue;
                    dataManager.updateIrrigationStats({ remainingTime: this.remainingTime });
                  }
                });
              Text('min')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ left: 4 })
                .width('40%');
            }
            .width('35%');
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 });
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFE0B2')
        .borderRadius(10)
        .margin({ bottom: 30 });
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
  InfoSquare(title: string, value: string, type: string) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 8 });
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(type === 'temperature' ? '#FF5722' : '#2196F3');
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .border({
      width: 2,
      color: type === 'temperature' ? '#FFCCBC' : '#BBDEFB'
    });
  }

  private refreshTemperature(): void {
    const currentData = dataManager.getCurrentData();
    this.temperature = currentData.temperature;
  }

  private refreshHumidity(): void {
    const currentData = dataManager.getCurrentData();
    this.humidity = currentData.humidity;
  }

  private updateIrrigationStatus(): void {
    // 水泵能效为0时关闭灌溉，大于0时开启灌溉
    this.isIrrigationOn = this.pumpEfficiency > 0;
  }

  private updateRemainingTime(): void {
    // 基于水箱水量和当前灌溉速率计算剩余时间
    const baseTime = this.tankWaterLevel * 2.5; // 简单估算
    this.remainingTime = Math.round(baseTime * (this.pumpEfficiency / 100));
    dataManager.updateIrrigationStats({ remainingTime: this.remainingTime });
  }

  private updateRecommendedEfficiency(): void {
    // 基于当前条件和历史数据推荐能效
    const baseEfficiency = 85;
    const tempAdjustment = this.temperature > 28 ? 3 : (this.temperature < 18 ? -2 : 0);
    const moistureAdjustment = this.soilMoisture < 40 ? 2 : 0;
    this.recommendedEfficiency = Math.min(95, Math.max(70, baseEfficiency + tempAdjustment + moistureAdjustment));
    dataManager.updateIrrigationStats({ recommendedEfficiency: this.recommendedEfficiency });
  }

  private calculateWater(): void {
    const moistureDeficit = Math.max(0, this.targetMoisture - this.soilMoisture);
    const tempFactor = this.temperature > 30 ? 1.2 : (this.temperature < 15 ? 0.8 : 1.0);
    
    let cropFactor = 1.0;
    if (this.cropType === 'vegetable') cropFactor = 1.0;
    else if (this.cropType === 'fruit') cropFactor = 1.3;
    else if (this.cropType === 'grain') cropFactor = 0.8;
    else if (this.cropType === 'flower') cropFactor = 1.1;
    
    this.estimatedWater = Math.round(moistureDeficit * 0.5 * tempFactor * cropFactor * 100) / 100;
    this.estimatedDuration = Math.ceil(this.estimatedWater / 0.5);
    
    // 更新相关计算
    this.updateRemainingTime();
    this.updateRecommendedEfficiency();
  }
}