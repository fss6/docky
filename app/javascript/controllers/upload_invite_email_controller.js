import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "label", "feedback", "error"]
  static values = { sendUrl: String }

  async send(event) {
    event.preventDefault()

    this.clearMessages()
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
        this.showError(data.error || "Não foi possível enviar o e-mail.")
        return
      }

      this.showFeedback(data.message || "E-mail enviado.")
    } catch (error) {
      console.error("[upload-invite-email]", error)
      this.showError("Não foi possível enviar o e-mail.")
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

  showFeedback(message) {
    if (!this.hasFeedbackTarget) return

    this.feedbackTarget.textContent = message
    this.feedbackTarget.classList.remove("hidden")
  }

  showError(message) {
    if (!this.hasErrorTarget) return

    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  clearMessages() {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = ""
      this.feedbackTarget.classList.add("hidden")
    }
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.classList.add("hidden")
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
