class ProfileAssistantStreamJob < ApplicationJob
  queue_as :llm

  # Retry strategy configuration
  retry_on Net::ReadTimeout, wait: 5.seconds, attempts: 3
  retry_on LlmService::TimeoutError, wait: 5.seconds, attempts: 3
  retry_on LlmService::ApiError, wait: 10.seconds, attempts: 2

  def perform(chat_session_id:, prompt:)
    chat_session = ChatSession.find(chat_session_id)
    profile = chat_session.profile
    channel_name = "profile_chat_#{chat_session_id}"
    full_content = ""

    # 获取系统提示词和工具
    service = ProfileAssistantService.new(profile, prompt, chat_session)
    result = service.call
    
    unless result[:success]
      broadcast_error(channel_name, result[:error])
      return
    end

    system_prompt = result[:system_prompt]
    tools = result[:tools]

    # 构建工具处理器
    tool_handler = ->(tool_name, args) do
      Rails.logger.info("Tool called: #{tool_name} with args: #{args}")
      
      # 广播工具调用
      ActionCable.server.broadcast(channel_name, {
        type: 'tool-call',
        tool_name: tool_name,
        arguments: args
      })

      # 执行工具
      result = ProfileAssistantService.handle_tool_call(tool_name, args, profile)
      
      # 如果是推荐团队成员，广播名片信息
      if tool_name == 'recommend_team_member'
        result_data = JSON.parse(result)
        if result_data['success']
          ActionCable.server.broadcast(channel_name, {
            type: 'member-card',
            profile: result_data['profile'],
            reason: result_data['reason']
          })
        end
      end

      result
    end

    # 构建对话历史（最近10条消息）
    previous_messages = chat_session.chat_messages.recent.limit(10).map do |msg|
      { role: msg.role, content: msg.content }
    end

    # 流式调用 LLM（传入历史消息）
    begin
      LlmService.call_stream(
        prompt: prompt,
        system: system_prompt,
        history: previous_messages,
        tools: tools,
        tool_handler: tool_handler,
        temperature: 0.7,
        max_tokens: 2000
      ) do |chunk|
        full_content += chunk
        ActionCable.server.broadcast(channel_name, {
          type: 'assistant-chunk',
          chunk: chunk
        })
      end

      # 保存助手消息
      assistant_message = chat_session.chat_messages.create!(
        role: 'assistant',
        content: full_content
      )

      # 广播完成
      ActionCable.server.broadcast(channel_name, {
        type: 'assistant-done',
        id: assistant_message.id,
        content: full_content,
        created_at: assistant_message.created_at.iso8601
      })
    rescue StandardError => e
      Rails.logger.error("ProfileAssistantStreamJob error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      broadcast_error(channel_name, '抱歉,我遇到了一些问题,请稍后再试。')
    end
  end

  private

  def broadcast_error(channel_name, message)
    ActionCable.server.broadcast(channel_name, {
      type: 'error',
      message: message
    })
  end
end
