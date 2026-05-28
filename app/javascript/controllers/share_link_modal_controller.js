import { Controller } from "@hotwired/stimulus"
import { showError, showSuccess } from "notyf_instance"

export default class extends Controller {
  static targets = ["dialog", "content"]
  static values = {
    createUrl: String,
    hasInvite: Boolean
  }

  connect() {
    this.boundPageShow = (event) => {
      if (event.persisted) this.syncHasInviteFromDom()
    }
    window.addEventListener("pageshow", this.boundPageShow)
  }

  disconnect() {
    window.removeEventListener("pageshow", this.boundPageShow)
  }

  async open(event) {
    event.preventDefault()

    this.syncHasInviteFromDom()
    this.dialogTarget.showModal()

    if (this.hasInviteValue && this.hasContent()) return

    const isFirstGeneration = !this.hasInviteValue

    try {
      await this.ensureInvite()
      this.hasInviteValue = true
      if (isFirstGeneration) showSuccess(this.inviteSuccessMessage())
    } catch (error) {
      console.error("[share-link-modal]", error)
      showError("Não foi possível gerar o link. Recarregue a página e tente novamente.")
      this.hasInviteValue = false
    }
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  async ensureInvite() {
    this.setLoadingState()

    const url = this.createUrlValue
    const token = this.csrfToken
    if (!token) throw new Error("missing csrf token")

    const response = await fetch(url, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": token
      },
      body: new URLSearchParams({ authenticity_token: token }),
      credentials: "same-origin"
    })

    if (!response.ok) {
      throw new Error(`create invite failed (${response.status})`)
    }

    const { html, invitesHtml } = await this.responsePayload(response)
    this.replaceElementWithHtml("share_link_modal_content", html)
    if (invitesHtml) this.replaceElementWithHtml("client_upload_invites_panel", invitesHtml)

    const ready = await this.waitForContent()
    if (!ready) throw new Error("modal content not updated")
  }

  replaceElementWithHtml(id, html) {
    const container = document.getElementById(id)
    if (!container) return

    const doc = new DOMParser().parseFromString(html, "text/html")
    const replacement =
      doc.getElementById(id) ||
      doc.body.firstElementChild

    if (!replacement) throw new Error(`invalid replacement html for #${id}`)

    container.replaceWith(replacement)
  }

  async responsePayload(response) {
    const contentType = response.headers.get("content-type") || ""

    if (contentType.includes("application/json")) {
      const data = await response.json()
      if (!data?.html) throw new Error("invalid json response")
      return { html: data.html, invitesHtml: data.invites_html }
    }

    const text = await response.text()
    if (text.includes("turbo-stream")) {
      return {
        html: this.htmlFromTurboStream(text, "share_link_modal_content"),
        invitesHtml: this.htmlFromTurboStream(text, "client_upload_invites_panel", false)
      }
    }

    return { html: text }
  }

  htmlFromTurboStream(text, targetId, required = true) {
    const doc = new DOMParser().parseFromString(text, "text/html")
    const stream = doc.querySelector(`turbo-stream[target='${targetId}']`)
    const template = stream?.querySelector("template")
    if (!template) {
      if (required) throw new Error(`invalid turbo stream response for #${targetId}`)
      return null
    }

    return template.innerHTML
  }

  async waitForContent(attempts = 15) {
    for (let i = 0; i < attempts; i += 1) {
      if (this.hasContent()) return true
      await this.nextFrame()
    }
    return false
  }

  setLoadingState() {
    const container = document.getElementById("share_link_modal_content")
    if (!container) return

    container.innerHTML = '<p class="text-sm text-zinc-500">Gerando link…</p>'
  }

  hasContent() {
    const root = document.getElementById("share_link_modal_content")
    if (!root) return false

    return Boolean(root.querySelector("[data-copy-link-target='source']"))
  }

  syncHasInviteFromDom() {
    const raw = this.element.getAttribute("data-share-link-modal-has-invite-value")
    this.hasInviteValue = raw === "true"
  }

  inviteSuccessMessage() {
    const url = this.createUrlValue || ""
    if (url.includes("onboarding_upload_invites")) {
      return "Link de onboarding gerado."
    }
    return "Link gerado com sucesso."
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  nextFrame() {
    return new Promise((resolve) => requestAnimationFrame(resolve))
  }
}
