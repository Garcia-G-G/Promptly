import { Controller } from "@hotwired/stimulus"

// Custom confirmation dialog for destructive actions. Renders an
// overlay with an optional "type this to confirm" input, then posts
// a hidden Rails form to the given URL + method.
//
// Usage:
//   <button data-controller="confirm"
//           data-action="click->confirm#show"
//           data-confirm-title-value="Delete workspace"
//           data-confirm-message-value="This cannot be undone."
//           data-confirm-confirm-text-value="my-workspace"
//           data-confirm-url-value="/workspaces/my-workspace"
//           data-confirm-method-value="delete">Delete</button>
export default class extends Controller {
  static values = {
    title: String,
    message: String,
    confirmText: String,
    url: String,
    method: { type: String, default: "delete" }
  }

  show(event) {
    event.preventDefault()
    const overlay = document.createElement("div")
    overlay.className = "confirm-overlay"
    overlay.innerHTML = this._dialogHTML()
    document.body.appendChild(overlay)

    const cancelBtn = overlay.querySelector("[data-confirm-cancel]")
    const executeBtn = overlay.querySelector("[data-confirm-execute]")
    const input = overlay.querySelector("[data-confirm-input]")

    const close = () => overlay.remove()

    cancelBtn.addEventListener("click", close)
    overlay.addEventListener("click", (e) => { if (e.target === overlay) close() })

    if (this.confirmTextValue) {
      executeBtn.disabled = true
      input.addEventListener("input", () => {
        executeBtn.disabled = input.value !== this.confirmTextValue
      })
      input.focus()
    } else {
      executeBtn.focus()
    }

    executeBtn.addEventListener("click", () => {
      this._submit()
      close()
    })
  }

  _dialogHTML() {
    const challenge = this.confirmTextValue ? `
      <div class="form-group" style="margin-top: 16px;">
        <label class="form-label">
          Type <code style="font-family: var(--font-mono); color: var(--red);">${this._escape(this.confirmTextValue)}</code> to confirm
        </label>
        <input type="text" class="form-input" data-confirm-input autocomplete="off" autocapitalize="off">
      </div>
    ` : ""

    return `
      <div class="confirm-modal" role="dialog" aria-modal="true">
        <h3 class="confirm-modal__title">${this._escape(this.titleValue)}</h3>
        <p class="confirm-modal__message">${this._escape(this.messageValue)}</p>
        ${challenge}
        <div style="display: flex; gap: 8px; margin-top: 20px; justify-content: flex-end;">
          <button type="button" class="btn btn--secondary" data-confirm-cancel>Cancel</button>
          <button type="button" class="btn btn--danger" data-confirm-execute>Confirm</button>
        </div>
      </div>
    `
  }

  _submit() {
    const form = document.createElement("form")
    form.method = "POST"
    form.action = this.urlValue
    form.style.display = "none"

    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrf) this._addField(form, "authenticity_token", csrf)
    this._addField(form, "_method", this.methodValue)

    document.body.appendChild(form)
    form.submit()
  }

  _addField(form, name, value) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = name
    input.value = value
    form.appendChild(input)
  }

  _escape(value) {
    const div = document.createElement("div")
    div.textContent = value
    return div.innerHTML
  }
}
