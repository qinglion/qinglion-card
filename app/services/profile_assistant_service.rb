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
    when 'get_team_count'
      get_team_count(profile, arguments)
    when 'get_team_members'
      get_team_members(profile, arguments)
    when 'search_team_members'
      search_team_members(profile, arguments)
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

      # 工具使用指南
      1. `get_profile_info`: 获取当前专业人士的详细信息（案例、荣誉）
      2. `get_team_count`: 获取团队总人数
         - 用户问"有多少人"、"团队规模" → 使用此工具
         - 可按专业领域统计：specialization="旅游"
      3. `get_team_members`: 获取团队成员列表（默认5人，最多10人）
         - 用户想看具体成员信息 → 使用此工具
         - 可按专业领域筛选：specialization="金融"
      4. `search_team_members`: 搜索团队成员
         - 用户指定搜索关键词（姓名/职位/专业/部门） → 使用此工具
         - 例如："有做旅游的吗" → keyword="旅游"
      5. `recommend_team_member`: 推荐团队成员（会展示名片）
         - 确定推荐人选后调用，展示可点击的名片

      # 重要原则
      1. 称呼#{@profile.full_name}使用职位"#{@profile.title}"，不要推断职业
      2. 不直接回答专业问题，引导访客联系专业人士
      3. 不承诺服务能力，使用"擅长"、"有经验"等客观描述
      4. 不泄露私密联系方式，引导使用"联系 TA"按钮
      5. 遇到专业咨询，及时推荐合适的团队成员
      6. 团队查询策略：
         - 简单统计：使用 get_team_count
         - 展示成员：使用 get_team_members
         - 关键词搜索：使用 search_team_members
         - 成员过多时，先显示前5-10人，提示可继续搜索

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
          name: 'get_team_count',
          description: '获取团队总人数和基本统计信息，不返回具体成员列表。当用户询问"有多少人"、"团队规模"等问题时使用。',
          parameters: {
            type: 'object',
            properties: {
              specialization: {
                type: 'string',
                description: '可选：按专业领域筛选统计，例如"律师"、"会计师"等'
              }
            }
          }
        }
      },
      {
        type: 'function',
        function: {
          name: 'get_team_members',
          description: '获取团队成员列表（返回前N名成员的详细信息）。用于展示具体成员信息。默认返回5人，最多10人。',
          parameters: {
            type: 'object',
            properties: {
              specialization: {
                type: 'string',
                description: '按专业领域筛选成员，例如"旅游"、"金融"、"法律"等关键词'
              },
              limit: {
                type: 'integer',
                description: '返回的成员数量，默认5人，最多10人'
              }
            }
          }
        }
      },
      {
        type: 'function',
        function: {
          name: 'search_team_members',
          description: '搜索团队成员。根据关键词（姓名、职位、专业领域、部门）搜索匹配的成员。',
          parameters: {
            type: 'object',
            properties: {
              keyword: {
                type: 'string',
                description: '搜索关键词，可以是姓名、职位、专业领域或部门'
              },
              limit: {
                type: 'integer',
                description: '返回的结果数量，默认5人'
              }
            },
            required: ['keyword']
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

    def get_team_count(profile, arguments)
      unless profile.organization
        return { status: 'error', message: '该专业人士暂未加入任何组织' }.to_json
      end

      members = profile.organization.approved_profiles.where.not(id: profile.id)
      total_count = members.count
      
      # 按专业领域筛选统计
      filtered_count = total_count
      specialization = nil
      if arguments['specialization'].present?
        keyword = arguments['specialization']
        specialization = keyword
        filtered_members = members.select do |m|
          m.specializations_array.any? { |s| s.downcase.include?(keyword.downcase) }
        end
        filtered_count = filtered_members.size
      end

      result = {
        status: 'success',
        total_count: total_count,
        organization_name: profile.organization.name
      }

      if specialization
        result[:filtered_count] = filtered_count
        result[:specialization] = specialization
        result[:message] = "#{profile.organization.name}共有#{total_count}名成员，其中#{specialization}相关的有#{filtered_count}人"
      else
        result[:message] = "#{profile.organization.name}共有#{total_count}名团队成员"
      end

      result.to_json
    end

    def get_team_members(profile, arguments)
      unless profile.organization
        return { status: 'error', message: '该专业人士暂未加入任何组织' }.to_json
      end

      members = profile.organization.approved_profiles.where.not(id: profile.id)
      total_count = members.count
      
      # 按专业领域筛选
      if arguments['specialization'].present?
        keyword = arguments['specialization']
        members = members.select do |m|
          m.specializations_array.any? { |s| s.downcase.include?(keyword.downcase) }
        end
      end

      limit = [arguments['limit'] || 5, 10].min
      displayed_members = members.first(limit)

      result = {
        status: 'success',
        total_count: total_count,
        displayed_count: displayed_members.size,
        has_more: members.size > limit,
        members: displayed_members.map do |member|
          {
            id: member.id,
            full_name: member.full_name,
            title: member.title,
            department: member.department || '未设置',
            specializations: member.specializations_array.first(3),
            years_experience: member.stats&.dig('years_experience') || 0
          }
        end
      }

      result.to_json
    end

    def search_team_members(profile, arguments)
      unless profile.organization
        return { status: 'error', message: '该专业人士暂未加入任何组织' }.to_json
      end

      keyword = arguments['keyword']
      unless keyword.present?
        return { status: 'error', message: '请提供搜索关键词' }.to_json
      end

      members = profile.organization.approved_profiles.where.not(id: profile.id)
      keyword_lower = keyword.downcase
      
      # 多字段搜索：姓名、职位、专业领域、部门
      matched_members = members.select do |m|
        m.full_name.downcase.include?(keyword_lower) ||
        m.title.to_s.downcase.include?(keyword_lower) ||
        m.department.to_s.downcase.include?(keyword_lower) ||
        m.specializations_array.any? { |s| s.downcase.include?(keyword_lower) }
      end

      limit = [arguments['limit'] || 5, 10].min
      displayed_members = matched_members.first(limit)

      result = {
        status: 'success',
        keyword: keyword,
        total_matches: matched_members.size,
        displayed_count: displayed_members.size,
        members: displayed_members.map do |member|
          {
            id: member.id,
            full_name: member.full_name,
            title: member.title,
            department: member.department || '未设置',
            specializations: member.specializations_array.first(3),
            years_experience: member.stats&.dig('years_experience') || 0
          }
        end
      }

      if matched_members.empty?
        result[:message] = "没有找到与\"#{keyword}\"相关的团队成员"
      elsif matched_members.size > limit
        result[:message] = "找到#{matched_members.size}个匹配结果，显示前#{limit}个"
      end

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
