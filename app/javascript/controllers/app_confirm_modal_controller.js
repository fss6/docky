import { Controller } from "@hotwired/stimulus"

const CONFIRM_BUTTON_DANGER =
  "inline-flex w-full cursor-pointer items-center justify-center rounded-lg border border-red-200 bg-red-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-red-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"

const CONFIRM_BUTTON_PRIMARY =
  "inline-flex w-full cursor-pointer items-center justify-center rounded-lg border border-accent/40 bg-accent px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-accent-hover focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"

// Modal de confirmação reutilizável (ex.: desabilitar usuário, excluir pasta, excluir conversa).
// Gatilho: data-action="click->app-confirm-modal#open" e parâmetros data-app-confirm-modal-* no botão.
export default class extends Controller {
  static targets = ["dialog", "itemLabel", "heading", "bodyPrefix", "bodySuffix", "form", "confirmButton"]

  connect() {
    this.captureDefaults()
    if (this.hasFormTarget) {
      this._onSubmitEnd = (event) => this.submitEnd(event)
      this.formTarget.addEventListener("turbo:submit-end", this._onSubmitEnd)
      this.syncFormTurboMode({ dataset: {} })
    }
  }

  disconnect() {
    if (this.hasFormTarget && this._onSubmitEnd) {
      this.formTarget.removeEventListener("turbo:submit-end", this._onSubmitEnd)
    }
  }

  captureDefaults() {
    if (this.hasHeadingTarget) this._defaultHeading = this.headingTarget.textContent
    if (this.hasBodyPrefixTarget) this._defaultBodyPrefix = this.bodyPrefixTarget.textContent
    if (this.hasBodySuffixTarget) this._defaultBodySuffix = this.bodySuffixTarget.textContent
    if (this.hasConfirmButtonTarget) {
      this._defaultConfirmText = this.confirmButtonTarget.textContent
      this._defaultConfirmClass = this.confirmButtonTarget.className
    }
  }

  open(event) {
    event.preventDefault()
    event.stopPropagation()
    const btn = event.currentTarget
    const url = btn.dataset.appConfirmModalUrlParam
    const itemLabel = btn.dataset.appConfirmModalItemLabelParam || "—"
    if (this.hasItemLabelTarget) this.itemLabelTarget.textContent = itemLabel

    if (this.hasHeadingTarget) {
      if (btn.dataset.appConfirmModalHeadingParam !== undefined) {
        this.headingTarget.textContent = btn.dataset.appConfirmModalHeadingParam
      } else if (this._defaultHeading !== undefined) {
        this.headingTarget.textContent = this._defaultHeading
      }
    }
    if (this.hasBodyPrefixTarget) {
      if (btn.dataset.appConfirmModalBodyPrefixParam !== undefined) {
        this.bodyPrefixTarget.textContent = btn.dataset.appConfirmModalBodyPrefixParam
      } else if (this._defaultBodyPrefix !== undefined) {
        this.bodyPrefixTarget.textContent = this._defaultBodyPrefix
      }
    }
    if (this.hasBodySuffixTarget) {
      if (btn.dataset.appConfirmModalBodySuffixParam !== undefined) {
        this.bodySuffixTarget.textContent = btn.dataset.appConfirmModalBodySuffixParam
      } else if (this._defaultBodySuffix !== undefined) {
        this.bodySuffixTarget.textContent = this._defaultBodySuffix
      }
    }

    if (this.hasConfirmButtonTarget) {
      if (btn.dataset.appConfirmModalConfirmTextParam !== undefined) {
        this.confirmButtonTarget.textContent = btn.dataset.appConfirmModalConfirmTextParam
      } else if (this._defaultConfirmText !== undefined) {
        this.confirmButtonTarget.textContent = this._defaultConfirmText
      }
      const variant = btn.dataset.appConfirmModalConfirmVariantParam
      if (variant === "primary") {
        this.confirmButtonTarget.className = CONFIRM_BUTTON_PRIMARY
      } else if (variant === "danger") {
        this.confirmButtonTarget.className = CONFIRM_BUTTON_DANGER
      } else if (this._defaultConfirmClass !== undefined) {
        this.confirmButtonTarget.className = this._defaultConfirmClass
      }
    }

    const httpMethod = (btn.dataset.appConfirmModalHttpMethodParam || "delete").toLowerCase()
    if (this.hasFormTarget && url) {
      this.formTarget.action = url
      this.syncFormMethod(this.formTarget, httpMethod)
      this.syncFormTurboMode(btn)
    }

    if (this.hasDialogTarget) this.dialogTarget.showModal()
  }

  syncFormTurboMode(btn) {
    if (!this.hasFormTarget) return

    const useTurboStream = btn.dataset.appConfirmModalTurboStreamParam === "true"
    if (useTurboStream) {
      this.formTarget.dataset.turboStream = "true"
      delete this.formTarget.dataset.turboFrame
    } else {
      delete this.formTarget.dataset.turboStream
      this.formTarget.dataset.turboFrame = "_top"
    }
  }

  submitEnd(event) {
    if (event.detail.success) this.close()
  }

  syncFormMethod(form, method) {
    form.querySelectorAll('input[name="_method"]').forEach((el) => el.remove())
    form.setAttribute("method", "post")
    if (method === "delete" || method === "patch" || method === "put") {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "_method"
      input.value = method
      form.appendChild(input)
    }
  }

  close() {
    if (this.hasDialogTarget) this.dialogTarget.close()
  }

  backdropClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
