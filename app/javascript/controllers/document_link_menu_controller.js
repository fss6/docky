import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["newItemForm"]

  closeOnOutside(event) {
    if (!this.element.open || this.element.contains(event.target)) return

    this.close()
  }

  closeOthers() {
    if (!this.element.open) return

    document.querySelectorAll("[data-controller~='document-link-menu'][open]").forEach((menu) => {
      if (menu !== this.element) menu.open = false
    })
  }

  showNewItem(event) {
    event.preventDefault()
    if (this.hasNewItemFormTarget) {
      this.newItemFormTarget.hidden = false
    }
  }

  close() {
    this.element.open = false
  }
}
