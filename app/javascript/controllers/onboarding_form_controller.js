import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option", "radio", "submit"]

  select(event) {
    const label = event.currentTarget
    const radio = label.querySelector('input[type="radio"]')
    if (!radio) return

    radio.checked = true
    this.optionTargets.forEach((option) => {
      option.classList.remove("onboarding-radio-selected")
      option.classList.add("onboarding-radio-default")
    })
    label.classList.remove("onboarding-radio-default")
    label.classList.add("onboarding-radio-selected")

    if (this.hasSubmitTarget) {
      this.submitTarget.value = radio.value === "skipped" ? "Cadastrar cliente" : "Cadastrar e iniciar onboarding →"
    }
  }
}
