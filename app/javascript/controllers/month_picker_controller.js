import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "openButton"]

  static values = {
    autoNavigate: { type: Boolean, default: false },
    navigateUrl: String,
    aba: String
  }

  connect() {
    if (typeof window.flatpickr !== "function") return

    const input = this.inputElement
    const initialValue = input.value || this.currentPeriod()
    const monthSelectPlugin = window.monthSelectPlugin
    const portugueseLocale = window.flatpickr?.l10ns?.pt
    const parentDialog = input.closest("dialog")
    const useAltInput = !this.autoNavigateValue

    this.picker = window.flatpickr(input, {
      locale: portugueseLocale || "pt",
      defaultDate: initialValue,
      allowInput: false,
      altInput: useAltInput,
      altFormat: "F/Y",
      clickOpens: false,
      disableMobile: true,
      dateFormat: "Y/m",
      appendTo: parentDialog || undefined,
      onChange: (selectedDates) => {
        if (this.autoNavigateValue && selectedDates.length > 0) {
          this.navigateToPeriod(selectedDates[0])
        }
      },
      onReady: (_selectedDates, _dateStr, instance) => {
        // In auto-navigate mode the label is rendered in ERB; hide the altInput
        // that flatpickr may have injected so it does not duplicate the date.
        if (this.autoNavigateValue && instance.altInput) {
          instance.altInput.setAttribute("aria-hidden", "true")
          instance.altInput.style.display = "none"
        }
        const positionEl = this.positionElement(instance)
        if (positionEl) instance.set("positionElement", positionEl)
      },
      onOpen: (_selectedDates, _dateStr, instance) => {
        const positionEl = this.positionElement(instance)
        if (positionEl) instance.set("positionElement", positionEl)
      },
      plugins: monthSelectPlugin ? [
        monthSelectPlugin({
          shorthand: true,
          dateFormat: "Y/m",
          altFormat: "F/Y"
        })
      ] : []
    })
  }

  disconnect() {
    if (this.picker) this.picker.destroy()
  }

  open(event) {
    event?.preventDefault()
    this.picker?.open()
  }

  currentPeriod() {
    const now = new Date()
    const month = `${now.getMonth() + 1}`.padStart(2, "0")
    return `${now.getFullYear()}/${month}`
  }

  get inputElement() {
    return this.hasInputTarget ? this.inputTarget : this.element
  }

  positionElement(instance) {
    if (this.hasOpenButtonTarget) return this.openButtonTarget
    if (instance.altInput) return instance.altInput
    return instance.input
  }

  navigateToPeriod(date) {
    if (!this.hasNavigateUrlValue) return

    const year = date.getFullYear()
    const month = `${date.getMonth() + 1}`.padStart(2, "0")
    const url = new URL(this.navigateUrlValue, window.location.origin)
    url.searchParams.set("period", `${year}-${month}`)
    if (this.hasAbaValue && this.abaValue) url.searchParams.set("aba", this.abaValue)

    window.Turbo?.visit(url.toString()) || (window.location.href = url.toString())
  }
}
