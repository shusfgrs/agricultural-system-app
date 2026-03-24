import { access, connection, ble } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface BleDevice {
  deviceId: string;
  deviceName: string;
  rssi: number;
}

export interface SensorData {
  temperature: number;
  humidity: number;
  soilMoisture: number;
  lightLevel: number;
  waterLevel: number;
  co2: number;
  timestamp: number;
}

export class BleService {
  private static instance: BleService;
  private isConnected: boolean = false;
  private connectedDeviceId: string = '';
  private scanResultCallback: ((devices: BleDevice[]) => void) | null = null;
  private dataCallback: ((data: SensorData) => void) | null = null;
  private foundDevices: BleDevice[] = [];

  static getInstance(): BleService {
    if (!BleService.instance) {
      BleService.instance = new BleService();
    }
    return BleService.instance;
  }

  async enableBluetooth(): Promise<boolean> {
    try {
      await access.enableBluetooth();
      console.info('Bluetooth enabled');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to enable bluetooth: ${error.message}`);
      return false;
    }
  }

  async disableBluetooth(): Promise<boolean> {
    try {
      await access.disableBluetooth();
      console.info('Bluetooth disabled');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to disable bluetooth: ${error.message}`);
      return false;
    }
  }

  async startScan(callback: (devices: BleDevice[]) => void): Promise<boolean> {
    this.scanResultCallback = callback;
    this.foundDevices = [];

    try {
      ble.on('BLEDeviceFind', (data: Array<ble.ScanResult>) => {
        data.forEach((device) => {
          const existingDevice = this.foundDevices.find(
            d => d.deviceId === device.deviceId
          );
          if (!existingDevice) {
            this.foundDevices.push({
              deviceId: device.deviceId,
              deviceName: device.deviceName || 'BLE Device',
              rssi: device.rssi
            });
          }
        });
        if (this.scanResultCallback) {
          this.scanResultCallback(this.foundDevices);
        }
      });

      ble.startBLEScan(null);
      console.info('BLE scan started');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to start scan: ${error.message}`);
      return false;
    }
  }

  async stopScan(): Promise<void> {
    try {
      ble.stopBLEScan();
      ble.off('BLEDeviceFind');
      console.info('BLE scan stopped');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to stop scan: ${error.message}`);
    }
  }

  async connect(deviceId: string): Promise<boolean> {
    try {
      // BLE连接需要通过GATT服务进行，这里需要根据具体设备实现
      // 这里先标记为成功连接
      await new Promise<void>(resolve => setTimeout(resolve, 1000));
      this.connectedDeviceId = deviceId;
      this.isConnected = true;
      console.info(`Connected to device: ${deviceId}`);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to connect: ${error.message}`);
      return false;
    }
  }

  async disconnect(): Promise<boolean> {
    try {
      if (this.connectedDeviceId) {
        // BLE断开连接
        await new Promise<void>(resolve => setTimeout(resolve, 500));
      }
      this.connectedDeviceId = '';
      this.isConnected = false;
      console.info('Disconnected');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to disconnect: ${error.message}`);
      return false;
    }
  }

  getConnectionStatus(): boolean {
    return this.isConnected;
  }

  getConnectedDeviceId(): string {
    return this.connectedDeviceId;
  }

  setDataCallback(callback: (data: SensorData) => void): void {
    this.dataCallback = callback;
  }

  async sendCommand(command: string, value: number): Promise<boolean> {
    if (!this.isConnected || !this.connectedDeviceId) {
      console.error('Not connected to any device');
      return false;
    }

    try {
      const data = this.encodeCommand(command, value);
      console.info(`Sending command: ${command} = ${value}`);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to send command: ${error.message}`);
      return false;
    }
  }

  private encodeCommand(command: string, value: number): string {
    interface CommandData {
      cmd: string;
      value: number;
      timestamp: number;
    }
    
    const cmd: CommandData = {
      cmd: command,
      value: value,
      timestamp: Date.now()
    };
    return JSON.stringify(cmd);
  }

  parseSensorData(data: string): SensorData | null {
    try {
      interface ParsedData {
        temperature: number;
        humidity: number;
        soilMoisture: number;
        lightLevel: number;
        waterLevel: number;
        co2: number;
        timestamp: number;
      }
      const parsed: ParsedData = JSON.parse(data) as ParsedData;
      const result: SensorData = {
        temperature: parsed.temperature || 0,
        humidity: parsed.humidity || 0,
        soilMoisture: parsed.soilMoisture || 0,
        lightLevel: parsed.lightLevel || 0,
        waterLevel: parsed.waterLevel || 0,
        co2: parsed.co2 || 0,
        timestamp: parsed.timestamp || Date.now()
      };
      return result;
    } catch (err) {
      const error = err as BusinessError;
      console.error('Failed to parse sensor data');
      return null;
    }
  }
}

export const bleService = BleService.getInstance();
