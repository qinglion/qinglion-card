# Profile Assistant Service - AI 数字分身服务
# 为访客提供专业咨询，可以获取个人信息和团队信息
class ProfileAssistantService < ApplicationService
  def initialize(profile, user_message, chat_session)
    @profile = profile
    @user_message = user_message
    @chat_session = chat_session
  end

  def call
    # 构建系统提示词和工具集
    system_prompt = build_system_prompt
    tools = build_mcp_tools
    
    # 使用流式响应
    {
      success: true,
      system_prompt: system_prompt,
      tools: tools
    }
  rescue StandardError => e
    Rails.logger.error("ProfileAssistantService error: #{e.message}")
    {
      success: false,
      error: '处理消息时出现错误,请重试。'
    }
  end

  # 处理工具调用
  def self.handle_tool_call(tool_name, arguments, profile)
    case tool_name
    when 'get_profile_info'
      get_profile_info(profile, arguments)
    when 'get_team_members'
      get_team_members(profile, arguments)
    when 'recommend_team_member'
      recommend_team_member(profile, arguments)
    else
      { error: "Unknown tool: #{tool_name}" }
    end
  end

  private

  def build_system_prompt
    organization_info = if @profile.organization
      "所属组织：#{@profile.organization.name}"
    else
      "暂无组织信息"
    end

    team_count = @profile.organization&.approved_profiles&.count || 0

    <<~PROMPT
      你是#{@profile.full_name}的**智能名片助手**，负责协助访客了解#{@profile.full_name}和团队的基本信息。

      ## 📋 你的身份定位：
      - 你是一个**名片助手**，不是专业顾问或咨询师
      - 你的作用是**介绍和引荐**，而不是提供专业意见或解决方案
      - 你可以介绍专业背景，但**不要**提供具体的专业建议、法律意见或技术方案

      ## 👤 专业人士信息：
      - 姓名：#{@profile.full_name}
      - 职位：#{@profile.title}
      - 公司：#{@profile.company || '未设置'}
      - 部门：#{@profile.department || '未设置'}
      - #{organization_info}
      - 专业领域：#{@profile.specializations_array.join('、')}
      - 简介：#{@profile.bio || '暂无简介'}
      - 执业年限：#{@profile.stats&.dig('years_experience') || 0}年
      - 成功案例：#{@profile.stats&.dig('cases_handled') || 0}个
      - 服务客户：#{@profile.stats&.dig('clients_served') || 0}位

      ## 👥 团队信息：
      - 团队成员数量：#{team_count}人

      ## ✅ 你应该做的：
      1. **介绍背景**：介绍#{@profile.full_name}的专业背景、经验和擅长领域
      2. **了解需求**：询问访客的需求，了解他们想要什么样的帮助
      3. **推荐联系**：根据访客需求，推荐合适的团队成员
      4. **使用工具**：
         - 使用 `get_profile_info` 获取详细的个人信息
         - 使用 `get_team_members` 查看团队成员列表
         - 使用 `recommend_team_member` 推荐最合适的团队成员

      ## ❌ 你不应该做的：
      1. **不要提供专业咨询**：不要回答具体的专业问题（如法律咨询、技术方案等）
      2. **不要做承诺**：不要承诺能处理什么案件或提供什么服务
      3. **不要自称专家**：不要说"我可以帮您"、"我们可以处理"，而应该说"#{@profile.full_name}擅长这个领域，我可以为您推荐"
      4. **不要直接回答专业问题**：遇到专业问题时，应该说"这是一个专业问题，建议您直接联系#{@profile.full_name}或相关专家"

      ## 💬 回答风格：
      - 简洁友好，重点突出
      - 使用 Markdown 格式（标题、列表、加粗等）
      - 主动询问访客需求
      - 及时推荐合适的人选
      - 始终记住：你是**引荐者**，不是**服务提供者**

      ## 📝 对话示例：
      **错误示例❌**：
      访客："你们能处理知识产权案件吗？"
      你："当然可以！我们团队在知识产权领域有丰富的经验..."
      
      **正确示例✅**：
      访客："你们能处理知识产权案件吗？"
      你："感谢您的咨询！#{@profile.full_name}的团队确实有知识产权方面的专业人士。让我为您查看一下团队中谁最合适为您提供帮助。您方便简单描述一下您的需求吗？"
      [然后使用 get_team_members 查看团队，再用 recommend_team_member 推荐]
    PROMPT
  end

  def build_mcp_tools
    [
      {
        type: 'function',
        function: {
          name: 'get_profile_info',
          description: '获取当前专业人士的详细信息，包括案例、荣誉等',
          parameters: {
            type: 'object',
            properties: {
              include_cases: {
                type: 'boolean',
                description: '是否包含案例研究'
              },
              include_honors: {
                type: 'boolean',
                description: '是否包含荣誉奖项'
              }
            }
          }
        }
      },
      {
        type: 'function',
        function: {
          name: 'get_team_members',
          description: '获取所属组织的团队成员列表，可以按专业领域筛选',
          parameters: {
            type: 'object',
            properties: {
              specialization: {
                type: 'string',
                description: '筛选特定专业领域的成员，例如"知识产权"、"合同法"等'
              },
              limit: {
                type: 'integer',
                description: '返回的成员数量限制，默认10'
              }
            }
          }
        }
      },
      {
        type: 'function',
        function: {
          name: 'recommend_team_member',
          description: '推荐一个团队成员给访客，系统会展示该成员的名片。只有在确定推荐某位成员时才调用此工具。',
          parameters: {
            type: 'object',
            properties: {
              profile_id: {
                type: 'integer',
                description: '要推荐的团队成员的 profile_id'
              },
              reason: {
                type: 'string',
                description: '推荐理由，简短说明为什么推荐这位成员'
              }
            },
            required: ['profile_id', 'reason']
          }
        }
      }
    ]
  end

  # MCP 工具实现
  class << self
    def get_profile_info(profile, arguments)
      result = {
        full_name: profile.full_name,
        title: profile.title,
        company: profile.company,
        department: profile.department,
        bio: profile.bio,
        specializations: profile.specializations_array,
        stats: profile.stats,
        contact: {
          phone: profile.phone,
          email: profile.email,
          location: profile.location
        }
      }

      if arguments['include_cases']
        result[:case_studies] = profile.case_studies.map do |cs|
          {
            title: cs.title,
            category: cs.category,
            date: cs.date,
            description: cs.description
          }
        end
      end

      if arguments['include_honors']
        result[:honors] = profile.honors.map do |h|
          {
            title: h.title,
            organization: h.organization,
            date: h.date,
            description: h.description
          }
        end
      end

      result.to_json
    end

    def get_team_members(profile, arguments)
      return { error: '该专业人士暂未加入任何组织' }.to_json unless profile.organization

      members = profile.organization.approved_profiles.where.not(id: profile.id)
      
      # 按专业领域筛选
      if arguments['specialization'].present?
        keyword = arguments['specialization']
        members = members.select do |m|
          m.specializations_array.any? { |s| s.include?(keyword) }
        end
      end

      limit = arguments['limit'] || 10
      members = members.first(limit)

      result = members.map do |member|
        {
          id: member.id,
          full_name: member.full_name,
          title: member.title,
          department: member.department,
          specializations: member.specializations_array,
          years_experience: member.stats&.dig('years_experience') || 0,
          bio: member.bio&.truncate(100)
        }
      end

      result.to_json
    end

    def recommend_team_member(profile, arguments)
      profile_id = arguments['profile_id']
      reason = arguments['reason']

      recommended_profile = Profile.find_by(id: profile_id)
      
      unless recommended_profile
        return { error: '未找到该团队成员' }.to_json
      end

      # 验证是否是同一组织的成员
      unless recommended_profile.organization_id == profile.organization_id
        return { error: '该成员不在同一组织' }.to_json
      end

      {
        success: true,
        profile: {
          id: recommended_profile.id,
          slug: recommended_profile.slug,
          full_name: recommended_profile.full_name,
          title: recommended_profile.title,
          department: recommended_profile.department,
          specializations: recommended_profile.specializations_array,
          bio: recommended_profile.bio,
          stats: recommended_profile.stats,
          avatar_url: recommended_profile.avatar.attached? ? 
            Rails.application.routes.url_helpers.rails_blob_path(recommended_profile.avatar, only_path: true) : nil
        },
        reason: reason
      }.to_json
    end
  end
end
