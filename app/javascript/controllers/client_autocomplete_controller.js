import { Controller } from "@hotwired/stimulus"

// Combobox para o selector "Cliente ativo" (inclui "Todos os clientes" com id vazio).
export default class extends Controller {
  static targets = ["hidden", "query", "list"]
  static values = {
    clients: { type: Array, default: [] }
  }

  connect() {
    this.activeIndex = -1
    this._lastHidden = this.hiddenTarget.value
    this._syncQueryFromHidden()
    this._setExpanded(false)
  }

  _syncQueryFromHidden() {
    const hv = this.hiddenTarget.value
    const entry = this.clientsValue.find((i) => String(i.id) === String(hv))
    if (entry) this.queryTarget.value = entry.name
  }

  // Quando o texto coincide com o valor já resolvido (hidden), mostrar lista completa como um <select>.
  _isShowingResolvedSelection() {
    const entry = this.clientsValue.find((i) => String(i.id) === String(this.hiddenTarget.value))
    if (!entry) return false
    const q = this.queryTarget.value.trim()
    if (!q) return false
    return entry.name.toLowerCase() === q.toLowerCase()
  }

  search() {
    this.activeIndex = -1
    const raw = this.queryTarget.value.trim().toLowerCase()
    const all = this.clientsValue
    let filtered
    if (this._isShowingResolvedSelection()) {
      filtered = all
    } else if (!raw) {
      filtered = all.slice(0, 40)
    } else {
      filtered = all.filter((i) => i.name.toLowerCase().includes(raw))
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
    if (li.dataset.empty === "true") {
      const entry = this.clientsValue.find((i) => i.id === "" || i.id === null)
      if (entry) this._select(entry)
      return
    }
    const id = li.dataset.id
    const n = parseInt(id, 10)
    const client = this.clientsValue.find((i) => Number(i.id) === n)
    if (client) this._select(client)
  }

  _select(entry) {
    this.hiddenTarget.value = entry.id === "" || entry.id === null ? "" : String(entry.id)
    this.queryTarget.value = entry.name
    this.listTarget.classList.add("hidden")
    this.activeIndex = -1
    this._setExpanded(false)
    if (this._lastHidden !== this.hiddenTarget.value) {
      this._lastHidden = this.hiddenTarget.value
      this.element.closest("form")?.requestSubmit()
    }
  }

  _renderList(filtered) {
    this.listTarget.innerHTML = filtered
      .map((c) => {
        const isEmpty = c.id === "" || c.id === null || c.id === undefined
        const attr = isEmpty ? 'data-empty="true"' : `data-id="${c.id}"`
        return `<li role="option" ${attr} class="cursor-pointer px-3 py-2 text-sm text-zinc-800 hover:bg-zinc-50">${this._escapeHtml(c.name)}</li>`
      })
      .join("")
    if (filtered.length === 0) {
      this.listTarget.innerHTML =
        '<li class="px-3 py-2 text-sm text-zinc-500">Nenhum cliente encontrado.</li>'
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
      this._setExpanded(false)
      const before = this.hiddenTarget.value
      this._resolveHiddenFromQuery()
      if (before !== this.hiddenTarget.value) {
        this._lastHidden = this.hiddenTarget.value
        this.element.closest("form")?.requestSubmit()
      }
    }, 180)
  }

  _resolveHiddenFromQuery() {
    const q = this.queryTarget.value.trim()
    if (!q) {
      const todos = this.clientsValue.find((i) => i.id === "" || i.id === null)
      if (todos) {
        this.hiddenTarget.value = ""
        this.queryTarget.value = todos.name
      } else {
        this.hiddenTarget.value = ""
      }
      return
    }
    const exact = this.clientsValue.find((i) => i.name.toLowerCase() === q.toLowerCase())
    if (exact) {
      this.hiddenTarget.value = exact.id === "" || exact.id === null ? "" : String(exact.id)
      this.queryTarget.value = exact.name
    } else {
      this.hiddenTarget.value = ""
    }
  }
}
