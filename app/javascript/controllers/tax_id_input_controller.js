import { Controller } from "@hotwired/stimulus"
import { formatTaxId, normalizeTaxId } from "tax_id"

export default class extends Controller {
  static targets = ["display", "hidden"]
  static values = { prefer: { type: String, default: "auto" } }

  connect() {
    this._syncDisplayFromHidden()
  }

  onInput() {
    this._applyMask()
  }

  onBlur() {
    this.sync()
  }

  sync() {
    this._applyMask()
  }

  _applyMask() {
    const normalized = normalizeTaxId(this.displayTarget.value)
    const formatted = formatTaxId(normalized, { prefer: this.preferValue })

    this.hiddenTarget.value = normalized
    this.displayTarget.value = formatted
  }

  _syncDisplayFromHidden() {
    const normalized = normalizeTaxId(this.hiddenTarget.value)
    this.hiddenTarget.value = normalized
    if (normalized) {
      this.displayTarget.value = formatTaxId(normalized, { prefer: this.preferValue })
    }
  }
}
