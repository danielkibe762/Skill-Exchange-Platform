(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-UNAUTHORIZED (err u102))
(define-constant ERR-INVALID-STATUS (err u103))
(define-constant ERR-ALREADY-EXISTS (err u104))
(define-constant ERR-INVALID-AMOUNT (err u105))
(define-constant ERR-INSUFFICIENT-BALANCE (err u106))
(define-constant ERR-ESCROW-ACTIVE (err u107))
(define-constant ERR-INVALID-RATING (err u108))
(define-constant ERR-DISPUTE-EXISTS (err u109))
(define-constant ERR-INVALID-RESOLUTION (err u110))

(define-data-var next-service-id uint u1)
(define-data-var next-escrow-id uint u1)
(define-data-var next-dispute-id uint u1)
(define-data-var platform-fee uint u50)

(define-map services uint {
    provider: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    credits-required: uint,
    is-active: bool,
    created-at: uint
})

(define-map user-profiles principal {
    username: (string-ascii 50),
    total-credits: uint,
    services-completed: uint,
    average-rating: uint,
    is-verified: bool
})

(define-map escrows uint {
    service-id: uint,
    provider: principal,
    consumer: principal,
    credits-amount: uint,
    status: (string-ascii 20),
    created-at: uint,
    completed-at: (optional uint)
})

(define-map service-ratings uint {
    escrow-id: uint,
    rating: uint,
    feedback: (string-ascii 200),
    rated-by: principal,
    created-at: uint
})

(define-map user-credits principal uint)

(define-map disputes uint {
    escrow-id: uint,
    raised-by: principal,
    reason: (string-ascii 300),
    provider-response: (optional (string-ascii 300)),
    status: (string-ascii 20),
    resolution: (optional (string-ascii 20)),
    resolved-by: (optional principal),
    created-at: uint,
    resolved-at: (optional uint)
})

(define-public (register-user (username (string-ascii 50)))
    (let ((caller tx-sender))
        (asserts! (is-none (map-get? user-profiles caller)) ERR-ALREADY-EXISTS)
        (map-set user-profiles caller {
            username: username,
            total-credits: u100,
            services-completed: u0,
            average-rating: u0,
            is-verified: false
        })
        (map-set user-credits caller u100)
        (ok true)
    )
)

(define-public (create-service (title (string-ascii 100)) (description (string-ascii 500)) (category (string-ascii 50)) (credits-required uint))
    (let ((service-id (var-get next-service-id))
          (caller tx-sender))
        (asserts! (is-some (map-get? user-profiles caller)) ERR-NOT-FOUND)
        (asserts! (> credits-required u0) ERR-INVALID-AMOUNT)
        (map-set services service-id {
            provider: caller,
            title: title,
            description: description,
            category: category,
            credits-required: credits-required,
            is-active: true,
            created-at: stacks-block-height
        })
        (var-set next-service-id (+ service-id u1))
        (ok service-id)
    )
)

(define-public (request-service (service-id uint))
    (let ((service-data (unwrap! (map-get? services service-id) ERR-NOT-FOUND))
          (caller tx-sender)
          (escrow-id (var-get next-escrow-id))
          (credits-required (get credits-required service-data))
          (user-balance (default-to u0 (map-get? user-credits caller))))
        (asserts! (get is-active service-data) ERR-INVALID-STATUS)
        (asserts! (not (is-eq caller (get provider service-data))) ERR-UNAUTHORIZED)
        (asserts! (>= user-balance credits-required) ERR-INSUFFICIENT-BALANCE)
        (map-set user-credits caller (- user-balance credits-required))
        (map-set escrows escrow-id {
            service-id: service-id,
            provider: (get provider service-data),
            consumer: caller,
            credits-amount: credits-required,
            status: "pending",
            created-at: stacks-block-height,
            completed-at: none
        })
        (var-set next-escrow-id (+ escrow-id u1))
        (ok escrow-id)
    )
)

