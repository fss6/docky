import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (typeof window.flatpickr !== "function") return

    const initialValue = this.element.value || this.currentPeriod()
    const monthSelectPlugin = window.monthSelectPlugin
    const portugueseLocale = window.flatpickr?.l10ns?.pt
    const parentDialog = this.element.closest("dialog")

    this.picker = window.flatpickr(this.element, {
      locale: portugueseLocale || "pt",
      defaultDate: initialValue,
      allowInput: false,
      altInput: true,
      altFormat: "F/Y",
      clickOpens: true,
      disableMobile: true,
      dateFormat: "Y/m",
      appendTo: parentDialog || undefined,
      onReady: (_selectedDates, _dateStr, instance) => {
        if (instance.altInput) instance.set("positionElement", instance.altInput)
      },
      onOpen: (_selectedDates, _dateStr, instance) => {
        if (instance.altInput) instance.set("positionElement", instance.altInput)
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

  currentPeriod() {
    const now = new Date()
    const month = `${now.getMonth() + 1}`.padStart(2, "0")
    return `${now.getFullYear()}/${month}`
  }
}
