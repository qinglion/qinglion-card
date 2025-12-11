# Profile Assistant MCP Tools

## 概述

Profile Assistant 是一个 AI 数字分身系统,为每个名片提供智能咨询服务。访客可以通过 AI 助手了解专业人士的信息、团队能力,并获得团队成员推荐。

## 架构

### 核心组件

1. **ProfileAssistantService** - AI 数字分身核心服务
   - 构建系统提示词和 MCP 工具
   - 处理工具调用
   - 管理团队成员推荐

2. **ProfileAssistantStreamJob** - 流式响应处理
   - 集成 LlmService 进行流式对话
   - 实时广播 AI 响应和工具调用
   - 处理团队成员名片推荐

3. **ProfileChatChannel** - WebSocket 通道
   - 管理访客连接
   - 接收用户消息
   - 触发 AI 响应

4. **profile_chat_controller.ts** - 前端控制器
   - 处理用户输入
   - 显示 AI 流式响应
   - 展示团队成员名片
   - 显示工具调用指示器

## MCP 工具集

### 1. get_profile_info

获取当前专业人士的详细信息。

**参数:**
```json
{
  "include_cases": boolean,      // 是否包含案例研究
  "include_honors": boolean       // 是否包含荣誉奖项
}
```

**返回:**
```json
{
  "full_name": "张律师",
  "title": "高级律师",
  "company": "XX律师事务所",
  "bio": "...",
  "specializations": ["合同法", "知识产权"],
  "stats": {...},
  "contact": {...},
  "case_studies": [...],    // 如果 include_cases=true
  "honors": [...]           // 如果 include_honors=true
}
```

**使用场景:**
- 访客询问专业人士的详细信息
- 需要展示专业背景和成就

### 2. get_team_members

获取所属组织的团队成员列表。

**参数:**
```json
{
  "specialization": "知识产权",  // 可选,按专业领域筛选
  "limit": 10                    // 返回数量限制
}
```

**返回:**
```json
[
  {
    "id": 123,
    "full_name": "李律师",
    "title": "知识产权专家",
    "department": "知识产权部",
    "specializations": ["知识产权", "商标法"],
    "years_experience": 15,
    "bio": "..."
  }
]
```

**使用场景:**
- 访客询问团队能力
- 需要找到特定专业领域的专家

### 3. recommend_team_member

推荐一个团队成员给访客,系统会展示该成员的名片。

**参数:**
```json
{
  "profile_id": 123,               // 必需,团队成员的 ID
  "reason": "李律师在知识产权..."   // 必需,推荐理由
}
```

**返回:**
```json
{
  "success": true,
  "profile": {
    "id": 123,
    "slug": "li-lawyer",
    "full_name": "李律师",
    "title": "知识产权专家",
    "department": "知识产权部",
    "specializations": ["知识产权", "商标法"],
    "bio": "...",
    "stats": {...},
    "avatar_url": "/rails/active_storage/..."
  },
  "reason": "李律师在知识产权..."
}
```

**使用场景:**
- AI 判断访客的问题需要特定专业领域的帮助
- 团队中有更合适的专家可以解决访客问题

## 用户体验流程

### 1. 访客进入咨询页面

```
访客 → 点击名片上的"咨询"标签 → 进入对话界面
```

URL: `/consultations?profile_id=1`

### 2. 对话交互

```
访客: "你们能处理知识产权案件吗?"
AI: 思考中... [调用 get_team_members 工具]
AI: "当然可以!我们团队在知识产权领域有丰富的经验..."
AI: [调用 recommend_team_member 展示李律师的名片]
```

### 3. 名片展示

系统自动在对话中插入团队成员的名片,包含:
- 头像
- 姓名、职位
- 专业领域标签
- 执业年限、案例数量
- 推荐理由
- "查看详细信息"按钮

访客可以点击按钮跳转到该成员的完整名片页面。

## 技术细节

### 流式响应

AI 响应采用流式传输,提供更好的用户体验:

