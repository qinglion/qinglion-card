# PWA (Progressive Web App) 设置指南

本应用已配置完整的 PWA 功能，包括离线缓存、快速加载和 Web Push Notifications 推送通知支持。

## 已实现的功能

### ✅ 1. 基础 PWA 配置

- **Manifest.json**: 完整的应用清单，支持"添加到主屏幕"
- **Service Worker**: 智能缓存策略（HTML 网络优先，静态资源缓存优先）
- **离线支持**: 静态资源离线可用
- **应用图标**: 支持 PNG 和 SVG 多种尺寸
- **应用快捷方式**: 快速访问个人名片和团队页面

### ✅ 2. Service Worker 缓存策略

- **网络优先（HTML）**: 页面始终获取最新内容，离线时回退到缓存
- **缓存优先（静态资源）**: CSS/JS/图片优先使用缓存，提升加载速度
- **缓存过期时间**: 7天自动更新
- **自动清理**: 升级时自动清理旧版本缓存

### ✅ 3. Web Push Notifications

- **推送通知支持**: 完整的 Push API 集成
- **权限管理**: 优雅的权限请求流程
- **通知点击处理**: 自动导航到相关页面
- **订阅管理**: 用户可随时启用/关闭通知

### ✅ 4. PWA 安装提示

- **安装按钮**: Stimulus 控制器管理安装流程
- **自动隐藏**: 已安装后自动隐藏安装按钮
- **独立显示模式**: 支持全屏独立窗口运行

## 使用方法

### 1. PWA 安装按钮

在任何页面添加安装按钮：

```erb
<div data-controller="pwa-install">
  <button
    data-pwa-install-target="installButton"
    data-action="click->pwa-install#install"
    class="btn-primary hidden">
    安装应用
  </button>
</div>
```

### 2. Push Notifications 订阅

在用户设置页面或仪表盘添加通知订阅控制：

```erb
<div data-controller="push-notifications">
  <button
    data-action="click->push-notifications#subscribe"
    data-push-notifications-target="subscribeButton"
    class="btn-primary">
    启用通知
  </button>
  
  <button
    data-action="click->push-notifications#unsubscribe"
    data-push-notifications-target="unsubscribeButton"
    class="btn-secondary hidden">
    关闭通知
  </button>
  
  <div data-push-notifications-target="status" class="mt-2"></div>
</div>
```

## Web Push Notifications 配置

### 步骤 1: 生成 VAPID 密钥

```bash
npm install -g web-push
web-push generate-vapid-keys
```

输出示例：
```
Public Key: BEl62iUYgUivxIkv69yViEuiBIa...
Private Key: bdSiNzUhUP6piAxLH-tW88zfBlWWveIx0dAsDO66aVU
```

### 步骤 2: 配置环境变量

将生成的密钥添加到 `config/application.yml`:

```yaml
VAPID_PUBLIC_KEY: "BEl62iUYgUivxIkv69yViEuiBIa..."
VAPID_PRIVATE_KEY: "bdSiNzUhUP6piAxLH-tW88zfBlWWveIx0dAsDO66aVU"
VAPID_SUBJECT: "mailto:your-email@example.com"
```

### 步骤 3: 创建 Push Subscription 模型

```bash
rails g model PushSubscription user:references endpoint:text p256dh_key:text auth_key:text
rails db:migrate
```

Model 示例 (`app/models/push_subscription.rb`):

```ruby
class PushSubscription < ApplicationRecord
  belongs_to :user, optional: true

  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true

  # Send notification to this subscription
  def send_notification(title:, body:, data: {})
    message = {
      title: title,
      body: body,
      icon: '/icon.png',
      badge: '/icon.png',
      data: data
    }

    WebPush.payload_send(
      endpoint: endpoint,
      message: message.to_json,
      p256dh: p256dh_key,
      auth: auth_key,
      vapid: {
        subject: ENV['VAPID_SUBJECT'],
        public_key: ENV['VAPID_PUBLIC_KEY'],
        private_key: ENV['VAPID_PRIVATE_KEY']
      }
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    # Subscription expired or invalid, remove it
    destroy
  end
end
```

