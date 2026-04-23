import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button", "feedback"]

  async copy() {
    const text = this.sourceTarget?.textContent?.trim()
    if (!text) return

    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(text)
      } else {
        this.fallbackCopy(text)
      }
      this.showFeedback("Link copiado.")
    } catch (_error) {
      this.showFeedback("Nao foi possivel copiar automaticamente.")
    }
  }

  fallbackCopy(text) {
    const input = document.createElement("textarea")
    input.value = text
    input.setAttribute("readonly", "")
    input.style.position = "absolute"
    input.style.left = "-9999px"
    document.body.appendChild(input)
    input.select()
    document.execCommand("copy")
    document.body.removeChild(input)
  }

  showFeedback(message) {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = message
      this.feedbackTarget.classList.remove("hidden")
    }

    if (this.hasButtonTarget) {
      this.buttonTarget.textContent = "Copiado!"
      window.clearTimeout(this.resetTimer)
      this.resetTimer = window.setTimeout(() => {
        this.buttonTarget.textContent = "Copiar link"
        if (this.hasFeedbackTarget) this.feedbackTarget.classList.add("hidden")
      }, 1800)
    }
  }
}
