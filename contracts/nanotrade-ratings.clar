;; Rating system functions 
(define-map ratings
  { user: principal }
  { 
    total-rating: uint,
    count: uint,
    average: uint  ;; Stored as number * 100 for 2 decimal precision
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
(define-constant min-rating u1)
(define-constant max-rating u5)
(define-constant precision-factor u100)

(define-public (rate-user (user principal) (rating uint))
  (begin
    ;; Validate rating value
    (asserts! (and (>= rating min-rating) (<= rating max-rating)) err-invalid-rating)
    ;; Prevent self-rating
    (asserts! (not (is-eq tx-sender user)) err-self-rating)
    ;; Check for duplicate rating
    (asserts! (is-none (map-get? rating-history 
      { rater: tx-sender, rated: user })) 
      err-duplicate-rating)
    
    (let ((current-rating (default-to 
      { total-rating: u0, count: u0, average: u0 } 
      (map-get? ratings {user: user}))))
      
      ;; Store rating history
      (map-set rating-history 
        { rater: tx-sender, rated: user }
        { rating: rating }
      )
      
      ;; Calculate new total and average
      (let (
        (new-total (+ (get total-rating current-rating) rating))
        (new-count (+ (get count current-rating) u1))
        (new-average (* (/ new-total new-count) precision-factor))
      )
        ;; Update user rating
        (map-set ratings
          {user: user}
          {
            total-rating: new-total,
            count: new-count,
            average: new-average
          }
        )
        (ok true))))

(define-read-only (get-user-rating (user principal))
  (let ((rating (map-get? ratings {user: user})))
    (if (is-some rating)
      (let ((unwrapped (unwrap-panic rating)))
        (ok {
          average: (get average unwrapped),
          count: (get count unwrapped)
        }))
      (ok {
        average: u0,
        count: u0
      }))))
