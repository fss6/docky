import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subjectSource", "bodySource", "subjectField", "bodyField"]

  sync() {
    if (this.hasSubjectSourceTarget && this.hasSubjectFieldTarget) {
      this.subjectFieldTarget.value = this.subjectSourceTarget.value
    }

    if (this.hasBodySourceTarget && this.hasBodyFieldTarget) {
      this.bodyFieldTarget.value = this.bodySourceTarget.value
    }
  }
}
