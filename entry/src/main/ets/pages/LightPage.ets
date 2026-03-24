import { router } from '@kit.ArkUI';
import { dataManager, SensorData, LightConfig } from '../services/DataManager';
import { bleService } from '../services/BleService';

@Entry
@Component
struct LightPage {
  @State isLightOn: boolean = false;
  @State autoMode: boolean = true;
  @State currentLightLevel: number = 300;
  @State eastBrightness: number = 50;
  @State westBrightness: number = 50;
  @State southBrightness: number = 50;
  @State northBrightness: number = 50;
  @State lightDirection: string = '东南';
  @State recommendedStrength: number = 400;
  @State recommendedDirection: string = '东南';
  @State isConnected: boolean = false;

  aboutToAppear(): void {
    this.isConnected = bleService.getConnectionStatus();
    
    const config = dataManager.getLightConfig();
    this.isLightOn = config.isOn;
    this.autoMode = config.autoMode;
    this.eastBrightness = config.eastBrightness;
    this.westBrightness = config.westBrightness;
    this.southBrightness = config.southBrightness;
    this.northBrightness = config.northBrightness;
    this.lightDirection = config.lightDirection;
    this.recommendedStrength = config.recommendedStrength;
    this.recommendedDirection = config.recommendedDirection;

    const currentData = dataManager.getCurrentData();
    this.currentLightLevel = currentData.lightLevel;

    dataManager.setDataCallback((data: SensorData) => {
      this.currentLightLevel = data.lightLevel;
      this.isConnected = bleService.getConnectionStatus();
    });
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
          Text('智能光照')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20 });
        }
        .width('90%')
        .margin({ top: 20, bottom: 30 });

        // 第一行：两个小方格
        Row({ space: 10 }) {
          // 左上方小方格 - 当前光照强度
          Column() {
            Text('当前光照强度')
              .fontSize(14)
              .fontColor('#666666');
            Row({ space: 5 }) {
              Text(`${this.currentLightLevel.toFixed(0)}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold);
              Text(' k')
                .fontSize(14)
                .fontColor('#666666');
            }
            .margin({ top: 5 });
          }
          .width('48%')
          .height(80)
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);

          // 右上方小方格 - 当前光照方向
          Column() {
            Text('当前光照方向')
              .fontSize(14)
              .fontColor('#666666');
            Text(this.lightDirection)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 5 });
          }
          .width('48%')
          .height(80)
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);
        }
        .width('90%')
        .margin({ bottom: 20 });

        // 四个滑块区域 - 直接实现每个滑块，不使用Builder
        Column({ space: 15 }) {
          // 东向灯强滑块
          this.EastLightSlider()

          // 西向灯强滑块
          this.WestLightSlider()

          // 南向灯强滑块
          this.SouthLightSlider()

          // 北向灯强滑块
          this.NorthLightSlider()
        }
        .width('90%')
        .margin({ bottom: 20 });

        // 最下方方格 - 自适应调节
        Column() {
          // 第一行：补光设备自适应调节
          Row() {
            Text('补光设备自适应调节')
              .fontSize(16)
              .fontWeight(FontWeight.Medium);
            Blank();
            Text(this.autoMode ? '已开启' : '已关闭')
              .fontSize(14)
              .fontColor(this.autoMode ? '#4CAF50' : '#F44336');
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 15, bottom: 10 });

          Divider();

          // 第二行：推荐参数（可编辑）
          Row() {
            Text('推荐补光强')
              .fontSize(14);
            TextInput({ text: this.recommendedStrength.toString() })
              .width(60)
              .height(30)
              .fontSize(14)
              .textAlign(TextAlign.Center)
              .backgroundColor('#FFFFFF')
              .borderRadius(5)
              .margin({ left: 5, right: 10 })
              .onChange((value: string) => {
                const numValue = parseInt(value);
                if (!isNaN(numValue) && numValue >= 0 && numValue <= 1000) {
                  this.recommendedStrength = numValue;
                  dataManager.setLightConfig({ recommendedStrength: numValue });
                }
              });
            Text('k')
              .fontSize(14);

            Blank();

            Text('补光方向')
              .fontSize(14);
            TextInput({ text: this.recommendedDirection })
              .width(60)
              .height(30)
              .fontSize(14)
              .textAlign(TextAlign.Center)
              .backgroundColor('#FFFFFF')
              .borderRadius(5)
              .margin({ left: 5 })
              .onChange((value: string) => {
                this.recommendedDirection = value;
                dataManager.setLightConfig({ recommendedDirection: value });
              });
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 10, bottom: 10 });

          Divider();

          // 第三行：点击自适应按钮
          Button('点击自适应')
            .width('90%')
            .height(40)
            .backgroundColor('#FFC107')
            .fontColor('#000000')
            .margin({ top: 10, bottom: 15 })
            .onClick(() => {
              this.autoAdjustLight();
            });
        }
        .width('90%')
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

  // 东向灯强滑块
  @Builder
  EastLightSlider() {
    this.LightSliderBuilder('东向灯强', this.eastBrightness, (value: number) => {
      this.eastBrightness = value;
      dataManager.setLightConfig({ eastBrightness: value });
    });
  }

  // 西向灯强滑块
  @Builder
  WestLightSlider() {
    this.LightSliderBuilder('西向灯强', this.westBrightness, (value: number) => {
      this.westBrightness = value;
      dataManager.setLightConfig({ westBrightness: value });
    });
  }

  // 南向灯强滑块
  @Builder
  SouthLightSlider() {
    this.LightSliderBuilder('南向灯强', this.southBrightness, (value: number) => {
      this.southBrightness = value;
      dataManager.setLightConfig({ southBrightness: value });
    });
  }

  // 北向灯强滑块
  @Builder
  NorthLightSlider() {
    this.LightSliderBuilder('北向灯强', this.northBrightness, (value: number) => {
      this.northBrightness = value;
      dataManager.setLightConfig({ northBrightness: value });
    });
  }

  // 通用的滑块构建器
  @Builder
  LightSliderBuilder(label: string, brightness: number, onChange: (value: number) => void) {
    Row({ space: 10 }) {
      Text(label)
        .fontSize(16)
        .width('25%');

      Slider({
        value: brightness,
        min: 0,
        max: 100,
        step: 5,
        style: SliderStyle.OutSet
      })
        .blockColor('#FFC107')
        .trackColor('#FFF9C4')
        .width('60%')
        .onChange((sliderValue: number) => {
          const roundedValue = Math.round(sliderValue);
          onChange(roundedValue);
        });

      // 提示灯区域 - 只保留连接状态提示灯，删除百分比显示
      Column() {
        // 设备连接状态提示灯
        Column() {
          Circle({ width: 20, height: 20 })
            .fill(this.isConnected ? '#4CAF50' : '#F44336');
          Text(this.isConnected ? '已连接' : '未连接')
            .fontSize(10)
            .fontColor(this.isConnected ? '#4CAF50' : '#F44336')
            .margin({ top: 2 });
        }
        .alignItems(HorizontalAlign.Center);
      }
      .width('15%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFE0B2')
    .borderRadius(10)
    .alignItems(VerticalAlign.Center);
  }

  autoAdjustLight(): void {
    // 调用自适应计算
    const recommendation = dataManager.calculateRecommendedLight();
    
    // 更新推荐值
    this.recommendedStrength = recommendation.strength;
    this.recommendedDirection = recommendation.direction;
    
    // 如果自动模式开启，则自动应用推荐值
    if (this.autoMode) {
      // 根据推荐方向设置不同方向的灯强
      let east = 50, west = 50, south = 50, north = 50;
      
      switch (recommendation.direction) {
        case '东':
          east = 80;
          break;
        case '南':
          south = 80;
          break;
        case '西':
          west = 80;
          break;
        case '北':
          north = 80;
          break;
        case '东南':
          east = 70;
          south = 70;
          break;
        default:
          east = 60;
          south = 60;
      }
      
      // 应用计算出的灯强
      this.eastBrightness = east;
      this.westBrightness = west;
      this.southBrightness = south;
      this.northBrightness = north;
      
      // 保存配置
      dataManager.setLightConfig({
        eastBrightness: east,
        westBrightness: west,
        southBrightness: south,
        northBrightness: north,
        recommendedStrength: recommendation.strength,
        recommendedDirection: recommendation.direction
      });
    } else {
      // 仅更新推荐值，不自动应用
      dataManager.setLightConfig({
        recommendedStrength: recommendation.strength,
        recommendedDirection: recommendation.direction
      });
    }
  }
}