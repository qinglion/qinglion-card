# Extracts professional specialization keywords from profile content using AI
# Triggered automatically when profile is updated
class ExtractProfileSpecializationsJob < ApplicationJob
  queue_as :default

  # Retry strategy
  retry_on LlmService::TimeoutError, wait: 5.seconds, attempts: 2
  retry_on LlmService::ApiError, wait: 10.seconds, attempts: 2

  def perform(profile_id)
    profile = Profile.find(profile_id)
    
    # Build context from profile content
    context = build_profile_context(profile)
    
    # Skip if no meaningful content
    return if context.strip.length < 20
    
    # Call LLM to extract specializations
    prompt = <<~PROMPT
      分析以下专业人士的信息，提取3-5个最核心的专业领域关键词。

      要求：
      1. 关键词要简洁（2-6个字）
      2. 关键词要具体可搜索
      3. 关键词要反映核心业务
      4. 只返回关键词数组，格式：["关键词1", "关键词2", "关键词3"]
      5. 不要返回其他任何文字说明

      专业人士信息：
      #{context}

      请直接返回JSON数组格式的关键词，例如：["旅游规划", "定制旅行", "文化体验"]
    PROMPT

    system_prompt = "你是专业领域分析专家，擅长从文本中提取关键业务领域。"
    
    # Call LLM without streaming
    # Use gpt-4o-mini explicitly since qwen-max is not available on proxy
    result = LlmService.call(
      prompt: prompt,
      system: system_prompt,
      temperature: 0.3,
      max_tokens: 200,
      model: 'gpt-4o-mini'
    )
    
    # Parse result (expecting JSON array)
    specializations = parse_specializations(result)
    
    # Update profile if valid
    if specializations.present? && specializations.length.between?(2, 6)
      profile.update!(specializations: specializations)
      Rails.logger.info("Updated specializations for Profile ##{profile.id}: #{specializations.inspect}")
    end
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse specializations for Profile ##{profile.id}: #{e.message}")
  rescue StandardError => e
    Rails.logger.error("ExtractProfileSpecializationsJob failed for Profile ##{profile.id}: #{e.message}")
    raise # Re-raise to trigger retry
  end

  private

  def build_profile_context(profile)
    parts = []
    
    parts << "职位：#{profile.title}" if profile.title.present?
    parts << "公司：#{profile.company}" if profile.company.present?
    parts << "部门：#{profile.department}" if profile.department.present?
    
    if profile.bio.present?
      # Truncate bio to avoid token limits
      parts << "简介：#{profile.bio.truncate(500)}"
    end
    
    # Add service advantages
    [1, 2, 3].each do |i|
      title = profile.send("service_advantage_#{i}_title")
      desc = profile.send("service_advantage_#{i}_description")
      if title.present? || desc.present?
        parts << "服务优势：#{title} - #{desc}".truncate(100)
      end
    end
    
    # Add CTA description if meaningful
    if profile.cta_description.present?
      parts << "服务描述：#{profile.cta_description.truncate(100)}"
    end
    
    parts.join("\n")
  end

  def parse_specializations(result)
    # Remove markdown code blocks if present
    cleaned = result.strip.gsub(/```json\n?/, '').gsub(/```\n?/, '')
    
    # Try to parse as JSON
    parsed = JSON.parse(cleaned)
    
    # Ensure it's an array of strings
    if parsed.is_a?(Array)
      parsed.map(&:to_s).map(&:strip).reject(&:blank?).uniq.first(5)
    else
      []
    end
  end
end
