import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event.preventDefault()
    const dialogKey = event.params.dialog
    const dialog = dialogKey
      ? this.dialogTargets.find((el) => el.dataset.modalKey === dialogKey)
      : this.dialogTarget
    if (dialog) dialog.showModal()
  }

  close() {
    this.closeOpenDialog()
  }

  backdropClick(event) {
    if (this.dialogTargets.includes(event.target)) this.close()
  }

  closeOnSuccess(event) {
    if (event.detail.success) this.closeOpenDialog()
  }

  closeOpenDialog() {
    this.dialogTargets.forEach((dialog) => {
      if (dialog.open) dialog.close()
    })
  }
}
