import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (typeof window.flatpickr !== "function") return

    const portugueseLocale = window.flatpickr?.l10ns?.pt
    const parentDialog = this.element.closest("dialog")

    this.picker = window.flatpickr(this.element, {
      locale: portugueseLocale || "pt",
      allowInput: false,
      altInput: true,
      altFormat: "d/m/Y",
      dateFormat: "Y-m-d",
      clickOpens: true,
      disableMobile: true,
      appendTo: parentDialog || undefined,
      onReady: (_selectedDates, _dateStr, instance) => {
        if (instance.altInput) instance.set("positionElement", instance.altInput)
      },
      onOpen: (_selectedDates, _dateStr, instance) => {
        if (instance.altInput) instance.set("positionElement", instance.altInput)
      }
    })
  }

  disconnect() {
    if (this.picker) this.picker.destroy()
  }
}
