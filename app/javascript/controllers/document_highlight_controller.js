import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const target = this.element.querySelector("[data-document-highlight-target]")
    if (!target) return

    requestAnimationFrame(() => {
      target.scrollIntoView({ behavior: "smooth", block: "center" })
    })
  }
}
