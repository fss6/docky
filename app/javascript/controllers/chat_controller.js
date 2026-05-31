import { Controller } from "@hotwired/stimulus"

/** Pixels from bottom to consider the user “following” new messages (streaming). */
const NEAR_BOTTOM_PX = 140

/** Single-line composer height; grows only up to this cap (≈4 lines). */
const INPUT_MIN_HEIGHT_PX = 36
const INPUT_MAX_HEIGHT_PX = 96

export default class extends Controller {
  static targets = ["input", "messages", "form", "emptyState"]

  connect() {
    this.pinnedToBottom = true
    this.scheduleScrollToBottom()

    this.boundScrollPin = () => {
      this.pinnedToBottom = this.isNearBottom()
    }
    this.messagesTarget.addEventListener("scroll", this.boundScrollPin, { passive: true })

    this.scrollFramePending = false
    this.boundMutation = () => {
      if (!this.pinnedToBottom) return
      this.requestScrollFrame()
    }
    this.mutationObserver = new MutationObserver(this.boundMutation)
    this.mutationObserver.observe(this.messagesTarget, {
      childList: true,
      subtree: true,
      characterData: true
    })

    this.boundTurboLoad = () => {
      if (this.hasMessagesTarget) this.scheduleScrollToBottom()
    }
    document.addEventListener("turbo:load", this.boundTurboLoad)
    this.boundPageShow = (event) => {
      if (event.persisted && this.hasMessagesTarget) this.scheduleScrollToBottom()
    }
    window.addEventListener("pageshow", this.boundPageShow)

    this.boundAfterStreamRender = () => this.onAfterStreamRender()
    document.addEventListener("turbo:after-stream-render", this.boundAfterStreamRender)

    if (this.hasInputTarget) this.resetInputHeight()
  }

  disconnect() {
    this.messagesTarget.removeEventListener("scroll", this.boundScrollPin)
    this.mutationObserver.disconnect()
    document.removeEventListener("turbo:load", this.boundTurboLoad)
    window.removeEventListener("pageshow", this.boundPageShow)
    document.removeEventListener("turbo:after-stream-render", this.boundAfterStreamRender)
  }

  onAfterStreamRender() {
    if (this.hasInputTarget) this.resetInputHeight()
    if (this.pinnedToBottom) this.requestScrollFrame()
  }

  submit(event) {
    event.preventDefault()
    const text = this.inputTarget.value.trim()
    if (!text) return

    this.removeEmptyState()
    this.formTarget.requestSubmit()
    this.inputTarget.value = ""
    this.resetInputHeight()
  }

  applyPrompt(event) {
    const prompt = event.currentTarget.dataset.chatPrompt || ""
    if (!prompt) return

    this.inputTarget.value = prompt
    this.resize()
    this.inputTarget.focus()
    this.inputTarget.setSelectionRange(this.inputTarget.value.length, this.inputTarget.value.length)
  }

  resetInputHeight() {
    const el = this.inputTarget
    el.style.height = `${INPUT_MIN_HEIGHT_PX}px`
    el.style.overflowY = "hidden"
  }

  resize() {
    const el = this.inputTarget
    const value = el.value

    if (!value.includes("\n") && value.length < 80) {
      this.resetInputHeight()
      return
    }

    el.style.height = "auto"
    const next = Math.min(Math.max(el.scrollHeight, INPUT_MIN_HEIGHT_PX), INPUT_MAX_HEIGHT_PX)
    el.style.height = `${next}px`
    el.style.overflowY = el.scrollHeight > INPUT_MAX_HEIGHT_PX ? "auto" : "hidden"
  }

  isNearBottom() {
    const el = this.messagesTarget
    return el.scrollHeight - el.scrollTop - el.clientHeight < NEAR_BOTTOM_PX
  }

  requestScrollFrame() {
    if (this.scrollFramePending) return
    this.scrollFramePending = true
    requestAnimationFrame(() => {
      this.scrollFramePending = false
      this.applyScrollToBottom()
    })
  }

  scheduleScrollToBottom() {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.applyScrollToBottom()
        requestAnimationFrame(() => this.applyScrollToBottom())
      })
    })
  }

  applyScrollToBottom() {
    if (!this.hasMessagesTarget) return
    const el = this.messagesTarget
    el.scrollTop = el.scrollHeight
    const last = el.lastElementChild
    if (last) {
      last.scrollIntoView({ block: "end", behavior: "auto" })
    }
    this.pinnedToBottom = true
  }

  removeEmptyState() {
    if (!this.hasEmptyStateTarget) return
    this.emptyStateTarget.remove()
  }

  keydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.submit(event)
    }
  }
}
