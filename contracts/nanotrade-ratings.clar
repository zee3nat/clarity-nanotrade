;; Rating system functions 
(define-map ratings
  { user: principal }
  { 
    total-rating: uint,
    count: uint
  }
)

;; Track rating history to prevent duplicates
(define-map rating-history
  { rater: principal, rated: principal }
  { rating: uint }
)

;; Constants
(define-constant err-invalid-rating (err u106))
(define-constant err-self-rating (err u107))
(define-constant err-duplicate-rating (err u108))

(define-public (rate-user (user principal) (rating uint))
  (begin
    ;; Validate rating value
    (asserts! (<= rating u5) err-invalid-rating)
    ;; Prevent self-rating
    (asserts! (not (is-eq tx-sender user)) err-self-rating)
    ;; Check for duplicate rating
    (asserts! (is-none (map-get? rating-history 
      { rater: tx-sender, rated: user })) 
      err-duplicate-rating)
    
    (let ((current-rating (default-to 
      { total-rating: u0, count: u0 } 
      (map-get? ratings {user: user}))))
      
      ;; Store rating history
      (map-set rating-history 
        { rater: tx-sender, rated: user }
        { rating: rating }
      )
      
      ;; Update user rating
      (map-set ratings
        {user: user}
        {
          total-rating: (+ (get total-rating current-rating) rating),
          count: (+ (get count current-rating) u1)
        }
      )
      (ok true))))

(define-read-only (get-user-rating (user principal))
  (let ((rating (map-get? ratings {user: user})))
    (if (is-some rating)
      (let ((unwrapped (unwrap-panic rating)))
        (ok {
          average: (/ (get total-rating unwrapped) (get count unwrapped)),
          count: (get count unwrapped)
        }))
      (ok {
        average: u0,
        count: u0
      }))))
