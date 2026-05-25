import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "button"]

  filter(event) {
    const category = event.currentTarget.dataset.documentFilter
    this.buttonTargets.forEach((btn) => {
      const active = btn.dataset.documentFilter === category
      btn.classList.toggle("client-filter-active", active)
      btn.classList.toggle("client-filter-inactive", !active)
    })

    this.itemTargets.forEach((item) => {
      const itemCat = item.dataset.documentCategory
      const show = category === "todos" || itemCat === category
      item.classList.toggle("hidden", !show)
    })
  }
}
