import { Controller } from "@hotwired/stimulus"

// Minimal click-to-toggle dropdown with outside-click dismissal.
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.boundOutside = this.closeOnOutsideClick.bind(this)
  }

  toggle(event) {
    event.stopPropagation()
    const willOpen = this.menuTarget.hidden
    this.menuTarget.hidden = !willOpen
    if (willOpen) {
      document.addEventListener("click", this.boundOutside)
    } else {
      document.removeEventListener("click", this.boundOutside)
    }
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.hidden = true
      document.removeEventListener("click", this.boundOutside)
    }
  }

  disconnect() {
    document.removeEventListener("click", this.boundOutside)
  }
}
