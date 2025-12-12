import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["item"]
  static values = {
    currentPage: String  // 'card', 'team', 'consultation'
  }

  declare readonly itemTargets: HTMLElement[]
  declare readonly currentPageValue: string

  connect(): void {
    this.updateActiveState()
  }

  currentPageValueChanged(): void {
    this.updateActiveState()
  }

  private updateActiveState(): void {
    this.itemTargets.forEach(item => {
      const page = item.dataset.page
      
      if (page === this.currentPageValue) {
        // Active state
        this.setActiveState(item)
      } else {
        // Inactive state
        this.setInactiveState(item)
      }
    })
  }

  private setActiveState(item: HTMLElement): void {
    // Update container classes
    item.classList.remove('hover:bg-gray-50', 'dark:hover:bg-gray-700')
    item.classList.add('bg-primary/5')
    
    // Update icon color
    const svg = item.querySelector('svg')
    if (svg) {
      svg.classList.remove('text-gray-600', 'dark:text-gray-400')
      svg.classList.add('text-primary')
    }
    
    // Update text color and weight
    const span = item.querySelector('span')
    if (span) {
      span.classList.remove('text-gray-600', 'dark:text-gray-400')
      span.classList.add('text-primary', 'font-medium')
    }
  }

  private setInactiveState(item: HTMLElement): void {
    // Update container classes
    item.classList.remove('bg-primary/5')
    item.classList.add('hover:bg-gray-50', 'dark:hover:bg-gray-700')
    
    // Update icon color
    const svg = item.querySelector('svg')
    if (svg) {
      svg.classList.remove('text-primary')
      svg.classList.add('text-gray-600', 'dark:text-gray-400')
    }
    
    // Update text color and weight
    const span = item.querySelector('span')
    if (span) {
      span.classList.remove('text-primary', 'font-medium')
      span.classList.add('text-gray-600', 'dark:text-gray-400')
    }
  }
}
