# Android 真机调试脚本

## 快速开始

```bash
# 检查设备连接
./scripts/android_debug.sh check

# 运行调试（推荐）
./scripts/android_debug.sh run

# 查看日志
./scripts/android_debug.sh logs
```

## 所有命令

| 命令 | 功能 | 说明 |
|---|---|---|
| `check` | 检查设备 | 检测已连接的 Android 设备 |
| `install` | 安装应用 | 构建并安装 debug APK |
| `run` | 运行调试 | 启动应用，支持热重载 |
| `logs` | 查看日志 | 实时显示应用日志 |
| `clear` | 清除数据 | 清除应用数据和缓存 |
| `uninstall` | 卸载应用 | 从设备卸载应用 |
| `restart` | 重启 ADB | 重启 ADB 服务（解决连接问题） |

## 使用流程

### 1. 准备手机
- 开启 **开发者选项**（连续点击版本号 7 次）
- 开启 **USB 调试**
- USB 连接模式选择 **文件传输（MTP）**
- 连接电脑，允许 USB 调试

### 2. 检查连接
```bash
./scripts/android_debug.sh check
```

如果未检测到设备：
```bash
./scripts/android_debug.sh restart
```

### 3. 运行调试
```bash
./scripts/android_debug.sh run
```

这会：
- 自动构建 debug 版本
- 安装到设备
- 启动应用
- 支持热重载（按 `r` 键）

### 4. 查看日志
```bash
./scripts/android_debug.sh logs
```

实时显示 Flutter 应用日志，按 Ctrl+C 退出。

## 热重载快捷键

运行 `flutter run` 后：
- `r` - 热重载（保持状态）
- `R` - 热重启（重置状态）
- `q` - 退出调试
- `h` - 显示更多帮助

## 常见问题

### 设备未检测到

1. **检查 USB 连接**
   - 换一根数据线
   - 换一个 USB 口

2. **检查手机设置**
   - USB 调试已开启
   - USB 模式为"文件传输"
   - 已信任此电脑

3. **重启 ADB**
   ```bash
   ./scripts/android_debug.sh restart
   ```

### 安装失败

```bash
# 先卸载旧版本
./scripts/android_debug.sh uninstall

# 重新安装
./scripts/android_debug.sh install
```

### 应用崩溃

```bash
# 清除应用数据
./scripts/android_debug.sh clear

# 重新运行
./scripts/android_debug.sh run
```

## 包名

当前应用包名：`com.an.zhen`

## 相关脚本

- `../flutter_app/build_app.sh` - 发布版本打包脚本
- `android_debug.sh` - 调试版本脚本（本文件）
