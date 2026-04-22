import { Controller } from "@hotwired/stimulus"

// Toggles visibility of scorer content fields and model-hint select
// based on the selected scorer_type radio. The name="scorer[content]"
// attribute is disabled on hidden fields so stale values from a
// previously-typed draft don't get submitted.
export default class extends Controller {
  static targets = [
    "contentGroup",
    "contentLabel",
    "llmContent",
    "regexContent",
    "customContent",
    "modelGroup"
  ]

  connect() {
    this._applyType(this._currentType())
  }

  typeChanged(event) {
    this._applyType(event.target.value)
  }

  _applyType(type) {
    const visible = this._containerFor(type)

    ;[this.llmContentTarget, this.regexContentTarget, this.customContentTarget].forEach((el) => {
      el.hidden = el !== visible
      this._toggleFieldName(el, el === visible)
    })

    this.contentGroupTarget.hidden = type === "exact_match"
    this.modelGroupTarget.hidden = type !== "llm_judge"

    if (this.hasContentLabelTarget) {
      this.contentLabelTarget.textContent = this._labelFor(type)
    }
  }

  _containerFor(type) {
    switch (type) {
      case "llm_judge": return this.llmContentTarget
      case "regex":     return this.regexContentTarget
      case "custom":    return this.customContentTarget
      default:          return null
    }
  }

  _labelFor(type) {
    switch (type) {
      case "llm_judge": return "Judge prompt template"
      case "regex":     return "Regex pattern"
      case "custom":    return "Content"
      default:          return "Content"
    }
  }

  _toggleFieldName(container, enabled) {
    const field = container.querySelector("textarea, input[type='text']")
    if (!field) return

    if (enabled) {
      if (field.dataset.savedName) {
        field.name = field.dataset.savedName
        delete field.dataset.savedName
      } else if (!field.name) {
        field.name = "scorer[content]"
      }
    } else if (field.name) {
      field.dataset.savedName = field.name
      field.removeAttribute("name")
    }
  }

  _currentType() {
    const checked = this.typeSelectorTarget?.querySelector("input[type='radio']:checked")
    return checked?.value || "llm_judge"
  }

  get typeSelectorTarget() {
    return this.element.querySelector("[data-scorer-form-target='typeSelector']")
  }
}
