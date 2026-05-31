import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "hidden"]

  connect() {
    this._syncDisplayFromHidden()
  }

  onInput() {
    const digits = this._digitsOnly(this.displayTarget.value).slice(0, 14)
    this.hiddenTarget.value = digits
    this.displayTarget.value = this._format(digits)
  }

  onBlur() {
    this.sync()
  }

  sync() {
    const digits = this._digitsOnly(this.displayTarget.value).slice(0, 14)
    this.hiddenTarget.value = digits
    this.displayTarget.value = this._format(digits)
  }

  _syncDisplayFromHidden() {
    const digits = this._digitsOnly(this.hiddenTarget.value)
    this.hiddenTarget.value = digits
    if (digits) {
      this.displayTarget.value = this._format(digits)
    }
  }

  _digitsOnly(value) {
    return value.toString().replace(/\D/g, "")
  }

  _format(digits) {
    if (!digits) return ""

    if (digits.length <= 11) {
      return digits
        .replace(/^(\d{3})(\d)/, "$1.$2")
        .replace(/^(\d{3})\.(\d{3})(\d)/, "$1.$2.$3")
        .replace(/^(\d{3})\.(\d{3})\.(\d{3})(\d)/, "$1.$2.$3-$4")
    }

    return digits
      .replace(/^(\d{2})(\d)/, "$1.$2")
      .replace(/^(\d{2})\.(\d{3})(\d)/, "$1.$2.$3")
      .replace(/^(\d{2})\.(\d{3})\.(\d{3})(\d)/, "$1.$2.$3/$4")
      .replace(/^(\d{2})\.(\d{3})\.(\d{3})\/(\d{4})(\d)/, "$1.$2.$3/$4-$5")
  }
}
