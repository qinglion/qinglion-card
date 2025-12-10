# 私有化部署 - 邮件服务配置指南

本文档详细说明如何在私有化部署时配置邮件的发送和接收功能。

## 📧 邮件功能概述

本应用使用 Rails ActionMailer 发送以下类型的邮件：

1. **密码重置邮件** (`UserMailer#password_reset`)
2. **邮箱验证邮件** (`UserMailer#email_verification`)
3. **邀请通知邮件** (`UserMailer#invitation_instructions`)
4. **审核通过通知邮件** (`UserMailer#approval_notification`)

## 🔧 SMTP 邮件发送配置

### 1. 环境变量配置

需要在 `config/application.yml` 中配置以下环境变量：

```yaml
# SMTP 服务器地址
EMAIL_SMTP_ADDRESS: 'smtp.example.com'

# SMTP 端口号（通常为 587 或 465）
EMAIL_SMTP_PORT: '587'

# SMTP 用户名（通常是完整的邮箱地址）
EMAIL_SMTP_USERNAME: 'noreply@yourdomain.com'

# SMTP 密码或 API Key
EMAIL_SMTP_PASSWORD: 'your_smtp_password_or_api_key'

# 发件域名（用于 from 地址）
EMAIL_SMTP_DOMAIN: 'yourdomain.com'

# 公共访问域名（用于邮件中的链接）
PUBLIC_HOST: 'app.yourdomain.com'
```

### 2. 常见邮件服务商配置示例

#### Gmail (Google Workspace)

```yaml
EMAIL_SMTP_ADDRESS: 'smtp.gmail.com'
EMAIL_SMTP_PORT: '587'
EMAIL_SMTP_USERNAME: 'noreply@yourdomain.com'
EMAIL_SMTP_PASSWORD: 'your_app_specific_password'  # 需要生成应用专用密码
EMAIL_SMTP_DOMAIN: 'yourdomain.com'
```

**注意事项：**
- 需要在 Google 账户中启用"两步验证"
- 生成应用专用密码：https://myaccount.google.com/apppasswords
- 不要使用账户主密码

#### SendGrid

```yaml
EMAIL_SMTP_ADDRESS: 'smtp.sendgrid.net'
EMAIL_SMTP_PORT: '587'
EMAIL_SMTP_USERNAME: 'apikey'  # 固定为 'apikey'
EMAIL_SMTP_PASSWORD: 'SG.xxx'  # 你的 SendGrid API Key
EMAIL_SMTP_DOMAIN: 'yourdomain.com'
```

**获取 API Key：**
1. 登录 SendGrid 控制台
2. 进入 Settings → API Keys
3. 创建新的 API Key，权限选择 "Mail Send - Full Access"

#### Mailgun

```yaml
EMAIL_SMTP_ADDRESS: 'smtp.mailgun.org'
EMAIL_SMTP_PORT: '587'
EMAIL_SMTP_USERNAME: 'postmaster@yourdomain.mailgun.org'
EMAIL_SMTP_PASSWORD: 'your_mailgun_smtp_password'
EMAIL_SMTP_DOMAIN: 'yourdomain.com'
```

**获取凭据：**
1. 登录 Mailgun 控制台
2. 进入 Sending → Domain Settings → SMTP credentials
3. 获取 SMTP 用户名和密码

#### AWS SES (Amazon Simple Email Service)

```yaml
EMAIL_SMTP_ADDRESS: 'email-smtp.us-east-1.amazonaws.com'  # 根据区域调整
EMAIL_SMTP_PORT: '587'
EMAIL_SMTP_USERNAME: 'your_smtp_username'  # SMTP 凭据中获取
EMAIL_SMTP_PASSWORD: 'your_smtp_password'  # SMTP 凭据中获取
EMAIL_SMTP_DOMAIN: 'yourdomain.com'
```

**获取 SMTP 凭据：**
1. 登录 AWS SES 控制台
2. 进入 SMTP Settings
3. 创建 SMTP 凭据

**注意：** 新账户需要先申请退出沙盒模式才能发送到任意邮箱

#### 阿里云邮件推送

```yaml
EMAIL_SMTP_ADDRESS: 'smtpdm.aliyun.com'
EMAIL_SMTP_PORT: '465'  # 或 80
EMAIL_SMTP_USERNAME: 'noreply@yourdomain.com'
EMAIL_SMTP_PASSWORD: 'your_smtp_password'
EMAIL_SMTP_DOMAIN: 'yourdomain.com'
```

#### 腾讯企业邮箱

```yaml
EMAIL_SMTP_ADDRESS: 'smtp.exmail.qq.com'
EMAIL_SMTP_PORT: '465'
EMAIL_SMTP_USERNAME: 'noreply@yourdomain.com'
EMAIL_SMTP_PASSWORD: 'your_email_password'
EMAIL_SMTP_DOMAIN: 'yourdomain.com'
```

### 3. 配置文件说明

邮件配置在以下文件中生效：

