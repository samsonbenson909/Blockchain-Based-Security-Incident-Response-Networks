;; Incident Commander Verification Contract
;; Manages verification and authorization of incident commanders

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Commander status types
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_SUSPENDED u2)
(define-constant STATUS_REVOKED u3)

;; Data structures
(define-map commanders
  { commander: principal }
  {
    status: uint,
    verification-date: uint,
    certifications: (string-ascii 500),
    experience-level: uint,
    verified-by: principal
  }
)

(define-map commander-stats
  { commander: principal }
  {
    incidents-handled: uint,
    success-rate: uint,
    last-active: uint
  }
)

(define-data-var total-commanders uint u0)

;; Public functions
(define-public (register-commander (certifications (string-ascii 500)) (experience-level uint))
  (let ((commander tx-sender))
    (asserts! (is-none (map-get? commanders { commander: commander })) ERR_ALREADY_VERIFIED)
    (map-set commanders
      { commander: commander }
      {
        status: STATUS_PENDING,
        verification-date: block-height,
        certifications: certifications,
        experience-level: experience-level,
        verified-by: CONTRACT_OWNER
      }
    )
    (map-set commander-stats
      { commander: commander }
      {
        incidents-handled: u0,
        success-rate: u100,
        last-active: block-height
      }
    )
    (var-set total-commanders (+ (var-get total-commanders) u1))
    (ok true)
  )
)

(define-public (verify-commander (commander principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? commanders { commander: commander })
      commander-data
      (begin
        (map-set commanders
          { commander: commander }
          (merge commander-data { status: STATUS_VERIFIED, verified-by: tx-sender })
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

(define-public (update-commander-stats (commander principal) (incidents-handled uint) (success-rate uint))
  (begin
    (asserts! (is-verified-commander commander) ERR_UNAUTHORIZED)
    (map-set commander-stats
      { commander: commander }
      {
        incidents-handled: incidents-handled,
        success-rate: success-rate,
        last-active: block-height
      }
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-verified-commander (commander principal))
  (match (map-get? commanders { commander: commander })
    commander-data (is-eq (get status commander-data) STATUS_VERIFIED)
    false
  )
)

(define-read-only (get-commander-info (commander principal))
  (map-get? commanders { commander: commander })
)

(define-read-only (get-commander-stats (commander principal))
  (map-get? commander-stats { commander: commander })
)

(define-read-only (get-total-commanders)
  (var-get total-commanders)
)
