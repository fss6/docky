import { Notyf } from "notyf"

let instance

function getNotyf() {
  if (!instance) {
    instance = new Notyf({
      duration: 5000,
      dismissible: true,
      ripple: false,
      position: { x: "right", y: "top" },
      types: [
        {
          type: "success",
          className: "notyf__toast--success",
          backgroundColor: "#f0fdfa",
          icon: { className: "notyf__icon--success", tagName: "i" }
        },
        {
          type: "error",
          className: "notyf__toast--error",
          backgroundColor: "#fef2f2",
          icon: { className: "notyf__icon--error", tagName: "i" }
        }
      ]
    })
  }
  return instance
}

export function showSuccess(message) {
  if (!message) return
  getNotyf().success(message)
}

export function showError(message) {
  if (!message) return
  getNotyf().error(message)
}

export function showToast({ type = "success", message }) {
  if (!message) return
  if (type === "error") {
    showError(message)
  } else {
    showSuccess(message)
  }
}