```ruby
LlmService.call_stream(
  prompt: prompt,
  system: system_prompt,
  tools: tools,
  tool_handler: tool_handler
) do |chunk|
  # 实时广播每个文本片段
  ActionCable.server.broadcast(channel_name, {
    type: 'assistant-chunk',
    chunk: chunk
  })
end
```

### 工具调用广播

当 AI 调用工具时,前端会显示指示器:

```ruby
ActionCable.server.broadcast(channel_name, {
  type: 'tool-call',
  tool_name: 'get_team_members',
  arguments: { specialization: '知识产权' }
})
```

前端显示: "正在查询团队成员..."

### 名片推荐广播

当推荐团队成员时,发送名片数据:

```ruby
ActionCable.server.broadcast(channel_name, {
  type: 'member-card',
  profile: { id: 123, slug: 'li-lawyer', ... },
  reason: '李律师在知识产权领域...'
})
```

前端自动渲染为可交互的名片卡片。

## 配置要求

### 环境变量

确保配置了 LLM 服务:

```yaml
# config/application.yml
LLM_BASE_URL: 'https://api.openai.com/v1'
LLM_API_KEY: 'your-api-key'
LLM_MODEL: 'gpt-4'
```

### 数据库

需要以下模型关联:
- Profile belongs_to Organization
- Organization has_many Profiles
- Profile 需要 status='approved' 才会出现在团队列表中

## 测试

### 手动测试步骤

1. 创建测试数据:
```bash
rails runner "
  org = Organization.create!(name: '测试律所')
  user1 = User.create!(email: 'lawyer1@test.com', password: 'password')
  user2 = User.create!(email: 'lawyer2@test.com', password: 'password')
  
  profile1 = Profile.create!(
    user: user1,
    organization: org,
    full_name: '张律师',
    title: '高级律师',
    specializations: ['合同法'],
    status: 'approved'
  )
  
  profile2 = Profile.create!(
    user: user2,
    organization: org,
    full_name: '李律师',
    title: '知识产权专家',
    specializations: ['知识产权', '商标法'],
    status: 'approved'
  )
  
  puts \"Profile 1 slug: #{profile1.slug}\"
"
```

2. 访问咨询页面:
```
http://localhost:3000/consultations?profile_id=<profile_id>
```

3. 测试对话:
- "你的专业领域是什么?"
- "你们团队有知识产权专家吗?"
- "推荐一个擅长商标法的律师"

### 自动化测试

```bash
bundle exec rspec spec/services/profile_assistant_service_spec.rb
bundle exec rspec spec/channels/profile_chat_channel_spec.rb
bundle exec rspec spec/requests/consultations_spec.rb
```

## 扩展建议

### 未来改进方向

1. **会话历史**: 保存和展示历史对话记录
2. **预设问题**: 提供常见问题的快速入口
3. **多语言支持**: 支持中英文切换
4. **富文本回复**: 支持 Markdown、链接、图片
5. **情感分析**: 根据访客情绪调整回复风格
6. **访客信息收集**: 在推荐成员前收集访客需求信息
7. **预约功能**: 直接从对话中预约咨询时间
8. **评价系统**: 访客可以评价 AI 助手的回复质量

## 故障排查

### 常见问题

**Q: AI 不回复**
A: 检查 LLM_API_KEY 和 LLM_BASE_URL 是否正确配置

**Q: 团队成员列表为空**
A: 确保 Profile 的 status='approved' 且属于同一 Organization

**Q: 名片推荐不显示**
A: 检查 Profile 是否有 slug,检查前端 handleMemberCard 方法

**Q: WebSocket 连接失败**
A: 检查 ActionCable 配置,确保 cable.yml 正确

### 日志调试

查看日志:
```bash
tail -f log/development.log | grep ProfileAssistant
```

查看 WebSocket 日志:
```bash
tail -f log/development.log | grep ActionCable
```

## 总结

Profile Assistant 通过 MCP 工具集实现了智能的团队推荐功能,让访客可以快速找到最合适的专业人士。系统采用流式响应、实时工具调用反馈和可交互名片展示,提供了流畅的用户体验。
