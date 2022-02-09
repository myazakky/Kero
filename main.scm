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

(define title (sjsonpath "$.voklumeInfo.title"))
(define image (sjsonpath "$.voklumeInfo.imageLinks.Large"))
(define authors (sjsonpath "$.voklumeInfo.authors"))
(define published-date (sjsonpath "$.volumeInfo.publishedDate"))

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
            (title data)
            (image data)
            (authors data)
            (published-date data)))
          (dbi-close con)))
      (respond/ok req "ok"))))

(define (main args) (start-http-server :port 6789 :error-log #t :access-log #t))
