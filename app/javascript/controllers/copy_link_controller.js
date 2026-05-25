import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button", "label", "feedback"]

  async copy() {
    const text = this.sourceTarget?.textContent?.trim()
    if (!text) return

    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(text)
      } else {
        this.fallbackCopy(text)
      }
      this.showFeedback("Link copiado.", "Copiado!")
    } catch (_error) {
      this.showFeedback("Nao foi possivel copiar automaticamente.", "Erro ao copiar")
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

  showFeedback(message, label) {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = message
      this.feedbackTarget.classList.remove("hidden")
    }

    const labelTarget = this.hasLabelTarget ? this.labelTarget : (this.hasButtonTarget ? this.buttonTarget : null)
    if (labelTarget) {
      const originalLabel = labelTarget.dataset.originalLabel || labelTarget.textContent
      labelTarget.dataset.originalLabel = originalLabel
      labelTarget.textContent = label
      window.clearTimeout(this.resetTimer)
      this.resetTimer = window.setTimeout(() => {
        labelTarget.textContent = originalLabel
        if (this.hasFeedbackTarget) this.feedbackTarget.classList.add("hidden")
      }, 1800)
    }
  }
}
