import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = {
    clientId: Number,
    documentsUrl: String,
    activeTab: String
  }

  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "ClientDocumentsChannel", client_id: this.clientIdValue },
      {
        received: (data) => this.received(data)
      }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
  }

  received(data) {
    if (data?.event !== "document_created") return

    this.element.dispatchEvent(new CustomEvent("client-document:created", { bubbles: true }))

    const badge = document.querySelector("[data-client-tab-badge]")
    if (badge) badge.classList.add("client-tab-badge--pulse")

    if (this.activeTabValue === "documentos" && this.hasDocumentsUrlValue) {
      fetch(this.documentsUrlValue, { headers: { Accept: "text/vnd.turbo-stream.html, text/html" } })
        .then((r) => r.text())
        .then((html) => {
          if (html.includes("turbo-stream")) {
            Turbo.renderStreamMessage(html)
            document.dispatchEvent(new CustomEvent("docfy:process-toasts"))
          }
        })
        .catch(() => {})
    }
  }
}
