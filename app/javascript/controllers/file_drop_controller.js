import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "zone", "hint", "fileName", "error"]
  static values = {
    extensions: Array,
    extensionsLabel: String
  }

  connect() {
    this.counter = 0
  }

  dragEnter(event) {
    event.preventDefault()
    event.stopPropagation()
    this.counter++
    this.zoneTarget.classList.add("border-client-accent", "bg-client-accent-muted/50", "shadow-[0_0_0_3px_rgb(13_148_136/0.12)]")
  }

  dragLeave(event) {
    event.preventDefault()
    event.stopPropagation()
    this.counter--
    if (this.counter <= 0) {
      this.counter = 0
      this.zoneTarget.classList.remove("border-client-accent", "bg-client-accent-muted/50", "shadow-[0_0_0_3px_rgb(13_148_136/0.12)]")
    }
  }

  dragOver(event) {
    event.preventDefault()
    event.stopPropagation()
  }

  drop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.counter = 0
    this.zoneTarget.classList.remove("border-client-accent", "bg-client-accent-muted/50", "shadow-[0_0_0_3px_rgb(13_148_136/0.12)]")

    const files = event.dataTransfer?.files
    if (files?.length) this.assignFile(files[0])
  }

  changed() {
    const file = this.inputTarget.files?.[0]
    if (!file) return

    if (!this.validFile(file)) {
      this.clearInput()
      return
    }

    this.clearError()
    this.showFileName(file.name)
    this.submitForm()
  }

  browse(event) {
    event.preventDefault()
    event.stopPropagation()
    this.inputTarget.click()
  }

  zoneClick(event) {
    if (event.target.closest("button, label, input")) return
    this.browse(event)
  }

  assignFile(file) {
    if (!this.validFile(file)) {
      this.clearInput()
      return
    }

    const dt = new DataTransfer()
    dt.items.add(file)
    this.inputTarget.files = dt.files
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  submitForm() {
    const form = this.inputTarget.closest("form")
    if (form) form.requestSubmit()
  }

  showFileName(name) {
    if (this.hasHintTarget) this.hintTarget.classList.add("hidden")
    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = name
      this.fileNameTarget.classList.remove("hidden")
    }
  }

  validFile(file) {
    if (!this.hasExtensionsValue || this.extensionsValue.length === 0) return true

    const extension = file.name.split(".").pop()?.toLowerCase()
    if (!extension || !this.extensionsValue.includes(extension)) {
      this.showError()
      return false
    }

    return true
  }

  showError() {
    if (!this.hasErrorTarget) return

    const label = this.hasExtensionsLabelValue ? this.extensionsLabelValue : "um formato aceito"
    this.errorTarget.textContent = `Formato não aceito. Envie ${label.replace(/\.$/, "")}.`
    this.errorTarget.classList.remove("hidden")

    if (this.hasHintTarget) this.hintTarget.classList.remove("hidden")
    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = ""
      this.fileNameTarget.classList.add("hidden")
    }
  }

  clearError() {
    if (!this.hasErrorTarget) return

    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }

  clearInput() {
    this.inputTarget.value = ""
  }
}
