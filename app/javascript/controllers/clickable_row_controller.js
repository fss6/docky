import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  visit(event) {
    if (event.type === "keydown" && event.key === " ") {
      event.preventDefault()
    }

    if (event.type === "click" && event.target.closest("a, button")) {
      return
    }

    const url = this.urlValue
    if (!url) return

    if (event.type === "click" && (event.metaKey || event.ctrlKey)) {
      window.open(url, "_blank", "noopener")
      return
    }

    if (typeof Turbo !== "undefined") {
      Turbo.visit(url)
    } else {
      window.location.assign(url)
    }
  }
}
