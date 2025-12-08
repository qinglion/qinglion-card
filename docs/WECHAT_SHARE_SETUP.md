# 微信分享功能配置指南

## 概述

本项目已集成微信 JS-SDK 分享功能，用于在微信中分享个人名片时显示自定义的标题、描述和图片。

## 架构说明

### 后端组件

1. **WechatService** (`app/services/wechat_service.rb`)
   - 管理 access_token 的获取和缓存（7000秒）
   - 管理 jsapi_ticket 的获取和缓存（7000秒）
   - 生成 JS-SDK 签名

2. **WechatSignaturesController** (`app/controllers/wechat_signatures_controller.rb`)
   - API 端点：`POST /wechat_signatures`
   - 接收 URL 参数
   - 返回签名配置

### 前端组件

3. **WechatShareController** (`app/javascript/controllers/wechat_share_controller.ts`)
   - Stimulus controller，处理微信 JS-SDK 集成
   - 自动加载微信 JS-SDK 脚本
   - 从后端获取签名
   - 配置分享内容

## 配置步骤

### 第一步：注册微信公众号

1. 访问：https://mp.weixin.qq.com/
2. 注册服务号或订阅号（服务号功能更全）
3. 完成认证（需要营业执照等）

### 第二步：获取 AppID 和 AppSecret

1. 登录微信公众平台
2. 进入：设置与开发 > 基本配置
3. 记录：
   - AppID（公众号开发信息）
   - AppSecret（需要管理员扫码查看）

### 第三步：配置 JS接口安全域名

1. 进入：设置与开发 > 公众号设置 > 功能设置 > JS接口安全域名
2. 点击"设置"
3. 添加域名（**不带协议**）：
   ```
   card.qinglion.com
   ```
4. 下载验证文件 `MP_verify_xxx.txt`
5. 将验证文件放到项目的 `public/` 目录
6. 确保文件可访问：`https://card.qinglion.com/MP_verify_xxx.txt`
7. 点击"确定"完成验证

**重要提示**：
- 域名必须是备案的域名
- 一个公众号最多配置 3 个域名
- 配置后需要等待 5-10 分钟生效

### 第四步：配置环境变量

在生产环境配置 AppID 和 AppSecret：

#### Railway 部署

```bash
# 设置环境变量
railway variables set WECHAT_APPID=wx1234567890abcdef
railway variables set WECHAT_APPSECRET=your_appsecret_here
```

#### Heroku 部署

```bash
heroku config:set WECHAT_APPID=wx1234567890abcdef
heroku config:set WECHAT_APPSECRET=your_appsecret_here
```

#### 本地开发

编辑 `config/application.yml`：

```yaml
# WeChat JS-SDK Configuration
WECHAT_APPID: 'wx1234567890abcdef'
WECHAT_APPSECRET: 'your_appsecret_here'
```

**⚠️ 安全提醒**：
- 永远不要将 AppSecret 提交到 Git 仓库
- 定期更换 AppSecret
- 不要在前端代码中暴露 AppSecret

## 工作原理

### 流程图

```
用户访问名片页面
    ↓
Stimulus controller 连接
    ↓
加载微信 JS-SDK 脚本
    ↓
获取当前 URL（去除 # 片段）
    ↓
POST /wechat_signatures
    ↓
后端 WechatService:
  1. 从缓存或微信 API 获取 access_token
  2. 从缓存或微信 API 获取 jsapi_ticket
  3. 生成签名：SHA1(jsapi_ticket + noncestr + timestamp + url)
    ↓
返回签名数据：
  {
    appId, timestamp, nonceStr, signature
  }
    ↓
前端调用 wx.config() 初始化
    ↓
微信验证签名
    ↓
wx.ready() 触发
    ↓
配置分享内容
    ↓
用户点击分享按钮
    ↓
显示自定义的分享内容！
```

### API 请求示例

**请求**：
```bash
curl -X POST https://card.qinglion.com/wechat_signatures \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: xxx" \
  -d '{"url": "https://card.qinglion.com/c/sengmitnick"}'
```

**响应**：
```json
{
  "success": true,
  "data": {
    "appId": "wx1234567890abcdef",
    "timestamp": "1701234567",
    "nonceStr": "abc123def456",
    "signature": "a1b2c3d4e5f6789...",
    "url": "https://card.qinglion.com/c/sengmitnick"
  }
}
```

