import { Controller } from "@hotwired/stimulus"
import { showToast } from "notyf_instance"

export default class extends Controller {
  connect() {
    this.processToasts = this.processToasts.bind(this)
    this.scheduleProcessToasts = this.scheduleProcessToasts.bind(this)
    this.handleDocfyToast = this.handleDocfyToast.bind(this)

    this.scheduleProcessToasts()
    document.addEventListener("turbo:load", this.scheduleProcessToasts)
    document.addEventListener("turbo:render", this.scheduleProcessToasts)
    document.addEventListener("turbo:submit-end", this.scheduleProcessToasts)
    document.addEventListener("turbo:after-stream-render", this.scheduleProcessToasts)
    document.addEventListener("docfy:toast", this.handleDocfyToast)
    document.addEventListener("docfy:process-toasts", this.scheduleProcessToasts)

    this.observeFlashMessages()
    this.observeToastTemplates()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.scheduleProcessToasts)
    document.removeEventListener("turbo:render", this.scheduleProcessToasts)
    document.removeEventListener("turbo:submit-end", this.scheduleProcessToasts)
    document.removeEventListener("turbo:after-stream-render", this.scheduleProcessToasts)
    document.removeEventListener("docfy:toast", this.handleDocfyToast)
    document.removeEventListener("docfy:process-toasts", this.scheduleProcessToasts)

    this.flashObserver?.disconnect()
    this.bodyObserver?.disconnect()
  }

  handleDocfyToast(event) {
    const { type = "success", message } = event.detail || {}
    showToast({ type, message })
  }

  scheduleProcessToasts() {
    requestAnimationFrame(this.processToasts)
  }

  observeFlashMessages() {
    const flashMessages = document.getElementById("flash_messages")
    if (!flashMessages) return

    this.flashObserver = new MutationObserver(this.scheduleProcessToasts)
    this.flashObserver.observe(flashMessages, { childList: true, subtree: true })
  }

  observeToastTemplates() {
    this.bodyObserver = new MutationObserver((mutations) => {
      const hasToastTemplate = mutations.some((mutation) =>
        [...mutation.addedNodes].some((node) => this.nodeHasToastTemplate(node))
      )
      if (hasToastTemplate) this.scheduleProcessToasts()
    })
    this.bodyObserver.observe(document.body, { childList: true, subtree: true })
  }

  nodeHasToastTemplate(node) {
    if (node.nodeType !== Node.ELEMENT_NODE) return false
    if (node.matches?.("template[data-toast-message]")) return true
    return Boolean(node.querySelector?.("template[data-toast-message]"))
  }

  processToasts() {
    const templates = document.querySelectorAll("template[data-toast-message]")
    templates.forEach((template) => {
      const message = template.content.textContent?.trim()
      const type = template.dataset.toastType || "success"
      if (message) showToast({ type, message })
      template.remove()
    })
  }
}
