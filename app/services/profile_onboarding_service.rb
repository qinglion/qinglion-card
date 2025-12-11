class ProfileOnboardingService < ApplicationService
  ONBOARDING_STEPS = {
    'intro' => {
      prompt: '你好！很高兴认识你 😊 可以简单介绍一下你自己吗？比如你的名字、职业等等。',
      system: '你是一个友好、专业的引导助手。用户刚开始创建自己的专业名片。请以轻松、亲切的语气引导用户介绍自己。当用户提供了基本信息后，提取姓名、职位、公司等关键信息。',
      next_step: 'specializations',
      field_mapping: ['full_name', 'title', 'company']
    },
    'specializations' => {
      prompt: '很棒！那你最擅长解决哪类问题呢？或者你的专业领域是什么？',
      system: '引导用户描述自己的专业领域和擅长方向。用户可能会描述多个领域，请帮助提取出3-5个关键专业领域。',
      next_step: 'case_story',
      field_mapping: ['specializations', 'bio']
    },
    'case_story' => {
      prompt: '有没有什么让你印象特别深刻的客户故事或成功案例？可以分享一下吗？',
      system: '引导用户分享一个具体的成功案例或客户故事。帮助用户提炼案例的标题、类型和简短描述。如果用户分享了多个故事，选择最精彩的一个。',
      next_step: 'brand_style',
      field_mapping: ['case_studies']
    },
    'brand_style' => {
      prompt: '最后一个问题，你希望客户怎么记住你？或者说，你想传达什么样的专业形象和服务风格？',
      system: '引导用户描述自己的品牌理念或服务风格。帮助用户提炼出独特的个人品牌特点，可以融入到个人简介中。',
      next_step: 'contact_preferences',
      field_mapping: ['bio']
    },
    'contact_preferences' => {
      prompt: '太好了！最后请告诉我你的联系方式和方便的联系时间，这样潜在客户就能更容易联系到你。',
      system: '收集用户的联系方式（电话、邮箱、地址）和可预约时间。确保至少获得一种联系方式。',
      next_step: 'avatar_upload',
      field_mapping: ['phone', 'email', 'location']
    },
    'avatar_upload' => {
      prompt: '完美！现在让我们给你的名片添加一张专业照片吧 📸 选一张你最满意的照片上传即可。',
      system: '引导用户上传头像照片。如果用户表示现在没有合适的照片，可以跳过这一步，之后再上传。',
      next_step: 'completed',
      field_mapping: ['avatar']
    }
  }.freeze

  def initialize(profile, message_content, current_step = nil)
    @profile = profile
    @message_content = message_content
    @current_step = current_step || @profile.onboarding_step || 'intro'
    # LlmService will be initialized when needed
  end

  def call
    step_config = ONBOARDING_STEPS[@current_step]
    return error_response('Invalid step') unless step_config

    # If message is empty, return initial prompt
    if @message_content.blank?
      return {
        success: true,
        response: step_config[:prompt],
        step: @current_step,
        next_step: step_config[:next_step],
        is_initial: true
      }
    end

    # Process user message with AI
    ai_response = process_with_ai(step_config)
    
    # Extract and save profile data
    extracted_data = extract_profile_data(ai_response, step_config)
    save_profile_data(extracted_data)
    
    # Store conversation data
    store_onboarding_data(@message_content, ai_response)

    # Move to next step
    next_step = step_config[:next_step]
    @profile.update(onboarding_step: next_step)

    # Check if onboarding is completed
    if next_step == 'completed'
      @profile.complete_onboarding!
      return {
        success: true,
        response: generate_completion_message,
        step: @current_step,
        next_step: next_step,
        completed: true,
        profile_preview: generate_profile_preview
      }
    end

    # Return AI response with next step prompt
    next_step_config = ONBOARDING_STEPS[next_step]
    {
      success: true,
      response: "#{ai_response}\n\n#{next_step_config[:prompt]}",
      step: @current_step,
      next_step: next_step,
      profile_preview: generate_profile_preview
    }
  end

  private

  def process_with_ai(step_config)
    prompt = @message_content
    system = step_config[:system]

    response = @llm_service.call(
      prompt: prompt,
      system: system,
      temperature: 0.7
    )

    response[:content] || '感谢分享！让我们继续下一步。'
  rescue StandardError => e
    Rails.logger.error("ProfileOnboardingService AI error: #{e.message}")
    '感谢分享！让我们继续下一步。'
  end

  def extract_profile_data(ai_response, step_config)
    # Use AI to extract structured data from conversation
    extraction_prompt = <<~PROMPT
      Based on the user's message: "#{@message_content}"
      Extract the following information and return as JSON:
      #{step_config[:field_mapping].map { |field| "- #{field}" }.join("\n")}
      
      Return only valid JSON, no other text.
      Example format: {"full_name": "张三", "title": "资深律师"}
    PROMPT

    result = @llm_service.call(
      prompt: extraction_prompt,
      system: 'You are a data extraction assistant. Extract structured data from user messages.',
      temperature: 0.3
    )

    JSON.parse(result[:content]) rescue {}
  rescue StandardError => e
    Rails.logger.error("ProfileOnboardingService extraction error: #{e.message}")
    {}
  end

  def save_profile_data(data)
    return if data.blank?

    # Handle specializations specially (array field)
    if data['specializations'].is_a?(String)
      specializations = data['specializations'].split(/[,，、]/).map(&:strip).reject(&:blank?)
      data['specializations'] = specializations
    end

    # Handle case studies
    if data['case_studies'].present?
      case_study_data = data.delete('case_studies')
      if case_study_data.is_a?(Hash)
        @profile.case_studies.create(
          title: case_study_data['title'] || '成功案例',
          description: case_study_data['description'],
          category: case_study_data['category']
        )
      end
    end

    # Update profile with extracted data
    @profile.update(data.slice('full_name', 'title', 'company', 'phone', 'email', 'location', 'bio', 'specializations'))
  rescue StandardError => e
    Rails.logger.error("ProfileOnboardingService save error: #{e.message}")
  end

  def store_onboarding_data(user_message, ai_response)
    current_data = @profile.onboarding_data || {}
    current_data[@current_step] = {
      'user_message' => user_message,
      'ai_response' => ai_response,
      'timestamp' => Time.current.iso8601
    }
    @profile.update(onboarding_data: current_data)
  end

  def generate_completion_message
    <<~MESSAGE
      🎉 太棒了！你的专业名片已经创建完成！

      我已经根据你提供的信息生成了一张精美的专业名片。你可以：
      1. 在右侧预览你的名片效果
      2. 随时通过仪表盘的AI助手来更新名片信息
      3. 分享名片链接给潜在客户

      现在就去查看你的名片吧！✨
    MESSAGE
  end

  def generate_profile_preview
    {
      full_name: @profile.full_name,
      title: @profile.title,
      company: @profile.company,
      phone: @profile.phone,
      email: @profile.email,
      location: @profile.location,
      bio: @profile.bio,
      specializations: @profile.specializations_array,
      avatar_url: @profile.avatar.attached? ? Rails.application.routes.url_helpers.url_for(@profile.avatar) : nil
    }
  rescue StandardError
    {}
  end

  def error_response(message)
    {
      success: false,
      error: message,
      step: @current_step
    }
  end
end
