import { Controller } from "@hotwired/stimulus"

/**
 * ImagePreview Controller - Handles image preview before upload
 */
export default class extends Controller<HTMLElement> {
  static targets = ["input", "preview", "placeholder"]

  declare readonly inputTarget: HTMLInputElement
  declare readonly previewTarget: HTMLImageElement
  declare readonly placeholderTarget: HTMLElement

  connect(): void {
    console.log("ImagePreview connected")
  }

  preview(): void {
    const file = this.inputTarget.files?.[0]
    
    if (file) {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        const result = e.target?.result as string
        
        // Show preview image
        this.previewTarget.src = result
        this.previewTarget.classList.remove('hidden')
        
        // Hide placeholder
        if (this.hasPlaceholderTarget) {
          this.placeholderTarget.classList.add('hidden')
        }
        
        console.log("Image preview updated")
      }
      
      reader.readAsDataURL(file)
    }
  }
}
