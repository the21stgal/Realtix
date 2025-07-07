;; Decentralized Real Estate Agent Network Smart Contract
;; A platform for real estate agents to track sales, testimonials, and professional referrals

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-visibility (err u104))

;; Visibility levels
(define-constant VISIBILITY-PUBLIC u0)
(define-constant VISIBILITY-LICENSED-AGENTS u1)
(define-constant VISIBILITY-PRIVATE u2)

;; Data Variables
(define-data-var commission-fee uint u500) ;; 0.05% fee in basis points

;; Data Maps

;; Agent profiles
(define-map agent-profiles
  { agent: principal }
  {
    full-name: (string-ascii 100),
    specialization: (string-ascii 200),
    service-area: (string-ascii 100),
    profile-visibility: uint,
    registered-at: uint,
    is-licensed: bool
  }
)

;; Property sales records
(define-map property-sales
  { agent: principal, sale-id: uint }
  {
    property-address: (string-ascii 100),
    sale-type: (string-ascii 100),
    completion-date: uint,
    listing-date: (optional uint),
    sale-notes: (string-ascii 500),
    visibility-level: uint,
    recorded-at: uint
  }
)

;; Agent sales counters
(define-map agent-sales-count
  { agent: principal }
  { count: uint }
)

;; Professional certifications
(define-map agent-certifications
  { agent: principal, certification-id: uint }
  {
    certification-name: (string-ascii 100),
    issuing-body: (string-ascii 100),
    earned-date: uint,
    expiration-date: (optional uint),
    certificate-hash: (buff 32),
    visibility-level: uint,
    is-verified: bool,
    recorded-at: uint
  }
)

;; Agent certification counters
(define-map agent-certification-count
  { agent: principal }
  { count: uint }
)

;; Client testimonials
(define-map client-testimonials
  { agent: principal, testimonial-id: uint }
  {
    service-category: (string-ascii 50),
    referring-agent: principal,
    testimonial-content: (string-ascii 300),
    submitted-at: uint
  }
)

;; Agent testimonial counters
(define-map agent-testimonial-count
  { agent: principal }
  { count: uint }
)

;; Professional referrals
(define-map agent-referrals
  { agent1: principal, agent2: principal }
  {
    referral-status: (string-ascii 20), ;; "pending", "accepted", "declined"
    initiated-by: principal,
    created-at: uint
  }
)

;; Service category endorsement counts
(define-map service-endorsements
  { agent: principal, service: (string-ascii 50) }
  { count: uint }
)

;; Read-only functions

;; Get agent profile
(define-read-only (get-agent-profile (agent principal))
  (map-get? agent-profiles { agent: agent })
)

;; Get property sale record
(define-read-only (get-property-sale (agent principal) (sale-id uint))
  (map-get? property-sales { agent: agent, sale-id: sale-id })
)

;; Get certification
(define-read-only (get-agent-certification (agent principal) (certification-id uint))
  (map-get? agent-certifications { agent: agent, certification-id: certification-id })
)

;; Get testimonial
(define-read-only (get-client-testimonial (agent principal) (testimonial-id uint))
  (map-get? client-testimonials { agent: agent, testimonial-id: testimonial-id })
)

;; Get referral status
(define-read-only (get-referral-status (agent1 principal) (agent2 principal))
  (map-get? agent-referrals { agent1: agent1, agent2: agent2 })
)

;; Get service endorsement count
(define-read-only (get-service-endorsement-count (agent principal) (service (string-ascii 50)))
  (default-to u0 (get count (map-get? service-endorsements { agent: agent, service: service })))
)

;; Check if agents are connected
(define-read-only (are-agents-connected (agent1 principal) (agent2 principal))
  (let ((referral1 (map-get? agent-referrals { agent1: agent1, agent2: agent2 }))
        (referral2 (map-get? agent-referrals { agent1: agent2, agent2: agent1 })))
    (or
      (and (is-some referral1) (is-eq (get referral-status (unwrap-panic referral1)) "accepted"))
      (and (is-some referral2) (is-eq (get referral-status (unwrap-panic referral2)) "accepted"))
    )
  )
)

;; Check if agent can view private content
(define-read-only (can-view-private-content (owner principal) (viewer principal) (visibility-level uint))
  (or
    (is-eq owner viewer)
    (is-eq visibility-level VISIBILITY-PUBLIC)
    (and 
      (is-eq visibility-level VISIBILITY-LICENSED-AGENTS)
      (are-agents-connected owner viewer)
    )
  )
)

;; Public functions

;; Register agent profile
(define-public (register-agent-profile (full-name (string-ascii 100)) (specialization (string-ascii 200)) (service-area (string-ascii 100)) (profile-visibility uint))
  (begin
    (asserts! (<= profile-visibility VISIBILITY-PRIVATE) err-invalid-visibility)
    (ok (map-set agent-profiles
      { agent: tx-sender }
      {
        full-name: full-name,
        specialization: specialization,
        service-area: service-area,
        profile-visibility: profile-visibility,
        registered-at: block-height,
        is-licensed: false
      }
    ))
  )
)

