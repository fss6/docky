import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field"]

  connect() {
    this.fields().forEach((field) => this.resizeField(field))
  }

  resize(event) {
    this.resizeField(event.currentTarget)
  }

  fields() {
    if (this.hasFieldTarget) return this.fieldTargets
    if (this.element.tagName === "TEXTAREA") return [this.element]

    return []
  }

  resizeField(field) {
    field.style.height = "auto"
    field.style.overflow = "hidden"
    field.style.height = `${field.scrollHeight}px`
  }
}
