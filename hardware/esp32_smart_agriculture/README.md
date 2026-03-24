# ESP32 智慧农业系统 - 接线说明

## 硬件清单

| 组件 | 数量 | 说明 |
|--------|------|------|
| ESP32 开发板 | 1 | 主控制器 |
| DHT11 温湿度传感器 | 1 | 测量空气温湿度 |
| 土壤湿度传感器 | 1 | 测量土壤湿度 |
| 光敏传感器（带模拟输出） | 1 | 测量光照强度 |
| 水位传感器（带模拟输出） | 1 | 测量水箱水位 |
| CO2传感器（MH-Z19C或模拟式） | 1 | 测量CO2浓度 |
| 5V 继电器模块 | 2 | 控制水泵和灯光 |
| 小水泵 + 电源 | 1 | 灌溉用 |
| LED 灯带 + 电源 | 1 | 补光用 |
| 面包板 | 1 | 方便接线 |
| 杜邦线若干 | - | 连接各模块 |

---

## ESP32 引脚分配

| 功能 | ESP32 引脚 | 说明 |
|------|-------------|------|
| DHT11 数据引脚 | GPIO 4 | 温湿度传感器 |
| 土壤湿度传感器 | GPIO 34 (ADC1_CH6) | 模拟输入 |
| 光敏传感器 | GPIO 35 (ADC1_CH7) | 模拟输入 |
| 水位传感器 | GPIO 32 (ADC1_CH4) | 模拟输入 |
| CO2传感器 | GPIO 33 (ADC1_CH5) | 模拟输入 |
| 灌溉继电器 | GPIO 25 | 控制水泵 |
| 灯光继电器 | GPIO 26 | 控制LED灯 |

---

## 详细接线步骤

### 1. 电源接线

所有传感器和继电器都需要供电：

| 组件 | VCC | GND |
|--------|------|------|
| DHT11 | 3.3V | GND |
| 土壤湿度传感器 | 3.3V | GND |
| 光敏传感器 | 3.3V | GND |
| 水位传感器 | 3.3V | GND |
| CO2传感器 | 3.3V/5V | GND |
| 继电器1（水泵） | 5V | GND |
| 继电器2（灯光） | 5V | GND |

### 2. 传感器信号线接线

| 传感器 | 信号线 → ESP32 引脚 |
|--------|---------------------|
| DHT11 DATA | GPIO 4 |
| 土壤湿度 AO | GPIO 34 |
| 光敏传感器 AO | GPIO 35 |
| 水位传感器 AO | GPIO 32 |
| CO2传感器 AO | GPIO 33 |

### 3. 继电器控制线接线

| 继电器 | 控制线 → ESP32 引脚 | 负载 |
|--------|---------------------|--------|
| 继电器1 IN | GPIO 25 | 小水泵 |
| 继电器2 IN | GPIO 26 | LED灯带 |

继电器 COM 和 NO/NC 接线：
- **COM**（公共端）接电源正极（5V）
- **NO**（常开端）接负载正极
- 负载负极接 GND

---

## CO2传感器说明

### 方案一：模拟CO2传感器（简单）

使用模拟输出的CO2传感器（如MQ-135），直接连接：
- VCC → 3.3V
- GND → GND
- AO → GPIO 33

**注意**：MQ-135需要预热24-48小时才能准确读数。

### 方案二：MH-Z19C（推荐）

使用UART接口的MH-Z19C红外CO2传感器：

| MH-Z19C | ESP32 |
|---------|-------|
| VCC | 5V |
| GND | GND |
| TX | GPIO 16 (RX2) |
| RX | GPIO 17 (TX2) |

需要修改代码使用UART读取，精度更高。

---

## 上传代码步骤

1. 安装 Arduino IDE
   - 下载：https://www.arduino.cc/en/software

2. 安装 ESP32 开发板支持
   - Arduino IDE → 文件 → 首选项
   - 附加开发板管理器网址：`https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
   - 工具 → 开发板 → 开发板管理器
   - 搜索 "esp32" → 安装 "ESP32 by Espressif Systems"

3. 安装必要的库
   - 工具 → 管理库
   - 搜索并安装：
     - `DHT sensor library by Adafruit`
     - `ArduinoJson by Benoit Blanchon`

4. 选择开发板和端口
   - 工具 → 开发板 → ESP32 Arduino → ESP32 Dev Module
   - 工具 → 端口 → 选择你的 ESP32 端口

5. 上传代码
   - 点击上传按钮
   - 等待上传完成

---

## 测试步骤

1. 打开串口监视器（115200 波特率）
2. 观察输出，应该看到：
   ```
   Starting Smart Agriculture System...
   BLE started. Waiting for connection...
   Device name: SmartAgriculture-ESP32
   ```

3. 打开手机 APP
   - 进入"设备管理"
   - 点击"扫描设备"
   - 应该能看到 "SmartAgriculture-ESP32"
   - 点击连接

4. 连接成功后，APP 应该显示传感器数据

---

## 数据格式

### 上传数据（ESP32 → APP）

```json
{
  "temperature": 25.5,
  "humidity": 65,
  "soilMoisture": 45,
  "lightLevel": 300,
  "waterLevel": 75,
  "co2": 450,
  "timestamp": 1700000000
}
```

### 控制命令（APP → ESP32）

```json
{
  "cmd": "irrigation",
  "value": 1,
  "timestamp": 1700000000000
}
```

**支持的命令：**

| cmd | value | 说明 |
|-----|-------|------|
| irrigation | 0/1 | 灌溉开关 |
| light | 0/1 | 灯光开关 |
| brightness | 0-100 | 灯光亮度 |
| target_moisture | 20-80 | 目标湿度 |

---

## 常见问题

### 问题：传感器读数不准确
- 检查接线是否松动
- 确认传感器供电正常
- 调整 `map()` 函数的参数校准

### 问题：继电器不动作
- 检查继电器 IN 引脚接线
- 确认继电器供电（需要5V）
- 检查 GPIO 引脚定义是否正确

### 问题：蓝牙无法连接
- 确认 ESP32 蓝牙已启动（串口有输出）
- 检查手机蓝牙是否开启
- 尝试重启 ESP32

### 问题：上传失败
- 检查 USB 数据线是否支持数据传输（有些只能充电）
- 按住 ESP32 上的 BOOT 键再按 RESET 键进入下载模式
- 检查端口选择是否正确

### 问题：CO2读数异常
- MQ-135需要预热24-48小时
- 检查传感器供电电压
- 可在代码中调整map函数的映射范围

---

## 文件说明

```
hardware/esp32_smart_agriculture/
├── esp32_smart_agriculture.ino  # Arduino代码
└── README.md                     # 本文档
```

## 相关文档

- [UI组接口文档](../../docs/UI_INTERFACE.md)
- [硬件组接口文档](../../docs/HARDWARE_INTERFACE.md)
