;; Rating system functions 
(define-public (rate-user (user principal) (rating uint))
  (begin
    (asserts! (<= rating u5) (err u106))
    (let ((current-rating (default-to 
      { total-rating: u0, count: u0 } 
      (map-get? ratings {user: user}))))
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
        (ok (tuple 
          (average (/ (get total-rating unwrapped) (get count unwrapped)))
          (count (get count unwrapped))
        )))
      (ok (tuple (average u0) (count u0))))))
