import { Controller } from "@hotwired/stimulus"

/** Pixels from bottom to consider the user “following” new messages (streaming). */
const NEAR_BOTTOM_PX = 140

export default class extends Controller {
  static targets = ["input", "messages", "form"]

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
  }

  disconnect() {
    this.messagesTarget.removeEventListener("scroll", this.boundScrollPin)
    this.mutationObserver.disconnect()
    document.removeEventListener("turbo:load", this.boundTurboLoad)
    window.removeEventListener("pageshow", this.boundPageShow)
  }

  submit(event) {
    event.preventDefault()
    const text = this.inputTarget.value.trim()
    if (!text) return

    this.formTarget.requestSubmit()
    this.inputTarget.value = ""
    this.resize()
  }

  resize() {
    const el = this.inputTarget
    el.style.height = "auto"
    el.style.height = Math.min(el.scrollHeight, 160) + "px"
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

  keydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.submit(event)
    }
  }
}
