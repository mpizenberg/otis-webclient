# otis - web client

[otis][otis]: outlining on touch device for image segmentation

This is the web client of the [otis web application][otis].
Please refer to it for installation, compilation and running.
It has two parts:

1. First is a minimalist express app (`index.js`).
   Its only purpose is to serve the index.html page of the web app,
   and the static site content (css, js, ...).
   It is plugged in the global otis web app as an express middleware.
2. Second is the frontend app (the interface in dir `src/`).
   It is done using the [elm] language, compiled to javascript.

> Remark: the elm frontend was initially based on this elm
> package [mpizenberg/elm-image-annotation][annotation],
> but due to many necessary additions not fit for the library,
> it is now a submodule dependency, corresponding to a specific commit.

[otis]: https://github.com/mpizenberg/otis
[elm]: http://elm-lang.org
[annotation]: https://github.com/mpizenberg/elm-image-annotation