**开发环境** (`config/environments/development.rb`):
```ruby
if ENV["EMAIL_SMTP_PASSWORD"].present?
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("EMAIL_SMTP_ADDRESS"),
    port: ENV.fetch("EMAIL_SMTP_PORT"),
    user_name: ENV.fetch("EMAIL_SMTP_USERNAME"),
    password: ENV.fetch("EMAIL_SMTP_PASSWORD")
  }
  config.action_mailer.delivery_method = :smtp
end
```

**生产环境** (`config/environments/production.rb`):
```ruby
if ENV["EMAIL_SMTP_PASSWORD"].present?
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("EMAIL_SMTP_ADDRESS"),
    port: ENV.fetch("EMAIL_SMTP_PORT"),
    user_name: ENV.fetch("EMAIL_SMTP_USERNAME"),
    password: ENV.fetch("EMAIL_SMTP_PASSWORD")
  }
  config.action_mailer.delivery_method = :smtp
end
```

### 4. 发件人地址配置

发件人地址在 `app/mailers/application_mailer.rb` 中配置：

```ruby
class ApplicationMailer < ActionMailer::Base
  default from: "notifications@#{ENV.fetch("EMAIL_SMTP_DOMAIN", 'example.com')}"
  layout "mailer"
end
```

发件地址格式为：`notifications@你的域名`

**修改发件人地址：**
如果想自定义发件人地址（如 `noreply@yourdomain.com`），修改 `application_mailer.rb`：

```ruby
default from: "noreply@#{ENV.fetch("EMAIL_SMTP_DOMAIN", 'example.com')}"
```

或使用固定地址：
```ruby
default from: ENV.fetch("EMAIL_FROM_ADDRESS", "noreply@yourdomain.com")
```

## 🧪 测试邮件配置

### 1. Rails Console 测试

```bash
# 开发环境
rails console

# 生产环境
RAILS_ENV=production rails console
```

测试发送邮件：
```ruby
# 创建测试用户（如果不存在）
user = User.create!(
  email: 'test@example.com',
  password: 'password123',
  password_confirmation: 'password123'
)

# 发送密码重置邮件
UserMailer.with(user: user).password_reset.deliver_now

# 发送邮箱验证邮件
UserMailer.with(user: user).email_verification.deliver_now
```

### 2. 使用开发任务测试

创建一个 Rake 任务用于测试邮件发送（可选）：

```ruby
# lib/tasks/email_test.rake
namespace :email do
  desc "Send test email"
  task test: :environment do
    email = ENV['TO'] || 'test@example.com'
    
    puts "Sending test email to #{email}..."
    
    user = User.find_by(email: email) || User.create!(
      email: email,
      password: SecureRandom.hex(16),
      password_confirmation: SecureRandom.hex(16)
    )
    
    UserMailer.with(user: user).password_reset.deliver_now
    
    puts "Test email sent successfully!"
  rescue => e
    puts "Error sending email: #{e.message}"
    puts e.backtrace.join("\n")
  end
end
```

使用方法：
```bash
rake email:test TO=your_email@example.com
```

## 📥 邮件接收配置

Rails 默认不支持直接接收邮件，但可以通过以下方式实现：

### 方案 1: Action Mailbox (推荐)

Action Mailbox 可以处理接收的邮件。

#### 1.1 安装 Action Mailbox

```bash
rails action_mailbox:install
rails db:migrate
```

#### 1.2 配置邮件路由

```ruby
# config/environments/production.rb
config.action_mailbox.ingress = :sendgrid  # 或 :mailgun, :postmark, :mandrill
```

#### 1.3 创建 Mailbox

```bash
rails generate mailbox replies
```

```ruby
# app/mailboxes/replies_mailbox.rb
class RepliesMailbox < ApplicationMailbox
  def process
    # 处理接收到的邮件
    # mail.from 发件人
    # mail.to 收件人
    # mail.subject 主题
    # mail.body 正文
    
    # 示例：记录邮件内容
    Rails.logger.info "Received email from: #{mail.from}"
    Rails.logger.info "Subject: #{mail.subject}"
    Rails.logger.info "Body: #{mail.body}"
  end
end
```

#### 1.4 配置邮件服务商

**SendGrid 配置：**
1. 在 SendGrid 中配置 Inbound Parse Webhook
2. URL 设置为：`https://yourdomain.com/rails/action_mailbox/sendgrid/inbound_emails`
3. 配置要接收的域名或邮箱地址

**Mailgun 配置：**
1. 在 Mailgun Routes 中创建新路由
2. Expression 设置为：`match_recipient("replies@yourdomain.com")`
3. Actions 设置为：`forward("https://yourdomain.com/rails/action_mailbox/mailgun/inbound_emails/mime")`

### 方案 2: IMAP 轮询（不推荐用于生产环境）

如果需要直接通过 IMAP 接收邮件，可以使用 `mail` gem：

