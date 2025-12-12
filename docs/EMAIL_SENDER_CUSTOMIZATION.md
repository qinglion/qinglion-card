# 邮件发送者自定义功能

## 概述

本文档说明了如何在审核通过通知邮件中使用组织名称作为发件人显示名称和邮件标题，提升用户体验。

## 功能特性

### 1. 自定义邮件标题

审核通过通知邮件的标题使用**组织名称**而不是应用名称：

**修改前：** `[出海去孵化器] 您的申请已通过审核`
**修改后：** `[青狮满天星] 您的申请已通过审核`

### 2. 自定义发件人显示名称

邮件发送者显示为**组织名称**而不是纯邮件地址：

**修改前：** `notifications@mail.clacky.ai`
**修改后：** `青狮满天星 <notifications@mail.clacky.ai>`

这使得邮件在收件箱中更容易识别，增强品牌形象。

## 技术实现

### 代码修改

文件：`app/mailers/user_mailer.rb`

```ruby
def approval_notification
  @user = params[:user]
  @token = params[:token]
  @organization_name = params[:organization_name]
  
  mail(
    to: @user.email, 
    subject: "[#{@organization_name}] 您的申请已通过审核",
    from: "#{@organization_name} <notifications@#{ENV.fetch('EMAIL_SMTP_DOMAIN', 'example.com')}>"
  )
end
```

### 关键点

1. **邮件标题**：使用 `@organization_name` 变量替代 `Rails.application.config.x.appname`
2. **发件人格式**：使用 RFC 822 标准格式 `"显示名称" <email@domain.com>`
3. **域名获取**：从环境变量 `EMAIL_SMTP_DOMAIN` 获取邮件域名

## 调用位置

审核通过通知邮件在以下两处发送：

### 1. 自动审核通过（Profile 模型）

文件：`app/models/profile.rb`

```ruby
def approve!
  transaction do
    update!(status: 'approved')
    if user.present?
      token = user.generate_registration_token
      user.update!(activated: true)
      
      UserMailer.with(
        user: user, 
        token: token, 
        organization_name: organization&.name || 'Our Platform'
      ).approval_notification.deliver_later
    end
  end
end
```

### 2. 手动重新发送（Admin 控制器）

文件：`app/controllers/admin/organizations_controller.rb`

```ruby
def resend_email
  # ... 验证逻辑 ...
  
  token = user.generate_registration_token
  UserMailer.with(
    user: user,
    token: token,
    organization_name: @organization.name
  ).approval_notification.deliver_now
end
```

## 测试验证

### 验证命令

```bash
# 检查邮件配置
bundle exec rails runner "
  org = Organization.first
  user = User.first
  mail = UserMailer.with(
    user: user, 
    token: 'test-token', 
    organization_name: org.name
  ).approval_notification
  
  puts 'Subject: ' + mail.subject
  puts 'From: ' + mail[:from].to_s
  puts 'To: ' + mail.to.join(', ')
"
```

### 预期输出

```
Subject: [青狮满天星] 您的申请已通过审核
From: "青狮满天星" <notifications@mail.clacky.ai>
To: user@example.com
```

### 运行测试套件

```bash
# 测试邮件相关功能
bundle exec rspec spec/requests/admin_organizations_spec.rb --format documentation
```

所有测试应该全部通过，包括：
- ✅ resends approval email to approved member
- ✅ does not resend email to non-approved member
- ✅ handles error when profile has no user

## 配置要求

确保 `config/application.yml` 中配置了正确的 SMTP 域名：

```yaml
EMAIL_SMTP_DOMAIN: '<%= ENV.fetch("CLACKY_EMAIL_SMTP_DOMAIN", "") %>'
```

在生产环境中，该值通常由 Clacky 平台自动设置。

## 注意事项

1. **组织名称必须传递**：调用 `approval_notification` 时必须传递 `organization_name` 参数
2. **邮件客户端兼容性**：大多数现代邮件客户端都支持显示名称，但某些旧版客户端可能只显示邮件地址
3. **字符编码**：组织名称包含中文时会自动进行 UTF-8 编码，无需手动处理
4. **SMTP 配置**：发件人地址必须与 SMTP 服务器配置的发件域名匹配

## 未来优化

可以考虑的扩展功能：

1. 为其他邮件类型（密码重置、邮箱验证等）也添加组织名称显示
2. 支持管理员在后台自定义邮件发件人名称
3. 添加邮件模板预览功能
4. 支持多语言发件人名称
