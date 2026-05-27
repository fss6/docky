import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template", "item", "position", "destroy"]

  connect() {
    this.draggedItem = null
    this.dragEnabled = false
    this.refreshPositions()
  }

  itemTargetConnected(element) {
    element.draggable = true
    element.addEventListener("dragstart", this.dragStart)
    element.addEventListener("dragover", this.dragOver)
    element.addEventListener("drop", this.drop)
    element.addEventListener("dragend", this.dragEnd)
  }

  itemTargetDisconnected(element) {
    element.removeEventListener("dragstart", this.dragStart)
    element.removeEventListener("dragover", this.dragOver)
    element.removeEventListener("drop", this.drop)
    element.removeEventListener("dragend", this.dragEnd)
  }

  add() {
    const id = Date.now().toString()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", id)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.refreshPositions()
  }

  remove(event) {
    const item = event.currentTarget.closest("[data-nested-sortable-list-target~='item']")
    const destroyInput = item.querySelector("[data-nested-sortable-list-target~='destroy']")
    const idInput = item.querySelector("input[name$='[id]']")

    if (idInput && idInput.value) {
      destroyInput.value = "1"
      item.classList.add("hidden")
    } else {
      item.remove()
    }

    this.refreshPositions()
  }

  startDragHandle(event) {
    this.dragEnabled = true
    event.currentTarget.classList.add("cursor-grabbing")
  }

  endDragHandle(event) {
    this.dragEnabled = false
    event.currentTarget.classList.remove("cursor-grabbing")
  }

  dragStart = (event) => {
    if (!this.dragEnabled) {
      event.preventDefault()
      return
    }

    this.draggedItem = event.currentTarget
    event.currentTarget.classList.add("opacity-50")
    event.dataTransfer.effectAllowed = "move"
  }

  dragOver = (event) => {
    event.preventDefault()
    const target = event.currentTarget

    if (!this.draggedItem || target === this.draggedItem || this.isDestroyed(target)) return

    const rect = target.getBoundingClientRect()
    const shouldInsertAfter = event.clientY > rect.top + rect.height / 2

    if (shouldInsertAfter) {
      target.after(this.draggedItem)
    } else {
      target.before(this.draggedItem)
    }
  }

  drop = (event) => {
    event.preventDefault()
    this.refreshPositions()
  }

  dragEnd = (event) => {
    event.currentTarget.classList.remove("opacity-50")
    this.dragEnabled = false
    this.draggedItem = null
    this.refreshPositions()
  }

  refreshPositions() {
    this.itemTargets
      .filter((item) => !this.isDestroyed(item))
      .forEach((item, index) => {
        const input = item.querySelector("[data-nested-sortable-list-target~='position']")
        if (input) input.value = index
      })
  }

  isDestroyed(item) {
    const destroyInput = item.querySelector("[data-nested-sortable-list-target~='destroy']")
    return destroyInput?.value === "1" || item.classList.contains("hidden")
  }
}
