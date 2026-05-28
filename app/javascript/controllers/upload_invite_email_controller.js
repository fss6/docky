import { Controller } from "@hotwired/stimulus"
import { showError, showSuccess } from "notyf_instance"

const STATUS_VARIANT_CLASSES = {
  success: ["bg-emerald-50", "text-emerald-800", "ring-1", "ring-inset", "ring-emerald-600/15"],
  error: ["bg-red-50", "text-red-800", "ring-1", "ring-inset", "ring-red-600/15"]
}

export default class extends Controller {
  static targets = ["button", "label", "status"]
  static values = {
    sendUrl: String,
    successFallback: String,
    errorFallback: String
  }

  async send(event) {
    event.preventDefault()

    this.clearStatus()
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
        const message = data.error || this.errorFallbackValue
        this.showStatus(message, "error")
        showError(message)
        return
      }

      const message = data.message || this.successFallbackValue
      this.showStatus(message, "success")
      showSuccess(message)
    } catch (error) {
      console.error("[upload-invite-email]", error)
      const message = this.errorFallbackValue
      this.showStatus(message, "error")
      showError(message)
    } finally {
      this.setSending(false)
    }
  }

  clearStatus() {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = ""
    this.statusTarget.classList.add("hidden")
    this.statusTarget.classList.remove(...STATUS_VARIANT_CLASSES.success, ...STATUS_VARIANT_CLASSES.error)
  }

  showStatus(message, variant) {
    if (!this.hasStatusTarget) return

    this.clearStatus()
    this.statusTarget.textContent = message
    this.statusTarget.classList.remove("hidden")
    this.statusTarget.classList.add(...STATUS_VARIANT_CLASSES[variant])
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
