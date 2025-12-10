# 简化的注册流程文档

## 概述

本文档描述了基于邀请链接的无密码注册流程。用户通过邀请链接提交申请后，无需立即设置密码。管理员审核通过后，用户会收到包含随机验证码的邮件，点击链接设置密码即可完成注册。

## 流程图

```
用户访问邀请链接
    ↓
填写基本信息（无需密码）
    ↓
提交申请（status: pending, activated: false）
    ↓
管理员审核
    ↓
点击"通过"按钮
    ↓
系统发送审批邮件（包含随机验证码）
    ↓
用户点击邮件链接
    ↓
设置登录密码
    ↓
完成注册，可以登录
```

## 主要改动

### 1. 数据库变更

添加了 `registration_token` 和 `registration_token_expires_at` 字段到 `users` 表：

```ruby
# db/migrate/20251210073648_add_registration_token_to_users.rb
class AddRegistrationTokenToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :registration_token, :string
    add_column :users, :registration_token_expires_at, :datetime
  end
end
```

### 2. User 模型

添加了注册令牌相关方法：

```ruby
# app/models/user.rb
def generate_registration_token
  self.registration_token = SecureRandom.urlsafe_base64(32)
  self.registration_token_expires_at = 7.days.from_now
  save!
  registration_token
end

def valid_registration_token?(token)
  return false if registration_token.blank? || registration_token_expires_at.blank?
  return false if registration_token_expires_at < Time.current
  registration_token == token
end

def clear_registration_token!
  update(registration_token: nil, registration_token_expires_at: nil)
end
```

### 3. Profile 模型

更新了 `approve!` 方法，自动发送审批通过邮件：

```ruby
# app/models/profile.rb
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
rescue ActiveRecord::RecordInvalid => e
  errors.add(:base, e.message)
  false
end
```

### 4. 邀请表单

移除了密码字段，用户注册时只需填写：
- 邮箱
- 真实姓名
- 职位
- 部门（可选）
- 个人简介（可选）
- 头像（可选）

### 5. InvitationsController

更新为无密码注册：

```ruby
# app/controllers/invitations_controller.rb
def create
  # ...
  @user = User.new(user_params)
  @user.verified = false
  @user.activated = false
  @user.password = SecureRandom.hex(16)  # 生成临时随机密码
  
  if @user.save
    @user.profile.update(
      organization_id: @organization.id,
      status: 'pending',
      email: @user.email
    )
    
    redirect_to root_path, notice: "申请已提交！管理员审核通过后，您将收到包含验证码的邮件，请按邮件指引完成注册。"
  # ...
end
```

### 6. 新增密码设置流程

创建了 `Identity::RegistrationCompletionsController` 处理密码设置：

```ruby
# app/controllers/identity/registration_completions_controller.rb
class Identity::RegistrationCompletionsController < ApplicationController
  def edit
    # 显示密码设置表单
  end

  def update
    if @user.update(user_params)
      @user.clear_registration_token!
      redirect_to sign_in_path, notice: "密码设置成功！请使用邮箱和密码登录"
    # ...
  end
end
```

### 7. 邮件模板

创建了 `approval_notification.html.erb`，包含：
- 欢迎信息
- 设置密码的链接按钮
- 登录邮箱
- 随机验证码（明文显示）
- 过期提醒（7天）

### 8. 路由

添加了新路由：

```ruby
# config/routes.rb
namespace :identity do
  resource :registration_completion, only: [:edit, :update], path: 'complete-registration'
end
```

## 用户体验流程

### 第一步：通过邀请链接注册

1. 用户点击邀请链接，例如：`https://example.com/invitation/new?token=abc123`
2. 填写基本信息（无需密码）
3. 点击"提交申请"
4. 看到提示："申请已提交！管理员审核通过后，您将收到包含验证码的邮件"

### 第二步：管理员审核

1. 管理员在后台看到待审核成员列表
2. 点击"通过"按钮
3. 系统自动：
   - 将用户状态设为 `activated: true`
   - 生成 7 天有效的注册令牌
   - 发送审批邮件

### 第三步：用户设置密码

1. 用户收到邮件，标题："您的申请已通过审核"
2. 邮件包含：
   - 设置密码的按钮链接
   - 登录邮箱
   - 随机验证码（可备用）
3. 点击按钮，跳转到密码设置页面
4. 设置密码并确认
5. 看到提示："密码设置成功！请使用邮箱和密码登录"
6. 使用邮箱和新密码登录系统

## 安全考虑

1. **令牌过期**：注册令牌 7 天后自动失效
2. **一次性使用**：设置密码后令牌立即清除
3. **随机生成**：使用 `SecureRandom.urlsafe_base64(32)` 生成令牌
4. **临时密码**：注册时生成随机临时密码，用户无法使用

## 测试

所有相关测试已更新并通过：

```bash
bundle exec rspec spec/requests/invitations_spec.rb
```

测试覆盖：
- 邀请链接验证
- 无密码注册流程
- 审核后生成令牌
- 通过令牌设置密码
- 密码设置后可以登录
