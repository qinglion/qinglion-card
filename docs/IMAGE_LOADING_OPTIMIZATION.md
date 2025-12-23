# 图片加载失败优化方案

## 问题描述

在生产环境发版期间，用户可能遇到：
1. 访问时服务器发版，图片加载失败
2. 浏览器缓存失败响应，发版后仍显示失败
3. 其他新用户可以正常看到图片

## 解决方案

实现了智能图片加载失败重试机制：

### 核心功能

1. **自动重试** - 失败时自动重试3次，每次添加时间戳防止缓存
2. **递增延迟** - 1秒、2秒、3秒递增，避免瞬时大量请求
3. **友好占位符** - 彻底失败后显示占位符和重试按钮
4. **视觉反馈** - 失败图片灰度显示，淡入动画

### 技术实现

**文件**:
- Controller: `app/javascript/controllers/image_fallback_controller.ts`
- Helper: `app/helpers/application_helper.rb` 
- Styles: `app/assets/stylesheets/application.css`

**防缓存原理**:
```
原始: https://example.com/image.jpg
重试1: https://example.com/image.jpg?retry=1702345678901
重试2: https://example.com/image.jpg?retry=1702345680902
```

每次重试添加不同时间戳，浏览器视为新URL，忽略失败缓存。

## 使用方法

### 自动启用（推荐）

所有 `optimized_image_tag` 自动包含失败重试：

```erb
<%= optimized_image_tag @profile.avatar, 
    alt: "头像", 
    class: "w-20 h-20",
    size: [200, 200] %>
```

### 手动添加

```erb
<img src="<%= url %>" 
     data-controller="image-fallback"
     data-image-fallback-max-retries-value="3"
     data-image-fallback-retry-delay-value="1000">
```

### 自定义参数

```erb
<%= optimized_image_tag @profile.avatar,
    data: {
      image_fallback_max_retries_value: 5,
      image_fallback_retry_delay_value: 2000,
      image_fallback_fallback_text_value: "加载失败"
    } %>
```

## 测试方法

1. 打开开发者工具（F12）
2. Network标签 → 选择"Offline"
3. 刷新页面，观察图片失败
4. 切换回"No throttling"
5. 观察图片自动重试并成功

## 已应用页面

- ✅ 所有使用 `optimized_image_tag` 的页面（自动）
- ✅ `app/views/cards/show.html.erb` - 名片头像
- ✅ `app/views/dashboards/settings.html.erb` - 设置页面
- ✅ `app/views/home/index.html.erb` - 首页成员列表

## 性能影响

- 首次加载：无额外开销
- 失败重试：仅在失败时触发
- 内存占用：每图片仅保存URL和计数
