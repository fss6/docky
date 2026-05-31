import { Controller } from "@hotwired/stimulus"
import { formatTaxId, searchNormalizeTaxId } from "tax_id"

// Combobox de atalho para abrir a página do cliente (/clients/:id).
export default class extends Controller {
  static targets = ["query", "list"]
  static values = {
    clients: { type: Array, default: [] }
  }

  connect() {
    this.activeIndex = -1
    this._setExpanded(false)
  }

  search() {
    this.activeIndex = -1
    const raw = this.queryTarget.value.trim()
    const all = this.clientsValue
    let filtered
    if (!raw) {
      filtered = all.slice(0, 40)
    } else {
      filtered = all.filter((client) => this._matchesQuery(client, raw))
    }
    this._renderList(filtered)
    if (all.length === 0) {
      this.listTarget.classList.add("hidden")
      this._setExpanded(false)
    } else {
      this.listTarget.classList.remove("hidden")
      this._setExpanded(true)
    }
  }

  _matchesQuery(client, raw) {
    const term = raw.toLowerCase()
    if (client.name.toLowerCase().includes(term)) return true

    const taxTerm = searchNormalizeTaxId(raw)
    if (!taxTerm) return false

    const storedTax = searchNormalizeTaxId(client.tax_id || "")
    return storedTax.includes(taxTerm)
  }

  open() {
    window.clearTimeout(this._blurTimeout)
    this.search()
  }

  chevronPointerDown(event) {
    event.preventDefault()
  }

  toggle(event) {
    event.preventDefault()
    window.clearTimeout(this._blurTimeout)
    const open = !this.listTarget.classList.contains("hidden")
    if (open) {
      this.listTarget.classList.add("hidden")
      this.activeIndex = -1
      this._setExpanded(false)
    } else {
      this.queryTarget.focus()
      this.open()
    }
  }

  _setExpanded(open) {
    this.queryTarget.setAttribute("aria-expanded", open ? "true" : "false")
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.listTarget.classList.add("hidden")
      this.activeIndex = -1
      this._setExpanded(false)
      return
    }

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
      if (!chosen) return
      this._pickElement(chosen)
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
    if (!li) return
    this._pickElement(li)
  }

  _pickElement(li) {
    const id = li.dataset.id
    if (!id) return
    const n = parseInt(id, 10)
    const client = this.clientsValue.find((i) => Number(i.id) === n)
    if (client) this._navigateTo(client)
  }

  _navigateTo(client) {
    this.listTarget.classList.add("hidden")
    this.activeIndex = -1
    this._setExpanded(false)
    window.location.assign(`/clients/${client.id}`)
  }

  _renderList(filtered) {
    if (filtered.length === 0) {
      this.listTarget.innerHTML =
        '<li class="px-3 py-2 text-sm text-zinc-500">Nenhum cliente encontrado.</li>'
      return
    }

    this.listTarget.innerHTML = filtered
      .map((c) => {
        const taxLine = c.tax_id
          ? `<span class="block text-xs text-zinc-500">${this._escapeHtml(formatTaxId(c.tax_id))}</span>`
          : ""
        return `<li role="option" data-id="${c.id}" class="cursor-pointer px-3 py-2 text-sm text-zinc-800 hover:bg-zinc-50"><span class="block">${this._escapeHtml(c.name)}</span>${taxLine}</li>`
      })
      .join("")
  }

  _escapeHtml(s) {
    const d = document.createElement("div")
    d.textContent = s
    return d.innerHTML
  }

  blur() {
    this._blurTimeout = window.setTimeout(() => {
      this.listTarget.classList.add("hidden")
      this._setExpanded(false)
    }, 180)
  }
}
