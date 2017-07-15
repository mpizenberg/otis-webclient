const app = Elm.Main.fullscreen()

// Warn potential loose of annotations on page refresh
window.addEventListener("beforeunload", function (event) {
	const warningMessage = "If you refresh, you will loose all you annotations!"
	event.returnValue = warningMessage // Gecko, Trident, Chrome 34+
	return warningMessage // Gecko, WebKit, Chrome < 34
})
