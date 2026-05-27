import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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

  close() {
    this.element.open = false
  }
}
