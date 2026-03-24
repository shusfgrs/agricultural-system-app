# UI组接口文档

## 概述

本文档为前端UI开发者提供智慧农业APP的接口说明，所有数据交互通过 `DataManager` 服务进行。

---

## 数据结构

### SensorData - 传感器数据

```typescript
interface SensorData {
  temperature: number;    // 温度 (°C)
  humidity: number;       // 湿度 (%)
  soilMoisture: number;   // 土壤湿度 (%)
  lightLevel: number;     // 光照强度 (lux)
  waterLevel: number;     // 水位 (%)
  co2: number;            // CO2浓度 (ppm)
  timestamp: number;      // 时间戳
}
```

### AlertThreshold - 预警阈值

```typescript
interface AlertThreshold {
  name: string;       // 参数名称
  minValue: number;   // 最小值
  maxValue: number;   // 最大值
  unit: string;       // 单位
}
```

### IrrigationConfig - 灌溉配置

```typescript
interface IrrigationConfig {
  isOn: boolean;           // 灌溉开关
  autoMode: boolean;       // 自动模式
  targetMoisture: number;  // 目标湿度
  duration: number;        // 持续时间(分钟)
}
```

### LightConfig - 光照配置

```typescript
interface LightConfig {
  isOn: boolean;        // 灯光开关
  autoMode: boolean;    // 自动模式
  brightness: number;   // 亮度 (0-100)
  startTime: string;    // 开启时间 (HH:mm)
  endTime: string;      // 关闭时间 (HH:mm)
}
```

### AlertRecord - 预警记录

```typescript
interface AlertRecord {
  id: string;          // 记录ID
  type: string;        // 预警类型
  message: string;     // 预警消息
  value: number;       // 触发值
  threshold: string;   // 阈值范围
  timestamp: number;   // 时间戳
}
```

---

## DataManager API

### 引入方式

```typescript
import { dataManager, SensorData, AlertThreshold, IrrigationConfig, LightConfig, AlertRecord } from '../services/DataManager';
```

---

### 传感器数据相关

#### 获取当前传感器数据

```typescript
const data: SensorData = dataManager.getCurrentData();
```

**返回示例：**
```json
{
  "temperature": 25.5,
  "humidity": 65,
  "soilMoisture": 45,
  "lightLevel": 300,
  "waterLevel": 75,
  "co2": 450,
  "timestamp": 1700000000000
}
```

#### 设置数据回调（实时更新）

```typescript
dataManager.setDataCallback((data: SensorData) => {
  this.temperature = data.temperature;
  this.humidity = data.humidity;
  // ... 更新UI
});
```

---

### 阈值预警相关

#### 获取所有阈值配置

```typescript
const thresholds: AlertThreshold[] = dataManager.getThresholds();
```

**返回示例：**
```json
[
  { "name": "temperature", "minValue": 15, "maxValue": 35, "unit": "°C" },
  { "name": "humidity", "minValue": 40, "maxValue": 80, "unit": "%" },
  { "name": "soilMoisture", "minValue": 30, "maxValue": 70, "unit": "%" },
  { "name": "lightLevel", "minValue": 100, "maxValue": 1000, "unit": "lux" },
  { "name": "waterLevel", "minValue": 20, "maxValue": 100, "unit": "%" },
  { "name": "co2", "minValue": 300, "maxValue": 1000, "unit": "ppm" }
]
```

#### 更新阈值

```typescript
dataManager.updateThreshold('temperature', 10, 40);
```

**参数说明：**
| 参数 | 类型 | 说明 |
|------|------|------|
| name | string | 参数名称: temperature, humidity, soilMoisture, lightLevel, waterLevel, co2 |
| minValue | number | 最小值 |
| maxValue | number | 最大值 |

#### 获取预警历史

```typescript
const history: AlertRecord[] = dataManager.getAlertHistory();
```

#### 设置预警回调

```typescript
dataManager.setAlertCallback((alert: AlertRecord) => {
  console.log('新预警:', alert.message);
});
```

#### 清除预警历史

```typescript
dataManager.clearAlertHistory();
```

---

### 灌溉控制相关

#### 获取灌溉配置

```typescript
const config: IrrigationConfig = dataManager.getIrrigationConfig();
```

