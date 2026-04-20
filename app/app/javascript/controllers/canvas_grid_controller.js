import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.canvas = this.element
    this.ctx = this.canvas.getContext("2d")
    this.points = []
    this.time = 0
    this.mouse = { x: -1000, y: -1000 }

    this.resize()
    this.boundResize = this.resize.bind(this)
    this.boundMouseMove = this.trackMouse.bind(this)
    window.addEventListener("resize", this.boundResize)
    window.addEventListener("mousemove", this.boundMouseMove)
    this.draw()
  }

  disconnect() {
    window.removeEventListener("resize", this.boundResize)
    window.removeEventListener("mousemove", this.boundMouseMove)
    cancelAnimationFrame(this.frame)
  }

  resize() {
    const w = this.canvas.width = window.innerWidth
    const h = this.canvas.height = window.innerHeight * 2
    const cols = Math.ceil(w / 52) + 1
    const rows = Math.ceil(h / 52) + 1
    this.points = []
    for (let r = 0; r < rows; r++)
      for (let c = 0; c < cols; c++)
        this.points.push({ ox: c * 52, oy: r * 52, x: c * 52, y: r * 52 })
  }

  trackMouse(e) { this.mouse = { x: e.clientX, y: e.clientY + window.scrollY } }

  draw() {
    this.time += 0.0015
    const { ctx, points, mouse } = this
    const w = this.canvas.width, h = this.canvas.height
    ctx.clearRect(0, 0, w, h)

    points.forEach(p => {
      const dx = p.ox - mouse.x, dy = p.oy - mouse.y
      const dist = Math.sqrt(dx * dx + dy * dy)
      const influence = Math.max(0, 1 - dist / 160)
      const wave = Math.sin(p.ox * 0.007 + this.time) * 2.5 + Math.cos(p.oy * 0.009 + this.time * 0.6) * 2
      p.x = p.ox + wave + dx * influence * 0.05
      p.y = p.oy + wave * 0.4 + dy * influence * 0.05
      const alpha = 0.04 + influence * 0.25
      const radius = 1 + influence * 1.5
      ctx.fillStyle = `rgba(0,0,0,${alpha})`
      ctx.beginPath()
      ctx.arc(p.x, p.y, radius, 0, Math.PI * 2)
      ctx.fill()
    })

    this.frame = requestAnimationFrame(() => this.draw())
  }
}
