import { Controller } from "@hotwired/stimulus"

// Combobox: pesquisa por nome e define o hidden `institution_id`.
export default class extends Controller {
  static targets = ["hidden", "query", "list"]
  static values = {
    institutions: { type: Array, default: [] }
  }

  connect() {
    this.activeIndex = -1
    this._syncQueryFromHidden()
  }

  _syncQueryFromHidden() {
    const id = this.hiddenTarget.value
    if (!id) return
    const n = parseInt(id, 10)
    const inst = this.institutionsValue.find((i) => i.id === n)
    if (inst) this.queryTarget.value = inst.name
  }

  search() {
    this.activeIndex = -1
    const raw = this.queryTarget.value.trim().toLowerCase()
    const all = this.institutionsValue
    let filtered
    if (!raw) {
      filtered = all.slice(0, 40)
    } else {
      filtered = all.filter((i) => i.name.toLowerCase().includes(raw))
    }
    this._renderList(filtered)
    if (all.length === 0) {
      this.listTarget.classList.add("hidden")
    } else {
      this.listTarget.classList.remove("hidden")
    }
  }

  open() {
    window.clearTimeout(this._blurTimeout)
    this.search()
  }

  keydown(event) {
    const items = this.listTarget.querySelectorAll('[role="option"]')
    if (items.length === 0) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.activeIndex = Math.min(this.activeIndex + 1, items.length - 1)
      this._highlight(items)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.activeIndex = Math.max(this.activeIndex - 1, 0)
      this._highlight(items)
    } else if (event.key === "Enter") {
      event.preventDefault()
      const chosen = this.activeIndex >= 0 ? items[this.activeIndex] : items.length === 1 ? items[0] : null
      if (!chosen || !chosen.dataset.id) return
      const id = parseInt(chosen.dataset.id, 10)
      const inst = this.institutionsValue.find((i) => i.id === id)
      if (inst) this._select(inst.id, inst.name)
    } else if (event.key === "Escape") {
      this.listTarget.classList.add("hidden")
      this.activeIndex = -1
    }
  }

  _highlight(items) {
    items.forEach((el, i) => {
      el.classList.toggle("bg-teal-50", i === this.activeIndex)
      el.classList.toggle("text-accent", i === this.activeIndex)
    })
  }

  pick(event) {
    event.preventDefault()
    const li = event.target.closest("li[role=option]")
    if (!li || !li.dataset.id) return
    const id = parseInt(li.dataset.id, 10)
    const inst = this.institutionsValue.find((i) => i.id === id)
    if (!inst) return
    this._select(inst.id, inst.name)
  }

  _select(id, name) {
    this.hiddenTarget.value = id
    this.queryTarget.value = name
    this.listTarget.classList.add("hidden")
    this.activeIndex = -1
    this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  _renderList(filtered) {
    this.listTarget.innerHTML = filtered
      .map(
        (i) =>
          `<li role="option" data-id="${i.id}" class="cursor-pointer px-3 py-2 text-sm text-zinc-800 hover:bg-zinc-50">${this._escapeHtml(i.name)}</li>`
      )
      .join("")
    if (filtered.length === 0) {
      this.listTarget.innerHTML =
        '<li class="px-3 py-2 text-sm text-zinc-500">Nenhuma instituição encontrada.</li>'
    }
  }

  _escapeHtml(s) {
    const d = document.createElement("div")
    d.textContent = s
    return d.innerHTML
  }

  blur() {
    this._blurTimeout = window.setTimeout(() => {
      this.listTarget.classList.add("hidden")
      this._resolveHiddenFromQuery()
    }, 180)
  }


  _resolveHiddenFromQuery() {
    const q = this.queryTarget.value.trim()
    if (!q) {
      this.hiddenTarget.value = ""
      return
    }
    const exact = this.institutionsValue.find((i) => i.name.toLowerCase() === q.toLowerCase())
    if (exact) {
      this.hiddenTarget.value = exact.id
      this.queryTarget.value = exact.name
    } else {
      this.hiddenTarget.value = ""
    }
  }
}
