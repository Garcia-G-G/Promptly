import { Controller } from "@hotwired/stimulus"

// Populates Variant A/B version dropdowns from the selected prompt's
// data-versions attribute (JSON, set server-side on each prompt option).
export default class extends Controller {
  static targets = ["promptSelect", "variantASelect", "variantBSelect"]

  promptChanged() {
    const opt = this.promptSelectTarget.selectedOptions[0]
    const json = opt?.dataset?.versions

    if (!json) {
      this.clearSelects()
      return
    }

    let versions
    try {
      versions = JSON.parse(json)
    } catch {
      this.clearSelects()
      return
    }

    this.populate(this.variantASelectTarget, versions, "Select Variant A…")
    this.populate(this.variantBSelectTarget, versions, "Select Variant B…")
  }

  populate(select, versions, placeholder) {
    select.replaceChildren(this.option("", placeholder))
    versions.forEach((v) => select.appendChild(this.option(v.id, v.label)))
  }

  clearSelects() {
    const placeholder = "Select prompt first…"
    ;[this.variantASelectTarget, this.variantBSelectTarget].forEach((s) => {
      s.replaceChildren(this.option("", placeholder))
    })
  }

  option(value, label) {
    const o = document.createElement("option")
    o.value = value
    o.textContent = label
    return o
  }
}
