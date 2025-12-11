import BaseChannelController from "./base_channel_controller"
import { marked } from 'marked'

/**
 * ProfileChat Controller - Handles WebSocket + UI for profile chat
 */
export default class extends BaseChannelController {
  static targets = [
    "messages",
    "input",
    "form",
    "sendButton"
  ]

  static values = {
    profileId: Number,
    visitorName: String,
    visitorEmail: String
  }

  declare messagesTarget: HTMLElement
  declare inputTarget: HTMLInputElement
  declare formTarget: HTMLFormElement
  declare sendButtonTarget: HTMLButtonElement
  declare profileIdValue: number
  declare visitorNameValue: string
  declare visitorEmailValue: string

  private currentAssistantBubble: HTMLElement | null = null
  private currentAssistantContent = ""

  connect(): void {
    console.log("ProfileChat controller connected")

    this.createSubscription("ProfileChatChannel", {
      profile_id: this.profileIdValue,
      visitor_name: this.visitorNameValue,
      visitor_email: this.visitorEmailValue
    })

    // Enable form after connection
    this.formTarget.addEventListener('submit', this.handleSubmit.bind(this))
  }

  disconnect(): void {
    this.destroySubscription()
  }

  protected channelConnected(): void {
    console.log("Chat channel connected")
    this.enableInput()
  }

  protected channelDisconnected(): void {
    console.log("Chat channel disconnected")
    this.disableInput()
  }

  // Handle user message from server (confirmation)
  protected handleUserMessage(data: any): void {
    // User message already added locally, just scroll
    this.scrollToBottom()
  }

  // Handle AI assistant streaming chunks
  protected handleAssistantChunk(data: any): void {
    if (!this.currentAssistantBubble) {
      this.currentAssistantBubble = this.createAssistantBubble()
      this.messagesTarget.appendChild(this.currentAssistantBubble)
    }

    this.currentAssistantContent += data.chunk
    const contentElement = this.currentAssistantBubble.querySelector('.message-content')
    if (contentElement) {
      // Render markdown to HTML
      contentElement.innerHTML = marked.parse(this.currentAssistantContent) as string
    }

    this.scrollToBottom()
  }

  // Handle AI assistant completion
  protected handleAssistantDone(data: any): void {
    this.currentAssistantBubble = null
    this.currentAssistantContent = ""
    this.enableInput()
    this.scrollToBottom()
  }

  // Handle tool call indicator
  protected handleToolCall(data: any): void {
    const toolName = data.tool_name
    const toolIndicator = this.createToolIndicator(toolName)
    this.messagesTarget.appendChild(toolIndicator)
    this.scrollToBottom()

    // Remove indicator after 2 seconds
    setTimeout(() => {
      toolIndicator.remove()
    }, 2000)
  }

  // Handle team member card recommendation
  protected handleMemberCard(data: any): void {
    const profile = data.profile
    const reason = data.reason
    const cardElement = this.createMemberCard(profile, reason)
    this.messagesTarget.appendChild(cardElement)
    this.scrollToBottom()
  }

  // Handle error messages
  protected handleError(data: any): void {
    const errorMessage = data.message || '出现错误，请稍后再试'
    const errorEl = document.createElement('div')
    errorEl.className = 'chat-message'
    errorEl.innerHTML = `
      <div class="avatar avatar-sm flex-shrink-0">
        <div class="w-full h-full bg-red-100 flex items-center justify-center">
          <svg class="w-5 h-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        </div>
      </div>
      <div class="chat-bubble chat-bubble-assistant bg-red-50 text-red-800">
        <p class="text-sm">${this.escapeHtml(errorMessage)}</p>
      </div>
    `
    this.messagesTarget.appendChild(errorEl)
    this.scrollToBottom()
    this.enableInput()
  }

  // UI Methods
  private handleSubmit(event: Event): void {
    event.preventDefault()
    
    const content = this.inputTarget.value.trim()
    if (!content) return

    // Add user message to UI immediately
    this.addUserMessage(content)

    // Send to server via WebSocket
    this.perform('send_message', { content: content })

    // Clear input and disable while waiting
    this.inputTarget.value = ''
    this.disableInput()
    this.scrollToBottom()
  }

