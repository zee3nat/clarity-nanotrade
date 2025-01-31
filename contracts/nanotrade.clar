;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-listed (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-invalid-price (err u104))
(define-constant err-invalid-royalty (err u105))

;; Data structures
(define-map listings
  { id: uint }
  {
    seller: principal,
    price: uint,
    description: (string-utf8 256),
    is-active: bool,
    royalty-percent: uint
  }
)

(define-map ratings
  { user: principal }
  { 
    total-rating: uint,
    count: uint
  }
)

;; Storage
(define-data-var listing-nonce uint u0)

;; Private functions
(define-private (validate-listing (price uint) (royalty uint))
  (begin
    (asserts! (> price u0) (err err-invalid-price))
    (asserts! (<= royalty u100) (err err-invalid-royalty))
    (ok true)))

;; Public functions
(define-public (list-innovation (price uint) (description (string-utf8 256)) (royalty uint))
  (let ((listing-id (var-get listing-nonce)))
    (try! (validate-listing price royalty))
    (map-set listings
      { id: listing-id }
      {
        seller: tx-sender,
        price: price,
        description: description,
        is-active: true,
        royalty-percent: royalty
      }
    )
    (var-set listing-nonce (+ listing-id u1))
    (ok listing-id)))

(define-public (purchase-innovation (listing-id uint))
  (let (
    (listing (unwrap! (map-get? listings {id: listing-id}) (err err-not-found)))
    (price (get price listing))
  )
    (asserts! (get is-active listing) (err err-not-found))
    (try! (stx-transfer? price tx-sender (get seller listing)))
    (map-set listings
      { id: listing-id }
      (merge listing { is-active: false })
    )
    (ok true)))

(define-read-only (get-listing (listing-id uint))
  (map-get? listings {id: listing-id}))
