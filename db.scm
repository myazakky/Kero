(use dbi)

(define (create-table)
  (let1 con (dbi-connect "dbi:sqlite:shelf.sqlite")
    (unwind-protect (begin 
      (dbi-do con "CREATE TABLE book (isbn PRIMARY KEY, title, image, authors, publishedDate)"))
      (dbi-close con))))

(create-table)