## 测试

### 使用 vConsole 调试

访问页面时添加 `?vconsole=1` 参数：

```
https://card.qinglion.com/c/sengmitnick?vconsole=1
```

点击右下角绿色按钮打开调试面板，查看：

- **Console** 标签：查看日志
- **Network** 标签：查看 API 请求

### 预期日志

正常情况下应该看到：

```javascript
"WechatShare controller connected"
"WeChat JS-SDK not loaded, loading now..."
"WeChat JS-SDK ready"
"Share to chat configured"
"Share to timeline configured"
```

### 测试分享功能

1. 在微信中打开名片页面
2. 点击右上角菜单（...）
3. 选择"发送给朋友"或"分享到朋友圈"
4. 查看是否显示自定义的标题、描述和图片

## 故障排查

详细的故障排查指南请参考：[WECHAT_SHARE_TROUBLESHOOTING.md](./WECHAT_SHARE_TROUBLESHOOTING.md)

### 快速检查清单

- [ ] 微信公众号已注册并认证
- [ ] AppID 和 AppSecret 已正确配置
- [ ] JS接口安全域名已添加（`card.qinglion.com`）
- [ ] 域名验证文件可访问
- [ ] 在微信浏览器中打开（不是普通浏览器）
- [ ] 使用 vConsole 查看调试信息
- [ ] 签名 API 返回成功

### 常见问题

#### 1. 签名验证失败

**错误**：`config:invalid signature`

**原因**：
- URL 格式不正确
- 域名未配置
- 签名算法错误

**解决**：
- 确认 JS接口安全域名已正确配置
- 等待 5-10 分钟让配置生效
- 清除微信缓存重试

#### 2. 权限错误

**错误**：`config:permission denied`

**原因**：
- AppID 错误
- 域名未在公众号配置

**解决**：
- 检查 WECHAT_APPID 环境变量
- 确认域名已添加到 JS接口安全域名

#### 3. API 调用失败

**错误**：Network request failed

**原因**：
- AppID 或 AppSecret 配置错误
- 微信 API 不可达

**解决**：
- 检查环境变量配置
- 查看 Rails 日志中的错误信息
- 测试网络连接到微信 API

## 缓存策略

为了避免频繁调用微信 API 和提高性能：

- **access_token**：缓存 7000 秒（约 1小时56分）
- **jsapi_ticket**：缓存 7000 秒（约 1小时56分）

微信的过期时间是 7200 秒（2小时），我们提前 200 秒过期以确保安全。

### 清除缓存

如需手动清除缓存：

```ruby
# Rails console
Rails.cache.delete('wechat_access_token')
Rails.cache.delete('wechat_jsapi_ticket')
```

## 生产环境建议

### 1. 使用 Redis 缓存

在 `config/environments/production.rb` 中配置：

```ruby
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  expires_in: 2.hours
}
```

### 2. 监控错误

添加错误监控（如 Sentry）：

```ruby
# app/services/wechat_service.rb
rescue StandardError => e
  Rails.logger.error("WechatService error: #{e.message}")
  Sentry.capture_exception(e) if defined?(Sentry)
  error_result(e.message)
end
```

### 3. 添加限流

防止 API 滥用：

```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
Rack::Attack.throttle('wechat_signatures/ip', limit: 20, period: 60) do |req|
  req.ip if req.path == '/wechat_signatures' && req.post?
end
```

## 安全注意事项

1. **保护 AppSecret**
   - 只在服务器端使用
   - 不要提交到 Git
   - 定期轮换

2. **验证请求来源**
   - 检查 Referer 头
   - 验证 URL 域名
   - 使用 CSRF 保护

3. **监控异常调用**
   - 记录所有 API 调用
   - 监控失败率
   - 设置告警

## 参考资料

- [微信 JS-SDK 官方文档](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html)
- [微信公众平台](https://mp.weixin.qq.com/)
- [JS-SDK 使用权限签名算法](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html#62)

## 技术支持

遇到问题时，请提供以下信息：

1. 错误截图（使用 vConsole）
2. Console 日志
3. Network 请求详情
4. 域名配置截图
5. Rails 日志

联系方式：
- 查看故障排查文档：[WECHAT_SHARE_TROUBLESHOOTING.md](./WECHAT_SHARE_TROUBLESHOOTING.md)
- 检查 Rails 日志：`log/production.log`
