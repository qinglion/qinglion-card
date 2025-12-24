import { Controller } from "@hotwired/stimulus"

/**
 * Push Notifications Controller
 *
 * Manages Web Push Notifications subscription and permission requests
 *
 * Usage:
 *   <div data-controller="push-notifications">
 *     <button
 *       data-action="click->push-notifications#subscribe"
 *       data-push-notifications-target="subscribeButton">
 *       启用通知
 *     </button>
 *     <button
 *       data-action="click->push-notifications#unsubscribe"
 *       data-push-notifications-target="unsubscribeButton"
 *       class="hidden">
 *       关闭通知
 *     </button>
 *     <div data-push-notifications-target="status"></div>
 *   </div>
 */
export default class extends Controller {
  declare readonly subscribeButtonTarget: HTMLButtonElement
  declare readonly unsubscribeButtonTarget: HTMLButtonElement
  declare readonly statusTarget: HTMLElement
  declare readonly hasSubscribeButtonTarget: boolean
  declare readonly hasUnsubscribeButtonTarget: boolean
  declare readonly hasStatusTarget: boolean

  async connect() {
    // Check if Push API is supported
    if (!('PushManager' in window)) {
      this.updateStatus('您的浏览器不支持推送通知', 'warning')
      return
    }

    // Check if service worker is registered
    if (!('serviceWorker' in navigator)) {
      this.updateStatus('您的浏览器不支持 Service Worker', 'warning')
      return
    }

    // Wait for service worker to be ready
    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()
      
      if (subscription) {
        this.updateButtonsForSubscribed()
        this.updateStatus('通知已启用', 'success')
      } else {
        this.updateButtonsForUnsubscribed()
      }
    } catch (error) {
      console.error('Error checking push subscription:', error)
    }
  }

  async subscribe() {
    try {
      // Request notification permission
      const permission = await Notification.requestPermission()
      
      if (permission !== 'granted') {
        this.updateStatus('需要通知权限才能启用推送通知', 'warning')
        return
      }

      // Get service worker registration
      const registration = await navigator.serviceWorker.ready

      // Subscribe to push notifications
      // Note: You'll need to generate VAPID keys for production
      // Run: npx web-push generate-vapid-keys
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(
          this.getPublicVapidKey()
        ) as BufferSource
      })

      // Send subscription to server
      await this.sendSubscriptionToServer(subscription)

      this.updateButtonsForSubscribed()
      this.updateStatus('通知已启用', 'success')
      
      // Trigger custom event
      this.dispatch('subscribed', { detail: { subscription } })
    } catch (error) {
      console.error('Error subscribing to push notifications:', error)
      this.updateStatus('订阅失败，请稍后重试', 'error')
    }
  }

  async unsubscribe() {
    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()

      if (subscription) {
        await subscription.unsubscribe()
        await this.removeSubscriptionFromServer(subscription)
        
        this.updateButtonsForUnsubscribed()
        this.updateStatus('通知已关闭', 'info')
        
        // Trigger custom event
        this.dispatch('unsubscribed')
      }
    } catch (error) {
      console.error('Error unsubscribing from push notifications:', error)
      this.updateStatus('取消订阅失败', 'error')
    }
  }

  private updateButtonsForSubscribed() {
    if (this.hasSubscribeButtonTarget) {
      this.subscribeButtonTarget.classList.add('hidden')
    }
    if (this.hasUnsubscribeButtonTarget) {
      this.unsubscribeButtonTarget.classList.remove('hidden')
    }
  }

  private updateButtonsForUnsubscribed() {
    if (this.hasSubscribeButtonTarget) {
      this.subscribeButtonTarget.classList.remove('hidden')
    }
    if (this.hasUnsubscribeButtonTarget) {
      this.unsubscribeButtonTarget.classList.add('hidden')
    }
  }

  private updateStatus(message: string, type: 'success' | 'warning' | 'error' | 'info' = 'info') {
    if (!this.hasStatusTarget) return

    const statusClasses = {
      success: 'text-success',
      warning: 'text-warning',
      error: 'text-danger',
      info: 'text-secondary'
    }

    this.statusTarget.textContent = message
    this.statusTarget.className = `text-sm ${statusClasses[type]}`
  }

  private async sendSubscriptionToServer(subscription: PushSubscription): Promise<void> {
    // Send subscription to your Rails backend
    // You'll need to create an API endpoint to receive this
    const response = await fetch('/api/v1/push_subscriptions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCsrfToken()
      },
      body: JSON.stringify({
        subscription: subscription.toJSON()
      })
    })

    if (!response.ok) {
      throw new Error('Failed to save subscription on server')
    }
  }

  private async removeSubscriptionFromServer(subscription: PushSubscription): Promise<void> {
    // Remove subscription from your Rails backend
    const response = await fetch('/api/v1/push_subscriptions', {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCsrfToken()
      },
      body: JSON.stringify({
        subscription: subscription.toJSON()
      })
    })

    if (!response.ok) {
      throw new Error('Failed to remove subscription from server')
    }
  }

  private getPublicVapidKey(): string {
    // In production, this should come from your Rails backend
    // For now, return a placeholder
    // Generate real keys with: npx web-push generate-vapid-keys
    return 'BEl62iUYgUivxIkv69yViEuiBIa-Ib37J8yazRrmtCQXW0T2N8qXJHJ6K9wlQXmqKnKxEJkJW4ghO8uEW3lR0rA'
  }

  private urlBase64ToUint8Array(base64String: string): Uint8Array {
    const padding = '='.repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding)
      .replace(/-/g, '+')
      .replace(/_/g, '/')

    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }

  private getCsrfToken(): string {
    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    return token || ''
  }

  static targets = ["subscribeButton", "unsubscribeButton", "status"]
}