;; Record property sale
(define-public (record-property-sale (property-address (string-ascii 100)) (sale-type (string-ascii 100)) (completion-date uint) (listing-date (optional uint)) (sale-notes (string-ascii 500)) (visibility-level uint))
  (let ((current-count (default-to u0 (get count (map-get? agent-sales-count { agent: tx-sender })))))
    (begin
      (asserts! (<= visibility-level VISIBILITY-PRIVATE) err-invalid-visibility)
      (map-set property-sales
        { agent: tx-sender, sale-id: current-count }
        {
          property-address: property-address,
          sale-type: sale-type,
          completion-date: completion-date,
          listing-date: listing-date,
          sale-notes: sale-notes,
          visibility-level: visibility-level,
          recorded-at: block-height
        }
      )
      (map-set agent-sales-count
        { agent: tx-sender }
        { count: (+ current-count u1) }
      )
      (ok current-count)
    )
  )
)

;; Add certification
(define-public (add-agent-certification (certification-name (string-ascii 100)) (issuing-body (string-ascii 100)) (earned-date uint) (expiration-date (optional uint)) (certificate-hash (buff 32)) (visibility-level uint))
  (let ((current-count (default-to u0 (get count (map-get? agent-certification-count { agent: tx-sender })))))
    (begin
      (asserts! (<= visibility-level VISIBILITY-PRIVATE) err-invalid-visibility)
      (map-set agent-certifications
        { agent: tx-sender, certification-id: current-count }
        {
          certification-name: certification-name,
          issuing-body: issuing-body,
          earned-date: earned-date,
          expiration-date: expiration-date,
          certificate-hash: certificate-hash,
          visibility-level: visibility-level,
          is-verified: false,
          recorded-at: block-height
        }
      )
      (map-set agent-certification-count
        { agent: tx-sender }
        { count: (+ current-count u1) }
      )
      (ok current-count)
    )
  )
)

;; Send referral request
(define-public (send-referral-request (target-agent principal))
  (begin
    (asserts! (not (is-eq tx-sender target-agent)) err-unauthorized)
    (asserts! (is-none (map-get? agent-referrals { agent1: tx-sender, agent2: target-agent })) err-already-exists)
    (asserts! (is-none (map-get? agent-referrals { agent1: target-agent, agent2: tx-sender })) err-already-exists)
    (ok (map-set agent-referrals
      { agent1: tx-sender, agent2: target-agent }
      {
        referral-status: "pending",
        initiated-by: tx-sender,
        created-at: block-height
      }
    ))
  )
)

;; Accept referral request
(define-public (accept-referral-request (requesting-agent principal))
  (let ((referral (map-get? agent-referrals { agent1: requesting-agent, agent2: tx-sender })))
    (begin
      (asserts! (is-some referral) err-not-found)
      (asserts! (is-eq (get referral-status (unwrap-panic referral)) "pending") err-unauthorized)
      (ok (map-set agent-referrals
        { agent1: requesting-agent, agent2: tx-sender }
        {
          referral-status: "accepted",
          initiated-by: requesting-agent,
          created-at: (get created-at (unwrap-panic referral))
        }
      ))
    )
  )
)

;; Provide service testimonial
(define-public (provide-service-testimonial (agent principal) (service-category (string-ascii 50)) (testimonial-content (string-ascii 300)))
  (let ((current-count (default-to u0 (get count (map-get? agent-testimonial-count { agent: agent }))))
        (current-service-count (default-to u0 (get count (map-get? service-endorsements { agent: agent, service: service-category })))))
    (begin
      (asserts! (not (is-eq tx-sender agent)) err-unauthorized)
      (asserts! (are-agents-connected tx-sender agent) err-unauthorized)
      (map-set client-testimonials
        { agent: agent, testimonial-id: current-count }
        {
          service-category: service-category,
          referring-agent: tx-sender,
          testimonial-content: testimonial-content,
          submitted-at: block-height
        }
      )
      (map-set agent-testimonial-count
        { agent: agent }
        { count: (+ current-count u1) }
      )
      (map-set service-endorsements
        { agent: agent, service: service-category }
        { count: (+ current-service-count u1) }
      )
      (ok current-count)
    )
  )
)

;; Verify certification (admin only)
(define-public (verify-agent-certification (agent principal) (certification-id uint))
  (let ((certification (map-get? agent-certifications { agent: agent, certification-id: certification-id })))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (asserts! (is-some certification) err-not-found)
      (ok (map-set agent-certifications
        { agent: agent, certification-id: certification-id }
        (merge (unwrap-panic certification) { is-verified: true })
      ))
    )
  )
)

;; License agent (admin only)
(define-public (license-agent (agent principal))
  (let ((profile (map-get? agent-profiles { agent: agent })))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (asserts! (is-some profile) err-not-found)
      (ok (map-set agent-profiles
        { agent: agent }
        (merge (unwrap-panic profile) { is-licensed: true })
      ))
    )
  )
)

;; Update commission fee (admin only)
(define-public (update-commission-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set commission-fee new-fee)
    (ok true)
  )
)