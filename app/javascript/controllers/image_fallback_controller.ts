import { Controller } from "@hotwired/stimulus"

/**
 * ImageFallback Controller - 处理图片加载失败的情况
 * 
 * 功能：
 * 1. 图片加载失败时自动重试（添加时间戳防止缓存）
 * 2. 多次重试失败后显示占位符
 * 3. 防止浏览器缓存失败的图片
 * 
 * 使用方法：
 * <img src="..." 
 *      data-controller="image-fallback"
 *      data-image-fallback-max-retries-value="3"
 *      data-image-fallback-retry-delay-value="1000"
 *      data-image-fallback-fallback-text-value="图片加载失败">
 */
export default class extends Controller<HTMLImageElement> {
  static values = {
    maxRetries: { type: Number, default: 3 },      // 最大重试次数
    retryDelay: { type: Number, default: 1000 },   // 重试延迟（毫秒）
    fallbackText: { type: String, default: "图片加载失败" }  // 占位文字
  }

  declare readonly maxRetriesValue: number
  declare readonly retryDelayValue: number
  declare readonly fallbackTextValue: string
  
  private retryCount: number = 0
  private originalSrc: string = ""
  private retryTimer?: number

  connect(): void {
    // 保存原始图片URL（去掉可能存在的时间戳参数）
    this.originalSrc = this.element.src.split('?')[0]
    
    // 监听图片加载错误
    this.element.addEventListener('error', this.handleError.bind(this))
    
    // 监听图片加载成功（用于重置重试计数）
    this.element.addEventListener('load', this.handleLoad.bind(this))
  }

  disconnect(): void {
    if (this.retryTimer) {
      clearTimeout(this.retryTimer)
    }
    this.element.removeEventListener('error', this.handleError.bind(this))
    this.element.removeEventListener('load', this.handleLoad.bind(this))
  }

  private handleLoad(): void {
    // 图片加载成功，重置重试计数
    this.retryCount = 0
    
    // 移除失败标记
    this.element.classList.remove('image-load-failed')
    
    // 恢复原始样式
    if (this.element.dataset.originalClass) {
      this.element.className = this.element.dataset.originalClass
      delete this.element.dataset.originalClass
    }
  }

  private handleError(event: Event): void {
    event.preventDefault()
    
    console.warn(`图片加载失败: ${this.originalSrc}, 重试次数: ${this.retryCount}/${this.maxRetriesValue}`)
    
    // 如果还有重试机会
    if (this.retryCount < this.maxRetriesValue) {
      this.retryCount++
      
      // 延迟后重试（添加时间戳防止缓存）
      this.retryTimer = window.setTimeout(() => {
        this.retryLoadImage()
      }, this.retryDelayValue * this.retryCount) // 递增延迟时间
    } else {
      // 达到最大重试次数，显示占位符
      this.showFallback()
    }
  }

  private retryLoadImage(): void {
    // 添加时间戳参数防止浏览器缓存失败的图片
    const timestamp = new Date().getTime()
    const separator = this.originalSrc.includes('?') ? '&' : '?'
    const newSrc = `${this.originalSrc}${separator}retry=${timestamp}`
    
    console.log(`重试加载图片 (${this.retryCount}/${this.maxRetriesValue}): ${newSrc}`)
    
    // 重新设置图片源
    this.element.src = newSrc
  }

  private showFallback(): void {
    console.error(`图片加载彻底失败: ${this.originalSrc}`)
    
    // 保存原始类名
    if (!this.element.dataset.originalClass) {
      this.element.dataset.originalClass = this.element.className
    }
    
    // 添加失败标记类
    this.element.classList.add('image-load-failed')
    
    // 创建占位符容器（如果父元素支持的话）
    const parent = this.element.parentElement
    if (parent && !parent.querySelector('.image-fallback-placeholder')) {
      this.createFallbackPlaceholder(parent)
    }
  }

  private createFallbackPlaceholder(parent: HTMLElement): void {
    // 隐藏失败的图片
    this.element.style.display = 'none'
    
    // 创建占位符
    const placeholder = document.createElement('div')
    placeholder.className = 'image-fallback-placeholder flex items-center justify-center bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400 text-center p-4'
    placeholder.style.width = '100%'
    placeholder.style.height = '100%'
    placeholder.style.minHeight = '200px'
    
    placeholder.innerHTML = `
      <div class="text-center">
        <svg class="w-12 h-12 mx-auto mb-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
        </svg>
        <p class="text-sm">${this.fallbackTextValue}</p>
        <button class="mt-2 text-xs text-primary hover:underline" data-action="click->image-fallback#retry">
          点击重试
        </button>
      </div>
    `
    
    parent.appendChild(placeholder)
  }

  // 手动重试方法（供按钮调用）
  retry(): void {
    console.log('手动重试加载图片')
    
    // 重置重试计数
    this.retryCount = 0
    
    // 移除占位符
    const placeholder = this.element.parentElement?.querySelector('.image-fallback-placeholder')
    if (placeholder) {
      placeholder.remove()
    }
    
    // 显示图片元素
    this.element.style.display = ''
    
    // 重新加载图片（带时间戳）
    this.retryLoadImage()
  }
}