```ruby
# Gemfile
gem 'mail'

# lib/tasks/check_email.rake
namespace :email do
  desc "Check incoming emails via IMAP"
  task check: :environment do
    require 'mail'
    
    Mail.defaults do
      retriever_method :imap,
        address: ENV['EMAIL_IMAP_ADDRESS'],
        port: ENV['EMAIL_IMAP_PORT'],
        user_name: ENV['EMAIL_IMAP_USERNAME'],
        password: ENV['EMAIL_IMAP_PASSWORD'],
        enable_ssl: true
    end
    
    Mail.find_and_delete(count: 10) do |email|
      # 处理邮件
      puts "From: #{email.from}"
      puts "Subject: #{email.subject}"
      puts "Body: #{email.body}"
    end
  end
end
```

## 🚀 生产环境部署检查清单

### 部署前检查

- [ ] 已配置所有必需的环境变量（EMAIL_SMTP_*）
- [ ] 已验证 SMTP 凭据的正确性
- [ ] 已在邮件服务商中验证发件域名
- [ ] 已配置 SPF、DKIM、DMARC 记录（提高送达率）
- [ ] 已测试邮件发送功能
- [ ] 已配置 PUBLIC_HOST 为正确的域名
- [ ] 已设置合适的发件人地址

### DNS 配置建议

为了提高邮件送达率，建议配置以下 DNS 记录：

**SPF 记录：**
```
TXT @ "v=spf1 include:_spf.youremailprovider.com ~all"
```

**DKIM 记录：**
（由邮件服务商提供，需要添加到 DNS）

**DMARC 记录：**
```
TXT _dmarc "v=DMARC1; p=none; rua=mailto:postmaster@yourdomain.com"
```

## 🔍 故障排查

### 邮件发送失败

1. **检查环境变量是否正确加载：**
```ruby
rails console
puts ENV['EMAIL_SMTP_ADDRESS']
puts ENV['EMAIL_SMTP_PORT']
puts ENV['EMAIL_SMTP_USERNAME']
puts ENV['EMAIL_SMTP_PASSWORD'].present? ? "已设置" : "未设置"
```

2. **查看日志：**
```bash
# 开发环境
tail -f log/development.log

# 生产环境
tail -f log/production.log
```

3. **测试 SMTP 连接：**
```ruby
require 'net/smtp'

smtp = Net::SMTP.new(ENV['EMAIL_SMTP_ADDRESS'], ENV['EMAIL_SMTP_PORT'])
smtp.enable_starttls
smtp.start('localhost', ENV['EMAIL_SMTP_USERNAME'], ENV['EMAIL_SMTP_PASSWORD'], :login) do
  puts "SMTP 连接成功！"
end
```

### 常见错误及解决方案

**错误：Net::SMTPAuthenticationError**
- 检查用户名和密码是否正确
- 检查是否需要使用应用专用密码（Gmail）
- 检查 SMTP 端口是否正确

**错误：Connection refused**
- 检查 SMTP 地址是否正确
- 检查端口是否正确（587, 465, 25）
- 检查防火墙是否允许 SMTP 连接

**错误：邮件进入垃圾箱**
- 配置 SPF、DKIM、DMARC 记录
- 验证发件域名
- 使用专业的邮件服务商
- 避免使用触发垃圾邮件过滤器的关键词

## 📝 配置示例总结

完整的 `config/application.yml` 邮件配置示例：

```yaml
# 生产环境配置
SECRET_KEY_BASE: 'your_generated_secret_key'
PUBLIC_HOST: 'app.yourdomain.com'

# SMTP 配置（使用 SendGrid 示例）
EMAIL_SMTP_ADDRESS: 'smtp.sendgrid.net'
EMAIL_SMTP_PORT: '587'
EMAIL_SMTP_USERNAME: 'apikey'
EMAIL_SMTP_PASSWORD: 'SG.xxxxxxxxxxxxxxxxxxxx'
EMAIL_SMTP_DOMAIN: 'yourdomain.com'
```

## 🔐 安全建议

1. **不要在代码中硬编码 SMTP 密码**
   - 使用环境变量或密钥管理服务
   
2. **使用应用专用密码**
   - Gmail 等服务需要生成应用专用密码
   
3. **定期轮换 API Key**
   - 定期更新 SMTP 凭据
   
4. **限制 API Key 权限**
   - 只授予必要的邮件发送权限
   
5. **监控邮件发送量**
   - 设置异常告警，防止被滥用

## 📚 参考资源

- [Rails Action Mailer 官方文档](https://guides.rubyonrails.org/action_mailer_basics.html)
- [Action Mailbox 官方文档](https://guides.rubyonrails.org/action_mailbox_basics.html)
- [SendGrid Rails 集成指南](https://docs.sendgrid.com/for-developers/sending-email/rubyonrails)
- [Mailgun Ruby 文档](https://documentation.mailgun.com/en/latest/api-libraries.html#ruby)

## 💡 最佳实践

1. **使用专业邮件服务商** - 避免使用自建 SMTP 服务器
2. **异步发送邮件** - 使用 ActiveJob 后台发送，提高响应速度
3. **邮件模板管理** - 使用清晰的邮件模板，便于维护
4. **监控和日志** - 记录邮件发送状态，便于追踪问题
5. **测试环境隔离** - 开发环境避免发送到真实邮箱