(define-public (accept-request (escrow-id uint))
    (let ((escrow-data (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
          (caller tx-sender))
        (asserts! (is-eq caller (get provider escrow-data)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status escrow-data) "pending") ERR-INVALID-STATUS)
        (map-set escrows escrow-id (merge escrow-data { status: "accepted" }))
        (ok true)
    )
)

(define-public (complete-service (escrow-id uint))
    (let ((escrow-data (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
          (caller tx-sender))
        (asserts! (is-eq caller (get provider escrow-data)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status escrow-data) "accepted") ERR-INVALID-STATUS)
        (map-set escrows escrow-id (merge escrow-data {
            status: "completed",
            completed-at: (some stacks-block-height)
        }))
        (ok true)
    )
)

(define-public (confirm-completion (escrow-id uint))
    (let ((escrow-data (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
          (caller tx-sender)
          (provider (get provider escrow-data))
          (credits-amount (get credits-amount escrow-data))
          (provider-balance (default-to u0 (map-get? user-credits provider))))
        (asserts! (is-eq caller (get consumer escrow-data)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status escrow-data) "completed") ERR-INVALID-STATUS)
        (map-set user-credits provider (+ provider-balance credits-amount))
        (map-set escrows escrow-id (merge escrow-data { status: "confirmed" }))
        (try! (update-provider-stats provider))
        (ok true)
    )
)

(define-public (rate-service (escrow-id uint) (rating uint) (feedback (string-ascii 200)))
    (let ((escrow-data (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
          (caller tx-sender))
        (asserts! (is-eq caller (get consumer escrow-data)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status escrow-data) "confirmed") ERR-INVALID-STATUS)
        (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-RATING)
        (map-set service-ratings escrow-id {
            escrow-id: escrow-id,
            rating: rating,
            feedback: feedback,
            rated-by: caller,
            created-at: stacks-block-height
        })
        (ok true)
    )
)

(define-public (cancel-request (escrow-id uint))
    (let ((escrow-data (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
          (caller tx-sender)
          (consumer (get consumer escrow-data))
          (credits-amount (get credits-amount escrow-data))
          (consumer-balance (default-to u0 (map-get? user-credits consumer))))
        (asserts! (is-eq caller consumer) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status escrow-data) "pending") ERR-INVALID-STATUS)
        (map-set user-credits consumer (+ consumer-balance credits-amount))
        (map-set escrows escrow-id (merge escrow-data { status: "cancelled" }))
        (ok true)
    )
)

(define-public (deactivate-service (service-id uint))
    (let ((service-data (unwrap! (map-get? services service-id) ERR-NOT-FOUND))
          (caller tx-sender))
        (asserts! (is-eq caller (get provider service-data)) ERR-UNAUTHORIZED)
        (map-set services service-id (merge service-data { is-active: false }))
        (ok true)
    )
)

(define-public (add-credits (amount uint))
    (let ((caller tx-sender)
          (current-balance (default-to u0 (map-get? user-credits caller))))
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (map-set user-credits caller (+ current-balance amount))
        (ok true)
    )
)

(define-private (update-provider-stats (provider principal))
    (let ((profile-data (unwrap! (map-get? user-profiles provider) ERR-NOT-FOUND))
          (completed-count (+ (get services-completed profile-data) u1)))
        (map-set user-profiles provider (merge profile-data {
            services-completed: completed-count
        }))
        (ok true)
    )
)

(define-read-only (get-service (service-id uint))
    (map-get? services service-id)
)

(define-read-only (get-user-profile (user principal))
    (map-get? user-profiles user)
)

(define-read-only (get-user-credits (user principal))
    (default-to u0 (map-get? user-credits user))
)

(define-read-only (get-escrow (escrow-id uint))
    (map-get? escrows escrow-id)
)

(define-read-only (get-service-rating (escrow-id uint))
    (map-get? service-ratings escrow-id)
)

(define-read-only (get-next-service-id)
    (var-get next-service-id)
)

(define-read-only (get-next-escrow-id)
    (var-get next-escrow-id)
)

(define-public (raise-dispute (escrow-id uint) (reason (string-ascii 300)))
    (let ((escrow-data (unwrap! (map-get? escrows escrow-id) ERR-NOT-FOUND))
          (caller tx-sender)
          (dispute-id (var-get next-dispute-id)))
        (asserts! (is-eq caller (get consumer escrow-data)) ERR-UNAUTHORIZED)
        (asserts! (or (is-eq (get status escrow-data) "completed") 
                      (is-eq (get status escrow-data) "accepted")) 
                  ERR-INVALID-STATUS)
        (asserts! (is-none (map-get? disputes dispute-id)) ERR-DISPUTE-EXISTS)
        (map-set disputes dispute-id {
            escrow-id: escrow-id,
            raised-by: caller,
            reason: reason,
            provider-response: none,
            status: "open",
            resolution: none,
            resolved-by: none,
            created-at: stacks-block-height,
            resolved-at: none
        })
        (map-set escrows escrow-id (merge escrow-data { status: "disputed" }))
        (var-set next-dispute-id (+ dispute-id u1))
        (ok dispute-id)
    )
)

(define-public (respond-to-dispute (dispute-id uint) (response (string-ascii 300)))
    (let ((dispute-data (unwrap! (map-get? disputes dispute-id) ERR-NOT-FOUND))
          (escrow-data (unwrap! (map-get? escrows (get escrow-id dispute-data)) ERR-NOT-FOUND))
          (caller tx-sender))
        (asserts! (is-eq caller (get provider escrow-data)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status dispute-data) "open") ERR-INVALID-STATUS)
        (map-set disputes dispute-id (merge dispute-data {
            provider-response: (some response),
            status: "responded"
        }))
        (ok true)
    )
)

(define-public (resolve-dispute (dispute-id uint) (resolution (string-ascii 20)))
    (let ((dispute-data (unwrap! (map-get? disputes dispute-id) ERR-NOT-FOUND))
          (escrow-data (unwrap! (map-get? escrows (get escrow-id dispute-data)) ERR-NOT-FOUND))
          (caller tx-sender)
          (provider (get provider escrow-data))
          (consumer (get consumer escrow-data))
          (credits-amount (get credits-amount escrow-data))
          (provider-balance (default-to u0 (map-get? user-credits provider)))
          (consumer-balance (default-to u0 (map-get? user-credits consumer))))
        (asserts! (is-eq caller CONTRACT-OWNER) ERR-OWNER-ONLY)
        (asserts! (or (is-eq (get status dispute-data) "open") 
                      (is-eq (get status dispute-data) "responded")) 
                  ERR-INVALID-STATUS)
        (asserts! (or (is-eq resolution "refund-consumer") 
                      (is-eq resolution "pay-provider") 
                      (is-eq resolution "split")) 
                  ERR-INVALID-RESOLUTION)
        (if (is-eq resolution "refund-consumer")
            (map-set user-credits consumer (+ consumer-balance credits-amount))
            (if (is-eq resolution "pay-provider")
                (begin
                    (map-set user-credits provider (+ provider-balance credits-amount))
                    (try! (update-provider-stats provider))
                )
                (begin
                    (map-set user-credits consumer (+ consumer-balance (/ credits-amount u2)))
                    (map-set user-credits provider (+ provider-balance (/ credits-amount u2)))
                )
            )
        )
        (map-set disputes dispute-id (merge dispute-data {
            status: "resolved",
            resolution: (some resolution),
            resolved-by: (some caller),
            resolved-at: (some stacks-block-height)
        }))
        (map-set escrows (get escrow-id dispute-data) (merge escrow-data { status: "resolved" }))
        (ok true)
    )
)

(define-read-only (get-dispute (dispute-id uint))
    (map-get? disputes dispute-id)
)

(define-read-only (get-next-dispute-id)
    (var-get next-dispute-id)
)
