app.ports.askContentSize.subscribe( () => {
	window.requestAnimationFrame( () => {
		askClientSize ( "content", app.ports.contentSize )
	})
})


app.ports.fetchTrainImage.subscribe( ([tool, url]) => {
	loadImage( tool, url, app.ports.trainImageFetched )
})


app.ports.fetchImage.subscribe( ([tool, url]) => {
	loadImage( tool, url, app.ports.imageFetched )
})


app.ports.displayGroundtruth.subscribe( ([tagId, gt]) => {
	window.requestAnimationFrame( () => {
		putCanvas( tagId, makeCanvas(gt) )
	})
})


function askClientSize( tagId, outPort ) {
	const tag = document.getElementById(tagId)
	outPort.send([tag.clientWidth, tag.clientHeight])
}


function loadImage( tool, url, outPort ) {
	const request = new XMLHttpRequest()
	request.onload = () => {
		const image = new Image()
		const blobUrl = URL.createObjectURL(request.response)
		image.onload = () => {
			const width = image.naturalWidth
			const height = image.naturalHeight
			outPort.send([tool, url, blobUrl, [width, height]])
		}
		image.src = blobUrl
	}
	request.open("GET", url)
	request.responseType = "blob"
	request.send(null)
}


// Groundtruth canvas displaying


function makeCanvas(gt) {
	const canvas = document.createElement('canvas')
	canvas.width = gt.width
	canvas.height = gt.height

	const ctx = canvas.getContext('2d')
	const imageData = dataFromBoolArray( gt.width, gt.height, gt.data )
	ctx.putImageData( imageData, 0, 0 )
	return canvas
}


function putCanvas( tagId, canvas ) {
	const url = canvas.toDataURL()
	const svgImg = document.getElementById(tagId)
	svgImg.textContent = "groundtruth"
	const XLink_NS = 'http://www.w3.org/1999/xlink'
	svgImg.setAttributeNS( XLink_NS, 'href', url )
}


function dataFromBoolArray( width, height, gtData ) {
	const length = width * height
	const dataArray = new Uint8ClampedArray(4*length)
	for (i = 0; i < length; i++) {
		const visible = gtData[i] ? 255 : 0
		dataArray[4*i] = visible // RED
		dataArray[4*i + 1] = 0
		dataArray[4*i + 2] = 0
		dataArray[4*i + 3] = visible // ALPHA
	}
	return new ImageData(dataArray, width, height)
}
