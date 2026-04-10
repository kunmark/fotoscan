# iPad 条码采集原型

这是一个适合 iPad 使用的离线网页应用原型，用于通过蓝牙扫描枪采集图书 ISBN 条码和零售条码，并导出 CSV。

项目现在同时包含两个入口：

- Web prototype: `index.html`
- Native iPad app: `native-ios/BarcodeCaptureApp.xcodeproj`

## 已实现功能

- 扫描录入 ISBN-10、ISBN-13、EAN-8、EAN-13、UPC-A、ITF-14 和常见数字零售条码
- 对 ISBN、EAN、UPC、ITF 等结构化条码进行校验位检查，减少误扫入库
- 支持在“键盘扫码”和“摄像头扫码”之间切换
- 自动记录每次扫描的日期和时间
- 自动对重复条码做数量汇总
- 导出扫描明细 CSV
- 导出按条码汇总的数量 CSV
- 本地离线存储，刷新页面后仍保留数据

## iPad 使用建议

1. 将蓝牙扫描枪设置为 `HID Keyboard` 或 `Keyboard Mode`
2. 让扫描枪在每次扫描后自动追加 `Enter`
3. 在 iPad 上打开 `index.html` 对应的网页地址后，点击“聚焦输入框”
4. 用 Safari 的“添加到主屏幕”把它保存成桌面应用

## 摄像头扫码说明

- 需要在 `HTTPS` 或 `localhost` 环境中打开页面，浏览器才允许访问摄像头
- 需要浏览器支持 `BarcodeDetector`，否则网页端无法直接识别摄像头画面中的条码
- 切换到“摄像头扫码”后，点击“启动摄像头”，将条码放入取景框中即可自动记录
- 摄像头识别成功后，仍然会走同一套本地存储、汇总统计和 CSV 导出逻辑

## 导出文件

- `barcode-raw-YYYY-MM-DD.csv`：每次扫描一行，包含条码、类型、扫描日期、扫描时间
- `barcode-summary-YYYY-MM-DD.csv`：按条码汇总，包含数量、首次扫描时间、最后扫描时间、涉及的扫描日期

## 后续可扩展

- 增加“图书/商品名称”字段
- 增加“仓位/书架/批次”字段
- 增加“按日期筛选”和“按类型筛选”
- 上传到云端或局域网共享

## Native iPad App

- Open `native-ios/BarcodeCaptureApp.xcodeproj` in Xcode on macOS
- The native app supports keyboard entry, Bluetooth scanner workflow, CSV sharing, and iPad camera scanning through `DataScannerViewController`
- Deployment target is `iOS 16.0`
- The project is configured as iPad-only with `TARGETED_DEVICE_FAMILY = 2`