### 步骤 4: 创建 API 控制器

```bash
rails g controller api/v1/push_subscriptions
```

控制器示例 (`app/controllers/api/v1/push_subscriptions_controller.rb`):

```ruby
class Api::V1::PushSubscriptionsController < Api::BaseController
  before_action :authenticate_user!

  def create
    subscription_params = params.require(:subscription)
    
    # Extract keys from subscription object
    keys = subscription_params[:keys]
    
    @subscription = current_user.push_subscriptions.find_or_create_by(
      endpoint: subscription_params[:endpoint]
    ) do |sub|
      sub.p256dh_key = keys[:p256dh]
      sub.auth_key = keys[:auth]
    end

    if @subscription.persisted?
      render json: { success: true }, status: :created
    else
      render json: { errors: @subscription.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    subscription_params = params.require(:subscription)
    subscription = current_user.push_subscriptions.find_by(
      endpoint: subscription_params[:endpoint]
    )
    
    if subscription&.destroy
      render json: { success: true }, status: :ok
    else
      render json: { errors: 'Subscription not found' }, status: :not_found
    end
  end
end
```

### 步骤 5: 添加路由

在 `config/routes.rb` 中添加：

```ruby
namespace :api do
  namespace :v1 do
    resources :push_subscriptions, only: [:create, :destroy]
  end
end
```

### 步骤 6: 安装 web-push gem

在 `Gemfile` 中添加：

```ruby
gem 'web-push'
```

然后运行：

```bash
bundle install
```

### 步骤 7: 更新 Push Notifications Controller

修改 `app/javascript/controllers/push_notifications_controller.ts` 中的 `getPublicVapidKey()` 方法：

```typescript
private getPublicVapidKey(): string {
  // 从 meta 标签或配置中读取
  const metaTag = document.querySelector('meta[name="vapid-public-key"]')
  return metaTag?.getAttribute('content') || ''
}
```

在 `app/views/layouts/application.html.erb` 的 `<head>` 中添加：

```erb
<meta name="vapid-public-key" content="<%= ENV['VAPID_PUBLIC_KEY'] %>">
```

## 发送推送通知示例

### 方式 1: 直接发送

```ruby
# 发送给单个用户
user = User.find(1)
user.push_subscriptions.each do |subscription|
  subscription.send_notification(
    title: '新消息',
    body: '您有一条新的团队邀请',
    data: { url: '/invitations' }
  )
end
```

### 方式 2: 后台任务

创建 `app/jobs/push_notification_job.rb`:

```ruby
class PushNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, title, body, data = {})
    user = User.find(user_id)
    user.push_subscriptions.each do |subscription|
      begin
        subscription.send_notification(
          title: title,
          body: body,
          data: data
        )
      rescue => e
        Rails.logger.error "Failed to send push notification: #{e.message}"
      end
    end
  end
end
```

使用：

```ruby
PushNotificationJob.perform_later(
  user.id,
  '审核通过',
  '您的个人资料已通过审核',
  { url: '/profile' }
)
```

## 测试 PWA 功能

### 1. 本地测试

PWA 功能需要 HTTPS 或 localhost 环境：

```bash
# 启动开发服务器
bin/dev

# 访问 http://localhost:3000
```

### 2. Chrome DevTools 测试

1. 打开 Chrome DevTools (F12)
2. 切换到 "Application" 标签
3. 左侧菜单查看：
   - **Manifest**: 检查应用清单配置
   - **Service Workers**: 查看 Service Worker 状态
   - **Cache Storage**: 查看缓存内容
   - **Push Messaging**: 测试推送通知

### 3. Lighthouse 审计

1. 打开 Chrome DevTools
2. 切换到 "Lighthouse" 标签
3. 选择 "Progressive Web App" 类别
4. 点击 "Generate report"

