(lang dune 3.0)

(name wcec-dvk)

(generate_opam_files false)

(source
 (github username/reponame))

(authors "Author Name")

(maintainers "Maintainer Name")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name wcec-dvk)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml dune)
 (tags
  (topics "to describe" your project)))

(using menhir 2.1)


; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
