import { Controller } from "@hotwired/stimulus"

// Copies the text content of the `source` target to the clipboard
// and gives a "Copied!" visual confirmation on the `button` target.
// Falls back to document.execCommand for older browsers that don't
// expose navigator.clipboard.
export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const text = this.sourceTarget.textContent.trim()
    try {
      await navigator.clipboard.writeText(text)
      this._flash()
    } catch {
      this._legacyCopy(text)
    }
  }

  _legacyCopy(text) {
    const ta = document.createElement("textarea")
    ta.value = text
    ta.style.position = "fixed"
    ta.style.opacity = "0"
    document.body.appendChild(ta)
    ta.select()
    try { document.execCommand("copy") } finally { document.body.removeChild(ta) }
    this._flash()
  }

  _flash() {
    if (!this.hasButtonTarget) return
    const btn = this.buttonTarget
    const original = btn.textContent
    btn.textContent = "Copied!"
    btn.classList.add("btn--success-flash")
    clearTimeout(this._flashTimer)
    this._flashTimer = setTimeout(() => {
      btn.textContent = original
      btn.classList.remove("btn--success-flash")
    }, 2000)
  }

  disconnect() {
    clearTimeout(this._flashTimer)
  }
}
