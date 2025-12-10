# 重新发送审核通过邮件功能

## 功能说明

当管理员在后台批准成员后，系统会自动发送审核通过邮件给用户。但在某些情况下，邮件可能发送失败（例如 SMTP 配置错误、网络问题等）。此功能允许管理员手动重新发送审核通过邮件。

## 使用场景

- **邮件发送失败**：SMTP 配置错误或网络问题导致邮件发送失败
- **用户未收到邮件**：邮件被邮箱服务商拦截或进入垃圾箱
- **用户误删邮件**：用户删除了审核通过邮件，需要重新获取激活链接
- **邮件配置更新后**：修复了 SMTP 配置后，需要重新发送之前失败的邮件

## 功能位置

**后台管理** → **组织管理** → **成员管理** → **已批准成员列表**

在已批准成员列表中，每个成员行都有以下操作按钮：
- 📋 **查看名片**：在新标签页中打开该成员的公开名片
- ✉️ **重新发送邮件**：重新发送审核通过邮件到该成员的注册邮箱

## 操作步骤

1. 登录后台管理（/admin）
2. 进入"组织管理" → "成员管理"
3. 在"已批准成员"列表中找到需要重新发送邮件的成员
4. 点击该成员行右侧的"重新发送邮件"按钮
5. 系统会立即尝试发送邮件并显示结果：
   - ✅ 成功：显示"已成功重新发送邮件至 xxx@example.com"
   - ❌ 失败：显示"邮件发送失败：错误信息"

## 技术实现

### 路由

```ruby
POST /admin/organization/members/:profile_id/resend_email
```

### Controller 方法

```ruby
def resend_approval_email
  profile = @organization.profiles.find(params[:profile_id])
  
  # 只能对已批准的成员重新发送
  unless profile.approved?
    redirect_to members_admin_organization_path(@organization), 
                alert: '只能对已批准的成员重新发送邮件。'
    return
  end
  
  user = profile.user
  
  if user.nil?
    redirect_to members_admin_organization_path(@organization), 
                alert: '该成员没有关联的用户账户。'
    return
  end
  
  begin
    # 生成新的注册令牌
    token = user.generate_registration_token
    
    # 立即发送邮件（不使用后台任务）
    UserMailer.with(
      user: user,
      token: token,
      organization_name: @organization.name
    ).approval_notification.deliver_now
    
    redirect_to members_admin_organization_path(@organization), 
                notice: "已成功重新发送邮件至 #{user.email}。"
  rescue => e
    Rails.logger.error "Failed to resend approval email: #{e.message}"
    redirect_to members_admin_organization_path(@organization), 
                alert: "邮件发送失败：#{e.message}"
  end
end
```

### 视图代码

```erb
<%= button_to '重新发送邮件', 
    resend_email_member_admin_organization_path(@organization, profile_id: profile.id), 
    method: :post, 
    class: 'btn-warning btn-sm', 
    title: '重新发送审核通过邮件' %>
```

## 安全性考虑

### 权限控制

- ✅ 仅管理员可访问
- ✅ 通过 `Admin::BaseController` 的 `before_action :require_admin` 保护
- ✅ 只能对已批准状态的成员重新发送邮件

### 令牌安全

- ✅ 每次重新发送都会生成新的注册令牌
- ✅ 令牌使用 Rails 的 `generates_token_for` 机制，具有时效性
- ✅ 旧令牌会自动失效

### 错误处理

- ✅ 使用 `begin...rescue` 捕获邮件发送异常
- ✅ 记录错误日志到 `Rails.logger`
- ✅ 向管理员显示友好的错误信息

## 邮件内容

重新发送的邮件与首次批准时的邮件内容相同，包含：

- 欢迎信息和组织名称
- 激活账户的链接（包含注册令牌）
- 设置密码的说明
- 帮助和支持信息

邮件模板位置：`app/views/user_mailer/approval_notification.html.erb`

## 常见问题 FAQ

### Q1: 为什么使用 `deliver_now` 而不是 `deliver_later`？

**A:** 使用 `deliver_now` 立即发送邮件，可以：
- 立即获取发送结果（成功或失败）
- 向管理员实时反馈邮件发送状态
- 避免后台任务延迟导致的用户体验问题

如果邮件发送失败，管理员可以立即看到错误信息，并采取相应措施（如检查 SMTP 配置）。

### Q2: 可以多次重新发送吗？

**A:** 可以。没有限制重新发送的次数。每次发送都会生成新的注册令牌，旧令牌会自动失效。

### Q3: 如果用户已经激活了账户，还能重新发送吗？

**A:** 可以。即使用户已经激活账户，管理员仍可以重新发送邮件。但用户点击邮件中的链接时，如果账户已激活，会被引导到登录页面。

### Q4: 邮件发送失败后如何排查？

**A:** 按以下步骤排查：

1. **检查 SMTP 配置**：
   ```bash
   rails runner "puts ENV['EMAIL_SMTP_ADDRESS']"
   rails runner "puts ENV['EMAIL_SMTP_PORT']"
   rails runner "puts ENV['EMAIL_SMTP_USERNAME']"
   rails runner "puts ENV['EMAIL_SMTP_PASSWORD'].present?"
   ```

2. **查看日志**：
   ```bash
   tail -f log/production.log
   ```

3. **测试 SMTP 连接**：
   ```ruby
   rails console
   require 'net/smtp'
   smtp = Net::SMTP.new(ENV['EMAIL_SMTP_ADDRESS'], ENV['EMAIL_SMTP_PORT'])
   smtp.enable_starttls
   smtp.start('localhost', ENV['EMAIL_SMTP_USERNAME'], ENV['EMAIL_SMTP_PASSWORD'], :login) do
     puts "SMTP 连接成功！"
   end
   ```

4. **参考邮件配置文档**：[docs/EMAIL_CONFIGURATION.md](EMAIL_CONFIGURATION.md)

### Q5: 重新发送邮件会改变用户状态吗？

**A:** 不会。重新发送邮件只是重新发送通知邮件，不会改变用户的任何状态（已批准状态、激活状态等）。

## 测试

测试文件：`spec/requests/admin_organizations_spec.rb`

```ruby
describe "POST /admin/organization/members/:profile_id/resend_email" do
  it "resends approval email to approved member" do
    user = create(:user)
    profile = user.profile
    profile.update(organization: organization, status: 'approved')
    
    expect {
      post resend_email_member_admin_organization_path(profile_id: profile.id)
    }.to change { ActionMailer::Base.deliveries.count }.by(1)
    
    expect(response).to have_http_status(:redirect)
    expect(flash[:notice]).to include('已成功重新发送邮件')
  end
  
  it "does not resend email to non-approved member" do
    user = create(:user)
    profile = user.profile
    profile.update(organization: organization, status: 'pending')
    
    post resend_email_member_admin_organization_path(profile_id: profile.id)
    
    expect(response).to have_http_status(:redirect)
    expect(flash[:alert]).to include('只能对已批准的成员重新发送邮件')
  end
end
```

运行测试：
```bash
bundle exec rspec spec/requests/admin_organizations_spec.rb:58 --format documentation
```

## 相关文档

- [邮件配置指南](EMAIL_CONFIGURATION.md) - 私有化部署时的邮件服务配置
- [用户注册流程](REGISTRATION_FLOW.md) - 完整的用户注册和激活流程
- [组织设置说明](ORGANIZATION_SETUP.md) - 组织管理功能说明

## 版本历史

- **v1.0** (2024-12-10)：初始版本，支持重新发送审核通过邮件
