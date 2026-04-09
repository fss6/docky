import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["error"]
  static values = {
    publishableKey: String,
    clientSecret: String
  }

  async connect() {
    this.errorTarget.textContent = ""

    if (!window.Stripe) {
      this.showError("Nao foi possivel carregar o Stripe.js.")
      return
    }

    if (!this.publishableKeyValue || !this.clientSecretValue) {
      this.showError("Chaves de checkout nao configuradas.")
      return
    }

    try {
      this.stripe = window.Stripe(this.publishableKeyValue)
      this.checkout = await this.stripe.initCheckoutElementsSdk({
        clientSecret: Promise.resolve(this.clientSecretValue)
      })
      this.paymentElement = this.checkout.createPaymentElement()
      this.paymentElement.mount("#payment-element")
    } catch (error) {
      this.showError(error?.message || "Falha ao inicializar checkout.")
    }
  }

  async confirm() {
    this.showError("")
    if (!this.checkout) return

    const loadActionsResult = await this.checkout.loadActions()
    if (loadActionsResult.type === "error") {
      this.showError(loadActionsResult.error.message)
      return
    }

    const { error } = await loadActionsResult.actions.confirm()
    if (error) {
      this.showError(error.message)
    }
  }

  showError(message) {
    this.errorTarget.textContent = message
  }
}
