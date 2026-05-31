import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step",
    "stepIndicator",
    "templateCard",
    "skipCard",
    "previewPanel",
    "previewHeading",
    "previewList",
    "previewEmpty",
    "previewSkip",
    "onboardingError",
    "nextButton",
    "backButton",
    "submitButton",
    "onboardingInput",
    "step1Field"
  ]

  static values = {
    templates: Array,
    initialStep: { type: Number, default: 1 },
    selectedTemplateId: String
  }

  connect() {
    this.currentStep = this.initialStepValue
    this.showStep(this.currentStep)
    this._restoreSelection()
    this._updateSubmitLabel()
  }

  next(event) {
    event.preventDefault()
    this._syncTaxIdInputs()
    if (!this._validateStep1()) return

    this.currentStep = 2
    this.showStep(2)
  }

  back(event) {
    event.preventDefault()
    this.currentStep = 1
    this.showStep(1)
  }

  onboardingChanged(event) {
    const input = event.currentTarget
    if (!input.checked) return

    this._clearOnboardingError()

    if (input.value === "skipped") {
      this._clearTemplateSelection()
      this._highlightSkipCard()
      this._renderSkipPreview()
    } else {
      const card = input.closest("[data-template-id]")
      if (card) {
        this._highlightTemplateCard(card)
        this._clearSkipSelection()
        this._renderPreview(input.value)
      }
    }

    this._updateSubmitLabel()
  }

  submit(event) {
    if (this.currentStep === 1) {
      event.preventDefault()
      this._syncTaxIdInputs()
      if (!this._validateStep1()) return

      this.currentStep = 2
      this.showStep(2)
      return
    }

    this._syncTaxIdInputs()
    if (!this._validateStep1()) {
      event.preventDefault()
      this.showStep(1)
      return
    }

    if (!this._hasOnboardingSelection()) {
      event.preventDefault()
      this._showOnboardingError()
    }
  }

  showStep(step) {
    this.currentStep = step
    this.stepTargets.forEach((el) => {
      const stepNumber = Number(el.dataset.step)
      el.classList.toggle("hidden", stepNumber !== step)
    })

    this.stepIndicatorTargets.forEach((el) => {
      const stepNumber = Number(el.dataset.step)
      const active = stepNumber === step
      el.setAttribute("aria-current", active ? "step" : "false")
      el.classList.toggle("text-accent", active)
      el.classList.toggle("font-semibold", active)
      el.classList.toggle("text-zinc-500", !active)
    })

    this.nextButtonTarget.classList.toggle("hidden", step !== 1)
    this.backButtonTarget.classList.toggle("hidden", step !== 2)
    this.submitButtonTarget.classList.toggle("hidden", step !== 2)
  }

  _validateStep1() {
    let valid = true
    let firstInvalid = null

    const nameField = this._step1Field("client[name]")
    if (nameField && !nameField.value.trim()) {
      valid = false
      firstInvalid = firstInvalid || nameField
    }

    const taxHidden = this._step1Field("client[tax_id]")
    const taxDisplay = this.element.querySelector("[data-tax-id-input-target='display']")
    if (taxHidden) {
      const taxId = taxHidden.value.trim()
      if (taxId.length !== 11 && taxId.length !== 14) {
        valid = false
        firstInvalid = firstInvalid || taxDisplay || taxHidden
      }
    }

    const emailField = this._step1Field("client[email]")
    if (emailField) {
      const email = emailField.value.trim()
      if (!email || !this._validEmail(email)) {
        valid = false
        firstInvalid = firstInvalid || emailField
      }
    }

    if (!valid && firstInvalid) firstInvalid.focus()
    return valid
  }

  _step1Field(name) {
    return this.step1FieldTargets.find((field) => field.name === name)
  }

  _validEmail(value) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
  }

  _syncTaxIdInputs() {
    this.element.querySelectorAll('[data-controller~="tax-id-input"]').forEach((element) => {
      const controller = this.application.getControllerForElementAndIdentifier(element, "tax-id-input")
      controller?.sync()
    })
  }

  _hasOnboardingSelection() {
    return this.onboardingInputTargets.some((input) => input.checked)
  }

  _showOnboardingError() {
    const message = "Selecione um template de onboarding ou pule o onboarding."
    if (this.hasOnboardingErrorTarget) {
      this.onboardingErrorTarget.textContent = message
      this.onboardingErrorTarget.classList.remove("hidden")
    }
  }

  _clearOnboardingError() {
    if (this.hasOnboardingErrorTarget) {
      this.onboardingErrorTarget.textContent = ""
      this.onboardingErrorTarget.classList.add("hidden")
    }
  }

  _restoreSelection() {
    const selected = this.selectedTemplateIdValue
    if (!selected) return

    if (selected === "skipped") {
      this._checkOnboardingInput("skipped")
      this._highlightSkipCard()
      this._renderSkipPreview()
      return
    }

    this._checkOnboardingInput(selected)
    const card = this.templateCardTargets.find((el) => el.dataset.templateId === selected)
    if (card) {
      this._highlightTemplateCard(card)
      this._renderPreview(selected)
    }
  }

  _checkOnboardingInput(value) {
    this.onboardingInputTargets.forEach((input) => {
      input.checked = input.value === value
    })
  }

  _highlightTemplateCard(card) {
    this.templateCardTargets.forEach((el) => {
      el.classList.remove("onboarding-radio-selected")
      el.classList.add("onboarding-radio-default")
    })
    card.classList.remove("onboarding-radio-default")
    card.classList.add("onboarding-radio-selected")
  }

  _highlightSkipCard() {
    if (!this.hasSkipCardTarget) return
    this.skipCardTarget.classList.remove("onboarding-radio-default")
    this.skipCardTarget.classList.add("onboarding-radio-selected")
  }

  _clearTemplateSelection() {
    this.templateCardTargets.forEach((el) => {
      el.classList.remove("onboarding-radio-selected")
      el.classList.add("onboarding-radio-default")
    })
  }

  _clearSkipSelection() {
    if (!this.hasSkipCardTarget) return
    this.skipCardTarget.classList.remove("onboarding-radio-selected")
    this.skipCardTarget.classList.add("onboarding-radio-default")
  }

  _renderPreview(templateId) {
    const template = this.templatesValue.find((t) => t.id.toString() === templateId.toString())
    if (!template || !this.hasPreviewPanelTarget) return

    this.previewPanelTarget.classList.remove("hidden")
    if (this.hasPreviewSkipTarget) this.previewSkipTarget.classList.add("hidden")
    if (this.hasPreviewEmptyTarget) this.previewEmptyTarget.classList.add("hidden")
    if (this.hasPreviewListTarget) this.previewListTarget.classList.remove("hidden")

    if (this.hasPreviewHeadingTarget) {
      this.previewHeadingTarget.textContent = template.name
    }

    if (this.hasPreviewListTarget) {
      this.previewListTarget.innerHTML = template.items
        .map(
          (item, index) => `
            <li class="flex gap-3 py-2">
              <span class="mt-0.5 inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-zinc-100 text-xs font-semibold text-zinc-600">${index + 1}</span>
              <span>
                <span class="block text-sm font-medium text-zinc-900">${this._escapeHtml(item.name)}</span>
                ${item.help_text ? `<span class="mt-0.5 block text-xs text-zinc-500">${this._escapeHtml(item.help_text)}</span>` : ""}
              </span>
            </li>`
        )
        .join("")
    }
  }

  _renderSkipPreview() {
    if (!this.hasPreviewPanelTarget) return

    this.previewPanelTarget.classList.remove("hidden")
    if (this.hasPreviewListTarget) {
      this.previewListTarget.innerHTML = ""
      this.previewListTarget.classList.add("hidden")
    }
    if (this.hasPreviewEmptyTarget) this.previewEmptyTarget.classList.add("hidden")
    if (this.hasPreviewSkipTarget) this.previewSkipTarget.classList.remove("hidden")
  }

  _updateSubmitLabel() {
    if (!this.hasSubmitButtonTarget) return

    const selected = this.onboardingInputTargets.find((input) => input.checked)
    if (!selected || selected.value === "skipped") {
      this.submitButtonTarget.value = this.submitButtonTarget.dataset.skipLabel
    } else {
      this.submitButtonTarget.value = this.submitButtonTarget.dataset.onboardingLabel
    }
  }

  _escapeHtml(value) {
    return value
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
