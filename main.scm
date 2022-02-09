(use rfc.http)
(use rfc.json)
(use sjsonpath)
(use dbi)
(use makiki)

(define (get-book-data isbn)
  (receive (status head body)
    (http-get "www.googleapis.com"
      (string-append
        "/books/v1/volumes"
        "?q=isbn:"
        isbn)
      :secure #t)
    (parse-json-string body)))

(define title (sjsonpath "$.items[0].volumeInfo.title"))
(define image (sjsonpath "$.items[0].volumeInfo.imageLinks.thumbnail"))
(define authors (sjsonpath "$.items[0].volumeInfo.authors[0]"))
(define published-date (sjsonpath "$.items[0].volumeInfo.publishedDate"))

(define (get-by-isbn con isbn)
  (dbi-do con #"SELECT * from book where (isbn = '~|isbn|');"))

(define-http-handler "/"
  (^[req app] (respond/ok req "<h1>It worked!</h1>")))

;; GET: /api/books/{isbn}/post
(define-http-handler #/\/api\/books\/(\d+)\/post/
  (^[req app]
    (let-params req ([isbn "p:1"])
      (let*
        ((data (get-book-data isbn))
        (con (dbi-connect "dbi:sqlite:shelf.sqlite"))
        [insert (dbi-prepare con "INSERT INTO book VALUES (?, ?, ?, ?, ?);")])
        (unwind-protect (begin
          (dbi-execute insert
            isbn
            (car (title data))
            (car (image data))
            (car (authors data))
            (car (published-date data))))
          (dbi-close con)))
      (respond/ok req "ok"))))

(define-http-handler #/\/api\/books\/(\d+)\/get/
  (^[req app]
    (let-params req ([isbn "p:1"])
      (let* ((con (dbi-connect "dbi:sqlite:shelf.sqlite"))
              (result (get-by-isbn con isbn))
              [getter (relation-accessor result)])
        (unwind-protect (begin
          (respond/ok req (map (^r
            (format #f
              "{isbn: ~s, title: ~s, image: ~s, authors: ~s, publishedDate: ~s}"
              (getter r "isbn")
              (getter r "title")
              (getter r "image")
              (getter r "authors")
              (getter r "publishedDate")))
            (relation-rows result))))
          (dbi-close con))))))

(define (main args) (start-http-server :port 6789 :error-log #t :access-log #t))