**返回示例：**
```json
{
  "isOn": false,
  "autoMode": true,
  "targetMoisture": 50,
  "duration": 10
}
```

#### 设置灌溉配置

```typescript
// 开启灌溉
dataManager.setIrrigationConfig({ isOn: true });

// 关闭灌溉
dataManager.setIrrigationConfig({ isOn: false });

// 设置自动模式
dataManager.setIrrigationConfig({ autoMode: true });

// 设置目标湿度
dataManager.setIrrigationConfig({ targetMoisture: 60 });
```

#### 计算灌溉水量

```typescript
const waterAmount: number = dataManager.calculateIrrigationWater('vegetable');
```

**作物类型参数：**
| 参数值 | 说明 | 系数 |
|--------|------|------|
| vegetable | 蔬菜 | 1.0 |
| fruit | 水果 | 1.3 |
| grain | 谷物 | 0.8 |
| flower | 花卉 | 1.1 |
| default | 默认 | 1.0 |

#### 获取灌溉估算

```typescript
const estimate = dataManager.getIrrigationWaterEstimate('vegetable');
// 返回: { waterAmount: 2.5, duration: 5 }
```

---

### 光照控制相关

#### 获取光照配置

```typescript
const config: LightConfig = dataManager.getLightConfig();
```

**返回示例：**
```json
{
  "isOn": false,
  "autoMode": true,
  "brightness": 50,
  "startTime": "06:00",
  "endTime": "18:00"
}
```

#### 设置光照配置

```typescript
// 开启灯光
dataManager.setLightConfig({ isOn: true });

// 设置亮度
dataManager.setLightConfig({ brightness: 80 });

// 设置自动模式
dataManager.setLightConfig({ autoMode: true });

// 设置定时
dataManager.setLightConfig({ startTime: '07:00', endTime: '19:00' });
```

---

## BleService API

### 引入方式

```typescript
import { bleService, BleDevice } from '../services/BleService';
```

### 蓝牙设备相关

#### 获取连接状态

```typescript
const isConnected: boolean = bleService.getConnectionStatus();
```

#### 获取已连接设备ID

```typescript
const deviceId: string = bleService.getConnectedDeviceId();
```

#### 扫描设备

```typescript
const success = await bleService.startScan((devices: BleDevice[]) => {
  this.deviceList = devices;
});

// 停止扫描
await bleService.stopScan();
```

#### 连接设备

```typescript
const success = await bleService.connect(deviceId);
```

#### 断开连接

```typescript
await bleService.disconnect();
```

---

## 使用示例

### 页面初始化获取数据

```typescript
aboutToAppear(): void {
  // 获取初始数据
  const currentData = dataManager.getCurrentData();
  this.temperature = currentData.temperature;
  this.humidity = currentData.humidity;
  
  // 设置数据回调
  dataManager.setDataCallback((data: SensorData) => {
    this.temperature = data.temperature;
    this.humidity = data.humidity;
  });
  
  // 获取蓝牙状态
  this.isConnected = bleService.getConnectionStatus();
}
```

### 控制操作示例

```typescript
// 开启灌溉
onIrrigationToggle(isOn: boolean): void {
  dataManager.setIrrigationConfig({ isOn: isOn });
}

// 调节亮度
onBrightnessChange(value: number): void {
  dataManager.setLightConfig({ brightness: value });
}

// 更新阈值
onThresholdChange(name: string, min: number, max: number): void {
  dataManager.updateThreshold(name, min, max);
}
```

---

## 数据流图

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   硬件设备   │────▶│  BleService │────▶│ DataManager │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │   UI 页面    │
                                        └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │  用户操作    │
                                        └─────────────┘
                                               │
                                               ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   硬件设备   │◀────│  BleService │◀────│ DataManager │
└─────────────┘     └─────────────┘     └─────────────┘
```

---

## 注意事项

1. **数据更新**: 使用 `setDataCallback` 设置回调后，数据会自动更新，无需手动轮询
2. **蓝牙状态**: 在页面显示前检查 `bleService.getConnectionStatus()` 判断是否连接
3. **模拟模式**: 未连接蓝牙时，数据为模拟数据，UI应显示提示
4. **阈值修改**: 修改阈值后会立即生效，并自动检查当前数据是否触发预警
