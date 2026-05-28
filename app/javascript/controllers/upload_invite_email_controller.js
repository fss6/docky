import { Controller } from "@hotwired/stimulus"
import { showError, showSuccess } from "notyf_instance"

export default class extends Controller {
  static targets = ["button", "label"]
  static values = { sendUrl: String }

  async send(event) {
    event.preventDefault()

    this.setSending(true)

    try {
      const token = this.csrfToken
      if (!token) throw new Error("missing csrf token")

      const response = await fetch(this.sendUrlValue, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": token
        },
        body: new URLSearchParams({ authenticity_token: token }),
        credentials: "same-origin"
      })

      const data = await response.json().catch(() => ({}))

      if (!response.ok) {
        showError(data.error || "Não foi possível enviar o e-mail.")
        return
      }

      showSuccess(data.message || "Envio em andamento.")
    } catch (error) {
      console.error("[upload-invite-email]", error)
      showError("Não foi possível enviar o e-mail.")
    } finally {
      this.setSending(false)
    }
  }

  setSending(sending) {
    if (!this.hasButtonTarget) return

    this.buttonTarget.disabled = sending
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = sending ? "Enviando…" : "Enviar e-mail"
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
