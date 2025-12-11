class ProfileChatChannel < ApplicationCable::Channel
  def subscribed
    @profile = Profile.find(params[:profile_id])
    @chat_session = find_or_create_chat_session
    stream_from "profile_chat_#{@chat_session.id}"
  rescue StandardError => e
    handle_channel_error(e)
    reject
  end

  def unsubscribed
    @chat_session&.update(ended_at: Time.current) if @chat_session&.active?
  rescue StandardError => e
    handle_channel_error(e)
  end

  def send_message(data)
    return unless data['content'].present?

    # Save user message
    user_message = @chat_session.chat_messages.create!(
      role: 'user',
      content: data['content']
    )

    # Broadcast user message immediately
    ActionCable.server.broadcast(
      "profile_chat_#{@chat_session.id}",
      {
        type: 'user-message',
        id: user_message.id,
        content: user_message.content,
        created_at: user_message.created_at.iso8601
      }
    )

    # Start AI response with MCP tools via background job
    ProfileAssistantStreamJob.perform_later(
      chat_session_id: @chat_session.id,
      prompt: data['content']
    )
  end

  private

  def find_or_create_chat_session
    # Always create new session for each connection to avoid multiple tabs sharing same session
    visitor_name = params[:visitor_name].presence || 'Anonymous'
    visitor_email = params[:visitor_email]

    @profile.chat_sessions.create!(
      visitor_name: visitor_name,
      visitor_email: visitor_email,
      started_at: Time.current
    )
  end

  def current_user
    @current_user ||= connection.current_user
  end
end
