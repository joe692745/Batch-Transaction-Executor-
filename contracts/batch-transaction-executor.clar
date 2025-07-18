(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-nonce (err u101))
(define-constant err-invalid-signature (err u102))
(define-constant err-execution-failed (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-batch-size (err u105))
(define-constant err-insufficient-payment (err u106))
(define-constant err-invalid-target (err u107))

(define-data-var contract-enabled bool true)
(define-data-var max-batch-size uint u50)
(define-data-var base-fee uint u1000)
(define-data-var per-transaction-fee uint u100)

(define-map user-nonces principal uint)
(define-map authorized-executors principal bool)
(define-map transaction-history 
  { user: principal, nonce: uint } 
  { executed: bool, stacks-block-height: uint, fee-paid: uint })

(define-map batch-execution-results
  { batch-id: uint }
  { 
    user: principal, 
    total-transactions: uint,
    successful-transactions: uint,
    total-fee: uint,
    executed-at: uint
  })

(define-data-var next-batch-id uint u1)

(define-public (enable-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-enabled true)
    (ok true)))

(define-public (disable-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-enabled false)
    (ok true)))

(define-public (set-max-batch-size (new-size uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set max-batch-size new-size)
    (ok true)))

(define-public (set-fees (new-base-fee uint) (new-per-tx-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set base-fee new-base-fee)
    (var-set per-transaction-fee new-per-tx-fee)
    (ok true)))

(define-public (authorize-executor (executor principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-executors executor true)
    (ok true)))

(define-public (revoke-executor (executor principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-delete authorized-executors executor)
    (ok true)))

(define-public (execute-batch-meta-transaction
  (user principal)
  (nonce uint)
  (targets (list 50 principal))
  (function-names (list 50 (string-ascii 50)))
  (arguments-list (list 50 (list 10 uint)))
  (signature (buff 65))
  (fee-payment uint))
  (let
    (
      (current-nonce (default-to u0 (map-get? user-nonces user)))
      (batch-size (len targets))
      (total-fee (+ (var-get base-fee) (* (var-get per-transaction-fee) batch-size)))
      (current-batch-id (var-get next-batch-id))
    )
    (asserts! (var-get contract-enabled) err-owner-only)
    (asserts! (is-eq nonce (+ current-nonce u1)) err-invalid-nonce)
    (asserts! (<= batch-size (var-get max-batch-size)) err-invalid-batch-size)
    (asserts! (>= fee-payment total-fee) err-insufficient-payment)
    (asserts! (or (is-eq tx-sender user) 
                  (default-to false (map-get? authorized-executors tx-sender))) 
              err-unauthorized)
    
    (map-set user-nonces user nonce)
    (map-set transaction-history 
      { user: user, nonce: nonce } 
      { executed: true, stacks-block-height: stacks-block-height, fee-paid: fee-payment })
    
    (let
      (
        (execution-results (execute-transaction-batch targets function-names arguments-list))
        (successful-count (get successful-transactions execution-results))
      )
      (map-set batch-execution-results
        { batch-id: current-batch-id }
        { 
          user: user, 
          total-transactions: batch-size,
          successful-transactions: successful-count,
          total-fee: fee-payment,
          executed-at: stacks-block-height
        })
      
      (var-set next-batch-id (+ current-batch-id u1))
      (ok { 
        batch-id: current-batch-id,
        successful-transactions: successful-count,
        total-transactions: batch-size,
        fee-charged: fee-payment
      }))))

(define-public (execute-batch-transaction
  (targets (list 50 principal))
  (function-names (list 50 (string-ascii 50)))
  (arguments-list (list 50 (list 10 uint))))
  (let
    (
      (user tx-sender)
      (current-nonce (default-to u0 (map-get? user-nonces user)))
      (new-nonce (+ current-nonce u1))
      (batch-size (len targets))
      (total-fee (+ (var-get base-fee) (* (var-get per-transaction-fee) batch-size)))
      (current-batch-id (var-get next-batch-id))
    )
    (asserts! (var-get contract-enabled) err-owner-only)
    (asserts! (<= batch-size (var-get max-batch-size)) err-invalid-batch-size)
    
    (map-set user-nonces user new-nonce)
    (map-set transaction-history 
      { user: user, nonce: new-nonce } 
      { executed: true, stacks-block-height: stacks-block-height, fee-paid: total-fee })
    
    (let
      (
        (execution-results (execute-transaction-batch targets function-names arguments-list))
        (successful-count (get successful-transactions execution-results))
      )
      (map-set batch-execution-results
        { batch-id: current-batch-id }
        { 
          user: user, 
          total-transactions: batch-size,
          successful-transactions: successful-count,
          total-fee: total-fee,
          executed-at: stacks-block-height
        })
      
      (var-set next-batch-id (+ current-batch-id u1))
      (ok { 
        batch-id: current-batch-id,
        successful-transactions: successful-count,
        total-transactions: batch-size,
        fee-charged: total-fee
      }))))

(define-private (execute-transaction-batch 
  (targets (list 50 principal))
  (function-names (list 50 (string-ascii 50)))
  (arguments-list (list 50 (list 10 uint))))
  (let
    (
      (results (map execute-single-transaction 
                   targets 
                   function-names 
                   arguments-list))
      (successful-count (fold + (map result-to-number results) u0))
    )
    { successful-transactions: successful-count }))

(define-private (execute-single-transaction 
  (target principal)
  (function-name (string-ascii 50))
  (arguments (list 10 uint)))
  false)

(define-private (result-to-number (result bool))
  (if result u1 u0))

(define-public (withdraw-fees (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (stx-transfer? amount tx-sender contract-owner)))

(define-read-only (get-user-nonce (user principal))
  (default-to u0 (map-get? user-nonces user)))

(define-read-only (get-transaction-history (user principal) (nonce uint))
  (map-get? transaction-history { user: user, nonce: nonce }))

(define-read-only (get-batch-execution-result (batch-id uint))
  (map-get? batch-execution-results { batch-id: batch-id }))

(define-read-only (get-contract-info)
  { 
    enabled: (var-get contract-enabled),
    max-batch-size: (var-get max-batch-size),
    base-fee: (var-get base-fee),
    per-transaction-fee: (var-get per-transaction-fee),
    next-batch-id: (var-get next-batch-id)
  })

(define-read-only (calculate-batch-fee (batch-size uint))
  (+ (var-get base-fee) (* (var-get per-transaction-fee) batch-size)))

(define-read-only (is-executor-authorized (executor principal))
  (default-to false (map-get? authorized-executors executor)))

(define-read-only (get-next-nonce (user principal))
  (+ (default-to u0 (map-get? user-nonces user)) u1))

(define-public (simulate-batch-execution
  (targets (list 50 principal))
  (function-names (list 50 (string-ascii 50)))
  (arguments-list (list 50 (list 10 uint))))
  (let
    (
      (batch-size (len targets))
      (total-fee (calculate-batch-fee batch-size))
    )
    (asserts! (<= batch-size (var-get max-batch-size)) err-invalid-batch-size)
    (ok { 
      batch-size: batch-size,
      estimated-fee: total-fee,
      max-batch-size: (var-get max-batch-size)
    })))