  private addUserMessage(content: string): void {
    const messageEl = document.createElement('div')
    messageEl.className = 'chat-message chat-message-user'
    messageEl.innerHTML = `
      <div class="chat-bubble chat-bubble-user">
        <p class="text-sm">${this.escapeHtml(content)}</p>
      </div>
    `
    this.messagesTarget.appendChild(messageEl)
  }

  private createAssistantBubble(): HTMLElement {
    const messageEl = document.createElement('div')
    messageEl.className = 'chat-message'
    messageEl.innerHTML = `
      <div class="avatar avatar-sm flex-shrink-0">
        <div class="w-full h-full bg-primary/10 flex items-center justify-center">
          <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"/>
          </svg>
        </div>
      </div>
      <div class="chat-bubble chat-bubble-assistant">
        <div class="text-sm message-content prose prose-sm max-w-none"></div>
      </div>
    `
    return messageEl
  }

  private enableInput(): void {
    this.inputTarget.disabled = false
    this.sendButtonTarget.disabled = false
  }

  private disableInput(): void {
    this.inputTarget.disabled = true
    this.sendButtonTarget.disabled = true
  }

  private scrollToBottom(): void {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  private escapeHtml(text: string): string {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  private createToolIndicator(toolName: string): HTMLElement {
    const toolNames: Record<string, string> = {
      'get_profile_info': '正在查询个人信息...',
      'get_team_members': '正在查询团队成员...',
      'recommend_team_member': '正在推荐团队成员...'
    }

    const indicatorEl = document.createElement('div')
    indicatorEl.className = 'tool-indicator'
    indicatorEl.innerHTML = `
      <svg class="w-4 h-4 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
      </svg>
      <span>${toolNames[toolName] || '正在处理...'}</span>
    `
    return indicatorEl
  }

  private createMemberCard(profile: any, reason: string): HTMLElement {
    const cardEl = document.createElement('div')
    cardEl.className = 'member-card'
    
    const avatarHtml = profile.avatar_url 
      ? `<img src="${profile.avatar_url}" class="w-12 h-12 rounded-full object-cover" alt="${profile.full_name}">` 
      : `<div class="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
           <span class="text-primary font-semibold text-lg">${profile.full_name[0]}</span>
         </div>`

    const specializationsHtml = profile.specializations && profile.specializations.length > 0
      ? `<div class="flex flex-wrap gap-1 mt-2">
           ${profile.specializations.map((s: string) => 
    `<span class="badge badge-sm badge-primary">${s}</span>`
  ).join('')}
         </div>`
      : ''

    const statsHtml = profile.stats
      ? `<div class="flex gap-4 mt-3 text-xs text-on-surface-variant">
           ${profile.stats.years_experience ? `<div>执业 ${profile.stats.years_experience} 年</div>` : ''}
           ${profile.stats.cases_handled ? `<div>${profile.stats.cases_handled} 个案例</div>` : ''}
         </div>`
      : ''

    cardEl.innerHTML = `
      <div class="flex items-start gap-3">
        ${avatarHtml}
        <div class="flex-1">
          <div class="font-semibold text-on-surface">${this.escapeHtml(profile.full_name)}</div>
          <div class="text-sm text-on-surface-variant">${this.escapeHtml(profile.title)}</div>
          ${profile.department ? `<div class="text-xs text-on-surface-variant">${this.escapeHtml(profile.department)}</div>` : ''}
          ${specializationsHtml}
          ${statsHtml}
          ${reason ? `<div class="mt-2 text-sm text-on-surface"><strong>推荐理由：</strong>${this.escapeHtml(reason)}</div>` : ''}
        </div>
      </div>
      <a href="/c/${profile.slug}" 
         class="btn btn-outline btn-sm mt-3 w-full flex items-center justify-center gap-2"
         target="_blank">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
        </svg>
        查看详细信息
      </a>
    `
    
    return cardEl
  }
}