目标分数：**90+**

### 4. 移动设备测试

#### iOS (Safari)
- 点击分享按钮
- 选择"添加到主屏幕"
- 应用将以独立模式运行

#### Android (Chrome)
- 浏览器自动显示"添加到主屏幕"横幅
- 或通过菜单手动添加
- 支持完整的 PWA 功能

## 生产环境部署

### 1. HTTPS 要求

⚠️ **重要**: PWA 和 Push Notifications 必须在 HTTPS 环境下运行（localhost 除外）

Clacky 环境已自动配置 HTTPS，无需额外设置。

### 2. 配置检查清单

- [ ] VAPID 密钥已配置
- [ ] 环境变量已设置
- [ ] Push Subscription 模型已创建
- [ ] API 端点已实现
- [ ] Service Worker 已注册
- [ ] 应用图标已准备
- [ ] Manifest 配置正确

### 3. 性能优化

```ruby
# config/initializers/assets.rb
# 预编译 PWA 相关资源
Rails.application.config.assets.precompile += %w[
  logo.png
  app-favicon.svg
  icon.png
]
```

## 故障排查

### Service Worker 未注册

**问题**: Console 显示 "ServiceWorker registration failed"

**解决**:
1. 确保在 HTTPS 或 localhost 环境
2. 检查 `/service-worker.js` 路径是否正确
3. 清除浏览器缓存和 Service Worker

```javascript
// 手动注销 Service Worker (DevTools Console)
navigator.serviceWorker.getRegistrations().then(registrations => {
  registrations.forEach(reg => reg.unregister())
})
```

### Push Notifications 订阅失败

**问题**: "PushManager.subscribe() failed"

**解决**:
1. 确认 VAPID 公钥格式正确
2. 检查用户是否授予通知权限
3. 确认后端 API 端点正常工作
4. 查看浏览器控制台错误信息

### 缓存更新问题

**问题**: 更新代码后用户看到旧版本

**解决**:
1. 更新 `CACHE_VERSION` (v1 → v2)
2. Service Worker 会自动清理旧缓存
3. 用户下次访问时会更新

```javascript
// app/views/pwa/service_worker.js.erb
const CACHE_VERSION = 'v2'; // 更新版本号
```

## 最佳实践

### 1. 缓存策略

- **关键页面**: 使用网络优先策略
- **静态资源**: 使用缓存优先策略
- **API 请求**: 不要缓存（或使用 stale-while-revalidate）

### 2. 通知频率

- 避免过度发送通知（影响用户体验）
- 提供细粒度的通知偏好设置
- 尊重用户的"勿扰"时间

### 3. 离线体验

- 设计专门的离线页面
- 提供清晰的离线状态提示
- 支持离线表单提交（Background Sync）

### 4. 性能监控

```ruby
# 监控 Service Worker 性能
# config/initializers/rack_mini_profiler.rb
if Rails.env.development?
  Rack::MiniProfiler.config.skip_paths << '/service-worker.js'
  Rack::MiniProfiler.config.skip_paths << '/manifest.json'
end
```

## 参考资源

- [MDN - Progressive Web Apps](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)
- [Google - PWA Checklist](https://web.dev/pwa-checklist/)
- [Web Push Protocol](https://tools.ietf.org/html/rfc8030)
- [VAPID Specification](https://tools.ietf.org/html/rfc8292)

## 支持的浏览器

| 功能 | Chrome | Firefox | Safari | Edge |
|------|--------|---------|--------|------|
| Service Worker | ✅ | ✅ | ✅ | ✅ |
| Add to Home Screen | ✅ | ✅ | ✅ | ✅ |
| Push Notifications | ✅ | ✅ | ❌* | ✅ |
| Background Sync | ✅ | ❌ | ❌ | ✅ |

*iOS Safari 不支持 Web Push Notifications（iOS 16.4+ 部分支持）
