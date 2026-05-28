import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field"]

  static values = {
    texts: Array,
    confirmHeading: String,
    confirmBody: String,
    confirmText: String
  }

  requestRestore(event) {
    event.preventDefault()

    const modalRoot = this.element.closest('[data-controller*="app-confirm-modal"]')
    if (!modalRoot) return

    const modal = this.application.getControllerForElementAndIdentifier(modalRoot, "app-confirm-modal")
    if (!modal?.openForCallback) return

    modal.openForCallback({
      heading: this.confirmHeadingValue,
      bodySuffix: this.confirmBodyValue,
      confirmText: this.confirmTextValue,
      confirmVariant: "primary",
      onConfirm: () => this.applyRestore()
    })
  }

  applyRestore() {
    this.fieldTargets.forEach((field, index) => {
      const text = this.textsValue[index]
      if (text == null) return

      field.value = text
      field.dispatchEvent(new Event("input", { bubbles: true }))
    })
  }
}
