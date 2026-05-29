import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["shell", "backdrop", "panel", "frame"]
  static values = {
    emptyUrl: String,
    clientUrl: String
  }

  static animationMs = 300

  connect() {
    this.boundKeydown = this.keydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)

    if (!this.hasShellTarget) return

    if (this.shellTarget.classList.contains("hidden")) {
      document.body.classList.remove("overflow-hidden")
      this.setClosedVisualState()
    } else if (this.hasFrameTarget && !this.isFrameEmpty()) {
      this.setOpenVisualState()
      document.body.classList.add("overflow-hidden")
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
    document.body.classList.remove("overflow-hidden")
  }

  closeShell() {
    if (!this.hasShellTarget || this.shellTarget.classList.contains("hidden")) return

    if (this.prefersReducedMotion) {
      this.finalizeClose()
      return
    }

    this.setClosedVisualState()

    window.setTimeout(() => this.finalizeClose(), this.constructor.animationMs)
  }

  openShell() {
    if (!this.hasShellTarget) return

    this.shellTarget.classList.remove("hidden", "pointer-events-none")
    this.shellTarget.setAttribute("aria-hidden", "false")
    document.body.classList.add("overflow-hidden")

    if (this.prefersReducedMotion) {
      this.setOpenVisualState()
      return
    }

    this.setClosedVisualState()

    requestAnimationFrame(() => {
      requestAnimationFrame(() => this.setOpenVisualState())
    })
  }

  frameLoaded() {
    if (this.isFrameEmpty()) {
      this.closeShell()
      return
    }

    this.openShell()
    this.syncFolderUrl()
  }

  backdropClick(event) {
    if (event.target !== this.backdropTarget) return

    this.navigateToEmpty()
  }

  keydown(event) {
    if (event.key !== "Escape") return
    if (!this.hasShellTarget || this.shellTarget.classList.contains("hidden")) return

    event.preventDefault()
    this.navigateToEmpty()
  }

  navigateToEmpty() {
    if (!this.hasFrameTarget || !this.hasEmptyUrlValue) return

    this.frameTarget.src = this.emptyUrlValue
  }

  isFrameEmpty() {
    if (!this.hasFrameTarget) return true

    return this.frameTarget.innerHTML.trim() === ""
  }

  syncFolderUrl() {
    const folderId = this.frameTarget.querySelector("[data-folder-id]")?.dataset.folderId
    if (!folderId || !this.hasClientUrlValue) return

    const url = new URL(this.clientUrlValue, window.location.origin)
    url.searchParams.set("folder_id", folderId)
    history.replaceState({}, "", url.toString())
  }

  syncClientUrl() {
    if (!this.hasClientUrlValue) return

    history.replaceState({}, "", this.clientUrlValue)
  }

  finalizeClose() {
    if (!this.hasShellTarget) return

    this.shellTarget.classList.add("hidden", "pointer-events-none")
    this.shellTarget.setAttribute("aria-hidden", "true")
    document.body.classList.remove("overflow-hidden")
    this.syncClientUrl()
  }

  setOpenVisualState() {
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("opacity-0")
      this.backdropTarget.classList.add("opacity-100")
    }
    if (this.hasPanelTarget) {
      this.panelTarget.classList.remove("translate-x-full")
      this.panelTarget.classList.add("translate-x-0")
    }
  }

  setClosedVisualState() {
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("opacity-100")
      this.backdropTarget.classList.add("opacity-0")
    }
    if (this.hasPanelTarget) {
      this.panelTarget.classList.remove("translate-x-0")
      this.panelTarget.classList.add("translate-x-full")
    }
  }

  get prefersReducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
