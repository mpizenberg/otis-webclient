# otis - web client

[otis][otis]: outlining on touch device for image segmentation

> [1] Outlining Objects for Interactive Segmentation on Touch Devices. 2017.
> Matthieu Pizenberg, Axel Carlier, Emmanuel Faure, Vincent Charvillat.
> In Proceedings of the 25th ACM International Conference on multimedia (MM'17).
> DOI: https://doi.org/10.1145/3123266.3123409

This is the web client of the [otis application][otis] so please
cite the aforementioned paper if used in a research work.
Please refer to it for installation, compilation and running.
It has two parts:

1. First is a minimalist express app (`index.js`).
   Its only purpose is to serve the index.html page of the web app,
   and the static site content (css, js, ...).
   It is plugged in the global otis web app as an express middleware.
2. Second is the frontend app (`src/` directory).
   It is done using the [elm] language, compiled to javascript.

> Remark: the elm frontend was initially based on this elm
> package [mpizenberg/elm-image-annotation][annotation],
> but due to many necessary additions not fit for the library,
> it is now a submodule dependency, corresponding to a specific commit.

[otis]: https://github.com/mpizenberg/otis
[elm]: http://elm-lang.org
[annotation]: https://github.com/mpizenberg/elm-image-annotation

## License

This part of the otis application is licensed under MPL-2.0.
