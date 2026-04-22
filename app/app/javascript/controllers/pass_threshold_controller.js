import { Controller } from "@hotwired/stimulus"

// Formats a 0..1 range slider value as a percentage in the label.
export default class extends Controller {
  static targets = ["slider", "display"]

  connect() { this.update() }

  update() {
    const pct = Math.round(parseFloat(this.sliderTarget.value) * 100)
    this.displayTarget.textContent = `${pct}%`
  }
}
