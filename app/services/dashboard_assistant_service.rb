class DashboardAssistantService < ApplicationService
  def initialize(profile, user_message)
    @profile = profile
    @user_message = user_message
  end

  def call
    # Build system prompt with profile context and MCP tools
    system_prompt = build_system_prompt
    
    # Process with AI - include function calling for profile updates
    response = LlmService.call_blocking(
      prompt: @user_message,
      system: system_prompt,
      temperature: 0.7
    )

    # Check if AI wants to update profile
    if response.include?('[UPDATE_PROFILE]')
      extracted_updates = extract_profile_updates(response)
      apply_profile_updates(extracted_updates)
      
      return {
        success: true,
        response: "好的，我已经帮你更新了名片信息！✨\n\n#{format_update_summary(extracted_updates)}",
        updated: true,
        updated_fields: extracted_updates.keys
      }
    end

    {
      success: true,
      response: response || '我收到你的消息了！还有什么可以帮到你的吗？',
      updated: false
    }
  rescue StandardError => e
    Rails.logger.error("DashboardAssistantService error: #{e.message}")
    {
      success: false,
      error: '处理消息时出现错误，请重试。'
    }
  end

  private

  def build_system_prompt
    <<~SYSTEM
      你是用户专业名片的AI助手。用户可以通过对话的方式让你帮助更新名片信息。

      当前名片信息：
      - 姓名: #{@profile.full_name}
      - 职位: #{@profile.title}
      - 公司: #{@profile.company || '未设置'}
      - 电话: #{@profile.phone || '未设置'}
      - 邮箱: #{@profile.email || '未设置'}
      - 地址: #{@profile.location || '未设置'}
      - 简介: #{@profile.bio || '未设置'}
      - 专业领域: #{@profile.specializations_array.join(', ') || '未设置'}

      可更新的字段和格式：
      1. full_name - 姓名（文本）
      2. title - 职位/职称（文本）
      3. company - 公司/机构（文本）
      4. phone - 电话号码（文本）
      5. email - 邮箱地址（邮箱格式）
      6. location - 地址/城市（文本）
      7. bio - 个人简介（长文本）
      8. specializations - 专业领域（数组，用逗号分隔）
      9. stats.years_experience - 执业年限（数字）
      10. stats.cases_handled - 成功案例数（数字）
      11. stats.clients_served - 服务客户数（数字）
      12. stats.success_rate - 成功率百分比（数字）

      ## 工作流程：
      1. 理解用户想要更新的信息
      2. 从用户消息中提取要更新的字段和新值
      3. 如果需要更新，在回复中包含 [UPDATE_PROFILE] 标记，然后用JSON格式列出要更新的字段：
         ```json
         {"full_name": "新名字", "title": "新职位"}
         ```
      4. 如果用户只是询问或聊天，正常回复即可，不需要 [UPDATE_PROFILE] 标记

      ## 示例对话：
      用户："帮我把电话改成 138-1234-5678"
      你："[UPDATE_PROFILE]\n```json\n{\"phone\": \"138-1234-5678\"}\n```"

      用户："我的简介想改成：资深律师，专注于民商事诉讼，拥有15年执业经验"
      你："[UPDATE_PROFILE]\n```json\n{\"bio\": \"资深律师，专注于民商事诉讼，拥有15年执业经验\", \"stats\": {\"years_experience\": 15}}\n```"

      用户："名片看起来怎么样？"
      你："您的名片信息很完整！姓名、职位、联系方式都齐全了。不过我注意到您的个人简介还比较简单，要不要补充一下您的专业背景和优势？"

      保持友好、专业的语气，积极帮助用户完善名片信息。
    SYSTEM
  end

  def extract_profile_updates(ai_response)
    # Extract JSON from the response
    json_match = ai_response.match(/```json\n(.*?)\n```/m)
    return {} unless json_match

    updates = JSON.parse(json_match[1])
    
    # Validate and clean updates
    valid_fields = %w[full_name title company phone email location bio specializations]
    cleaned_updates = {}

    updates.each do |key, value|
      if key == 'stats' && value.is_a?(Hash)
        cleaned_updates['stats'] = value
      elsif valid_fields.include?(key)
        cleaned_updates[key] = value
      elsif key == 'specializations' && value.is_a?(String)
        cleaned_updates['specializations'] = value.split(/[,，、]/).map(&:strip).reject(&:blank?)
      end
    end

    cleaned_updates
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse profile updates: #{e.message}")
    {}
  end

  def apply_profile_updates(updates)
    return if updates.blank?

    # Handle stats separately
    if updates['stats'].present?
      current_stats = @profile.stats || {}
      updated_stats = current_stats.merge(updates['stats'].transform_keys(&:to_s))
      updates['stats'] = updated_stats
    end

    # Update profile
    @profile.update(updates)
  rescue StandardError => e
    Rails.logger.error("Failed to apply profile updates: #{e.message}")
  end

  def format_update_summary(updates)
    field_names = {
      'full_name' => '姓名',
      'title' => '职位',
      'company' => '公司',
      'phone' => '电话',
      'email' => '邮箱',
      'location' => '地址',
      'bio' => '个人简介',
      'specializations' => '专业领域',
      'stats' => '专业数据'
    }

    summary = updates.keys.map do |key|
      "• #{field_names[key] || key}"
    end.join("\n")

    "已更新以下信息：\n#{summary}"
  end
end
