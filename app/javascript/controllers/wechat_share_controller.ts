import { Controller } from "@hotwired/stimulus"

declare const wx: any

/**
 * WechatShare Controller - Handles WeChat JS-SDK share functionality
 */
export default class extends Controller<HTMLElement> {
  static values = {
    title: String,
    desc: String,
    link: String,
    imgUrl: String
  }

  declare readonly titleValue: string
  declare readonly descValue: string
  declare readonly linkValue: string
  declare readonly imgUrlValue: string

  connect(): void {
    console.log("WechatShare controller connected")
    this.initWechatShare()
  }

  private async initWechatShare(): Promise<void> {
    // Check if WeChat JS-SDK is loaded
    if (typeof wx === 'undefined') {
      console.log('WeChat JS-SDK not loaded, loading now...')
      await this.loadWechatScript()
    }

    // Get current URL (without fragment)
    const url = window.location.href.split('#')[0]

    try {
      // Get signature from internal API
      const response = await fetch('/wechat_signatures', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken()
        },
        body: JSON.stringify({ url: url })
      })

      const result = await response.json()

      if (result.success && result.data) {
        this.configWechat(result.data)
      } else {
        console.error('Failed to get WeChat signature:', result.error)
      }
    } catch (error) {
      console.error('Error initializing WeChat share:', error)
    }
  }

  private loadWechatScript(): Promise<void> {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = '//res2.wx.qq.com/open/js/jweixin-1.6.0.js'
      script.onload = () => resolve()
      script.onerror = () => reject(new Error('Failed to load WeChat JS-SDK'))
      document.head.appendChild(script)
    })
  }

  private configWechat(config: any): void {
    wx.config({
      debug: false, // Use vConsole for debugging instead
      appId: config.appId,
      timestamp: config.timestamp,
      nonceStr: config.nonceStr,
      signature: config.signature,
      jsApiList: [
        'updateAppMessageShareData',
        'updateTimelineShareData',
        'onMenuShareTimeline',
        'onMenuShareAppMessage'
      ]
    })

    wx.ready(() => {
      console.log('WeChat JS-SDK ready')
      this.setupShareConfig()
    })

    wx.error((res: any) => {
      console.error('WeChat JS-SDK error:', res)
    })
  }

  private setupShareConfig(): void {
    const shareData = {
      title: this.titleValue || document.title,
      desc: this.descValue || '专业名片分享',
      link: this.linkValue || window.location.href,
      imgUrl: this.imgUrlValue || this.getDefaultImage()
    }

    // New API (1.4.0+)
    wx.updateAppMessageShareData({
      title: shareData.title,
      desc: shareData.desc,
      link: shareData.link,
      imgUrl: shareData.imgUrl,
      success: () => {
        console.log('Share to chat configured')
      }
    })

    wx.updateTimelineShareData({
      title: shareData.title,
      link: shareData.link,
      imgUrl: shareData.imgUrl,
      success: () => {
        console.log('Share to timeline configured')
      }
    })

    // Old API (for compatibility with older WeChat versions)
    wx.onMenuShareAppMessage({
      title: shareData.title,
      desc: shareData.desc,
      link: shareData.link,
      imgUrl: shareData.imgUrl,
      success: () => {
        console.log('User shared to chat')
      }
    })

    wx.onMenuShareTimeline({
      title: shareData.title,
      link: shareData.link,
      imgUrl: shareData.imgUrl,
      success: () => {
        console.log('User shared to timeline')
      }
    })
  }

  private getDefaultImage(): string {
    // Try to get og:image or first image on page
    const ogImage = document.querySelector('meta[property="og:image"]')
    if (ogImage) {
      return ogImage.getAttribute('content') || ''
    }

    const firstImg = document.querySelector('img')
    if (firstImg && firstImg.src) {
      return firstImg.src
    }

    return ''
  }

  private getCsrfToken(): string {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') || '' : ''
  }
}
