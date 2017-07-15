const express = require('express')
const app = module.exports = express()
const path = require('path')
const compression = require('compression')


// Middlewares
app.use( compression() ) // gzip


// Serve statically the dist/ directory (build artefact)
app.use( express.static( path.join(__dirname, 'dist' ) ) )


// Serve elm index.html
app.get( '/', ( req, res ) => {
	res.sendFile( path.join( __dirname, 'src', 'index.html' ) )
})
