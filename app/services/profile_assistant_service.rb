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
      "所属组织：#{@profile.organization.name}，团队成员：#{@profile.organization.approved_profiles.count}人"
    else
      "暂无组织信息"
    end

    <<~PROMPT
      你是#{@profile.full_name}的智能名片助手，负责协助访客了解#{@profile.full_name}的专业背景和团队信息。

      # 核心定位
      你是引荐者，不是服务提供者或专业顾问。你的职责是介绍和推荐，不提供专业咨询或承诺服务。

      # 开场白示例
      "您好！我是#{@profile.full_name}的智能名片助手。我可以帮您了解#{@profile.full_name}的专业背景和团队信息，或为您推荐合适的专业人士。请问有什么可以帮到您？"

      # 基本信息
      - 姓名：#{@profile.full_name}
      - 职位：#{@profile.title}
      - 公司：#{@profile.company || '未设置'}
      - 部门：#{@profile.department || '未设置'}
      - #{organization_info}
      - 专业领域：#{@profile.specializations_array.join('、')}
      - 执业年限：#{@profile.stats&.dig('years_experience') || 0}年
      - 成功案例：#{@profile.stats&.dig('cases_handled') || 0}个

      # 工具使用
      - `get_profile_info`: 获取详细个人信息（案例、荣誉）
      - `get_team_members`: 查询团队成员（可按专业领域筛选）
      - `recommend_team_member`: 推荐团队成员（会展示名片）

      # 重要原则
      1. 称呼#{@profile.full_name}使用职位"#{@profile.title}"，不要推断职业
      2. 不直接回答专业问题，引导访客联系专业人士
      3. 不承诺服务能力，使用"擅长"、"有经验"等客观描述
      4. 不泄露私密联系方式，引导使用"联系 TA"按钮
      5. 遇到专业咨询，及时推荐合适的团队成员

      # 回答风格
      简洁友好，使用Markdown格式，主动了解需求，及时推荐人选。
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
                description: '筛选特定专业领域的成员，根据用户的专业领域来筛选'
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
      # 简化数据结构，只返回必要信息
      result = {
        status: 'success',
        data: {
          full_name: profile.full_name,
          title: profile.title,
          company: profile.company || '未设置',
          department: profile.department || '未设置',
          specializations: profile.specializations_array,
          years_experience: profile.stats&.dig('years_experience') || 0,
          cases_handled: profile.stats&.dig('cases_handled') || 0,
          bio: profile.bio&.truncate(200) || '暂无简介'
        }
      }

      # 只在明确请求时添加案例和荣誉
      if arguments['include_cases'] && profile.case_studies.any?
        result[:data][:case_studies] = profile.case_studies.limit(3).map do |cs|
          {
            title: cs.title,
            category: cs.category,
            description: cs.description&.truncate(100)
          }
        end
      end

      if arguments['include_honors'] && profile.honors.any?
        result[:data][:honors] = profile.honors.limit(3).map do |h|
          {
            title: h.title,
            organization: h.organization
          }
        end
      end

      result.to_json
    end

    def get_team_members(profile, arguments)
      unless profile.organization
        return { status: 'error', message: '该专业人士暂未加入任何组织' }.to_json
      end

      members = profile.organization.approved_profiles.where.not(id: profile.id)
      
      # 按专业领域筛选
      if arguments['specialization'].present?
        keyword = arguments['specialization']
        members = members.select do |m|
          m.specializations_array.any? { |s| s.include?(keyword) }
        end
      end

      limit = [arguments['limit'] || 5, 10].min  # 限制最多10个
      members = members.first(limit)

      result = {
        status: 'success',
        count: members.size,
        members: members.map do |member|
          {
            id: member.id,
            full_name: member.full_name,
            title: member.title,
            department: member.department || '未设置',
            specializations: member.specializations_array.first(3),  # 最多3个领域
            years_experience: member.stats&.dig('years_experience') || 0
          }
        end
      }

      result.to_json
    end

    def recommend_team_member(profile, arguments)
      profile_id = arguments['profile_id']
      reason = arguments['reason']

      recommended_profile = Profile.find_by(id: profile_id)
      
      unless recommended_profile
        return { status: 'error', message: '未找到该团队成员' }.to_json
      end

      # 验证是否是同一组织的成员
      unless recommended_profile.organization_id == profile.organization_id
        return { status: 'error', message: '该成员不在同一组织' }.to_json
      end

      {
        status: 'success',
        action: 'recommend_member',
        reason: reason,
        member: {
          id: recommended_profile.id,
          slug: recommended_profile.slug,
          full_name: recommended_profile.full_name,
          title: recommended_profile.title,
          department: recommended_profile.department || '未设置',
          specializations: recommended_profile.specializations_array.first(3),
          years_experience: recommended_profile.stats&.dig('years_experience') || 0,
          cases_handled: recommended_profile.stats&.dig('cases_handled') || 0,
          avatar_url: recommended_profile.avatar.attached? ? 
            Rails.application.routes.url_helpers.rails_blob_path(recommended_profile.avatar, only_path: true) : nil
        }
      }.to_json
    end
  end
end
