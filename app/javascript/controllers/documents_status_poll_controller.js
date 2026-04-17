import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "emptyState"]
  static values = {
    url: String,
    intervalMs: { type: Number, default: 4000 }
  }

  connect() {
    this.poll()
  }

  disconnect() {
    this.stopTimer()
  }

  async poll() {
    await this.refresh()
    this.stopTimer()
    this.timer = setTimeout(() => this.poll(), this.intervalMsValue)
  }

  async refresh() {
    if (!this.urlValue) return

    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      })
      if (!response.ok) return

      const payload = await response.json()
      this.renderDocuments(payload.documents || [])
    } catch (_error) {
      // Silently ignore transient polling failures.
    }
  }

  renderDocuments(documents) {
    if (!this.hasListTarget || !this.hasEmptyStateTarget) return

    if (documents.length === 0) {
      this.listTarget.innerHTML = ""
      this.emptyStateTarget.classList.remove("hidden")
      return
    }

    this.emptyStateTarget.classList.add("hidden")
    this.listTarget.innerHTML = documents.map((doc) => this.documentRow(doc)).join("")
  }

  documentRow(doc) {
    const icon = this.statusIcon(doc.status)
    const escapedName = this.escapeHtml(doc.name || "—")
    const escapedStatus = this.escapeHtml(doc.status_label || doc.status || "—")
    const escapedDate = this.escapeHtml(doc.created_at_label || "—")
    const escapedPath = this.escapeHtml(doc.show_path || "#")
    const badgeClasses = this.escapeHtml(doc.status_badge_classes || "bg-zinc-100 text-zinc-700")

    return `
      <li class="flex items-center justify-between gap-3 rounded-md border border-zinc-200/80 bg-white px-3 py-2">
        <div class="min-w-0">
          <a href="${escapedPath}" class="block truncate text-sm font-medium text-zinc-900 no-underline hover:text-accent">${escapedName}</a>
          <p class="mt-0.5 text-xs text-zinc-500">Enviado em ${escapedDate}</p>
        </div>
        <div class="inline-flex items-center gap-2">
          ${icon}
          <span class="inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold ${badgeClasses}">
            ${escapedStatus}
          </span>
        </div>
      </li>
    `
  }

  statusIcon(status) {
    if (status === "processing" || status === "pending") {
      return `<span class="inline-block h-3.5 w-3.5 animate-spin rounded-full border-2 border-zinc-300 border-t-accent" aria-hidden="true"></span>`
    }
    if (status === "processed") {
      return `<span class="inline-flex h-3.5 w-3.5 items-center justify-center text-emerald-600" aria-hidden="true">✓</span>`
    }
    if (status === "failed") {
      return `<span class="inline-flex h-3.5 w-3.5 items-center justify-center text-red-600" aria-hidden="true">!</span>`
    }
    return ""
  }

  stopTimer() {
    if (!this.timer) return
    clearTimeout(this.timer)
    this.timer = null
  }

  escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;")
  }
}
