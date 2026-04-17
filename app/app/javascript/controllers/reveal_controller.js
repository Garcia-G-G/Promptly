import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 0 } }

  connect() {
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(24px)"

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          setTimeout(() => {
            this.element.style.transition = "opacity 0.6s cubic-bezier(0.16,1,0.3,1), transform 0.6s cubic-bezier(0.16,1,0.3,1)"
            this.element.style.opacity = "1"
            this.element.style.transform = "translateY(0)"
          }, this.delayValue)
          observer.disconnect()
        }
      })
    }, { threshold: 0.1 })

    observer.observe(this.element)
  }
}
