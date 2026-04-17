import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { depth: { type: Number, default: 4 } }

  connect() {
    this.element.style.transition = "transform 0.5s cubic-bezier(0.2,0.8,0.2,1)"
    this.element.style.transformStyle = "preserve-3d"
  }

  mousemove(event) {
    const rect = this.element.getBoundingClientRect()
    const x = (event.clientX - rect.left) / rect.width - 0.5
    const y = (event.clientY - rect.top) / rect.height - 0.5
    const depth = this.depthValue

    this.element.style.transition = "transform 0.08s linear"
    this.element.style.transform = `perspective(1000px) rotateX(${y * -depth}deg) rotateY(${x * depth}deg)`
  }

  mouseleave() {
    this.element.style.transition = "transform 0.5s cubic-bezier(0.2,0.8,0.2,1)"
    this.element.style.transform = "perspective(1000px) rotateX(0deg) rotateY(0deg)"
  }
}
