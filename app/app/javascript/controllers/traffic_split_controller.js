import { Controller } from "@hotwired/stimulus"

// Updates the "A: 60% / B: 40%" display as the range slider moves.
export default class extends Controller {
  static targets = ["slider", "display"]

  update() {
    const a = parseInt(this.sliderTarget.value, 10)
    this.displayTarget.textContent = `A: ${a}% / B: ${100 - a}%`
  }
}
