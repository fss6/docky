import { Controller } from "@hotwired/stimulus"
import { showError, showSuccess } from "notyf_instance"

export default class extends Controller {
  static targets = ["source", "button", "label"]

  async copy() {
    const text = this.sourceTarget?.textContent?.trim()
    if (!text) return

    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(text)
      } else {
        this.fallbackCopy(text)
      }
      showSuccess("Link copiado.")
      this.flashButtonLabel("Copiado!")
    } catch (_error) {
      showError("Não foi possível copiar automaticamente.")
      this.flashButtonLabel("Erro ao copiar")
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

  flashButtonLabel(label) {
    const labelTarget = this.hasLabelTarget ? this.labelTarget : (this.hasButtonTarget ? this.buttonTarget : null)
    if (!labelTarget) return

    const originalLabel = labelTarget.dataset.originalLabel || labelTarget.textContent
    labelTarget.dataset.originalLabel = originalLabel
    labelTarget.textContent = label
    window.clearTimeout(this.resetTimer)
    this.resetTimer = window.setTimeout(() => {
      labelTarget.textContent = originalLabel
    }, 1800)
  }
}
