// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "channels"

let turboAfterStreamRenderTimer = null
const turboAfterStreamRenderEvent = new Event("turbo:after-stream-render")

document.addEventListener("turbo:before-stream-render", (event) => {
  const originalRender = event.detail.render

  event.detail.render = function (streamElement) {
    originalRender(streamElement)
    clearTimeout(turboAfterStreamRenderTimer)
    turboAfterStreamRenderTimer = setTimeout(() => {
      document.dispatchEvent(turboAfterStreamRenderEvent)
    }, 0)
  }
})
