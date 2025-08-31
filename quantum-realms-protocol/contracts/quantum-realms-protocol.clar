;; QuantumRealms Protocol Smart Contract

;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-GUILD-NOT-FOUND (err u103))
(define-constant ERR-INVALID-TIER (err u104))
(define-constant ERR-ALREADY-EXISTS (err u105))
(define-constant ERR-PROBABILITY-CLOSED (err u106))
(define-constant ERR-INVALID-TIMESTAMP (err u107))
(define-constant ERR-INSUFFICIENT-STAKE (err u108))
(define-constant ERR-INVALID-QUANTUM-SCORE (err u109))
(define-constant ERR-TERRITORY-NOT-FOUND (err u110))
(define-constant ERR-INVALID-CONSENSUS-SCORE (err u111))
(define-constant ERR-TIMELINE-EXPIRED (err u112))
(define-constant ERR-ALREADY-SETTLED (err u113))
(define-constant ERR-NOT-SETTLED (err u114))
(define-constant ERR-ALREADY-CLAIMED (err u115))

;; Contract Owner
(define-data-var protocol-owner principal tx-sender)
(define-data-var quantum-fee-rate uint u250) ;; 2.5%
(define-data-var min-quantum-score uint u50)
(define-data-var probability-pool-fee uint u100) ;; 1%

;; Guild Leader Profile Data
(define-map guild-leaders 
    { leader: principal }
    {
        total-quantum-power: uint,
        strategy-score: uint,
        temporal-score: uint,
        crystal-supply: uint,
        resources-earned: uint,
        territory-count: uint,
        member-count: uint,
        reputation: uint
    }
)

;; Dynamic Quantum Crystal Values
(define-map quantum-crystal-prices
    { leader: principal }
    {
        current-price: uint,
        last-update: uint,
        price-trend: int,
        volume-24h: uint
    }
)

;; Guild Membership NFT Tiers
(define-map guild-membership-nfts
    { leader: principal, member: principal }
    {
        tier-level: uint, ;; 1-initiate, 2-adept, 3-guardian, 4-quantum-master
        quantum-score: uint,
        total-contributions: uint,
        tier-benefits: uint,
        resource-share-rate: uint,
        mint-timestamp: uint
    }
)

;; Quantum Consensus Data
(define-map quantum-consensus-proofs
    { user: principal, territory-id: uint }
    {
        consensus-score: uint,
        probability-score: uint,
        strategy-quality: uint,
        timestamp: uint,
        verified: bool,
        reward-earned: uint
    }
)

;; Territory Registry for Quantum States
(define-map territory-registry
    { territory-id: uint }
    {
        guild-leader: principal,
        quantum-hash: (buff 32),
        timestamp: uint,
        probability-protected: bool,
        consensus-count: uint,
        resources-generated: uint
    }
)

;; Temporal Timeline Campaigns
(define-map temporal-campaigns
    { timeline-id: uint }
    {
        guild-leader: principal,
        target-probability: uint,
        quantum-pool: uint,
        end-timestamp: uint,
        actual-outcome: uint,
        settled: bool,
        total-stakes: uint
    }
)

;; Guild Member Probability Predictions
(define-map quantum-predictions
    { timeline-id: uint, member: principal }
    {
        predicted-probability: uint,
        stake-amount: uint,
        potential-reward: uint,
        claimed: bool
    }
)

;; Multi-Realm Quantum Credits
(define-map quantum-credits
    { user: principal }
    {
        alpha-realm-credits: uint,
        beta-realm-credits: uint,
        gamma-realm-credits: uint,
        omega-realm-credits: uint,
        total-credits: uint,
        conversion-rate: uint
    }
)

;; Resource Distribution Pools
(define-map guild-resource-pools
    { leader: principal }
    {
        immediate-pool: uint,
        member-reward-pool: uint,
        territory-protection-pool: uint,
        collaboration-pool: uint
    }
)

;; Auto-incrementing IDs
(define-data-var next-territory-id uint u1)
(define-data-var next-timeline-id uint u1)

;; Helper Functions
(define-private (calculate-tier-benefits (tier uint))
    (if (is-eq tier u1) u10  ;; initiate: 10% benefits
    (if (is-eq tier u2) u25  ;; adept: 25% benefits
    (if (is-eq tier u3) u50  ;; guardian: 50% benefits
        u100)))              ;; quantum-master: 100% benefits
)

(define-private (calculate-resource-share (tier uint))
    (if (is-eq tier u1) u5   ;; initiate: 5% resource share
    (if (is-eq tier u2) u10  ;; adept: 10% resource share
    (if (is-eq tier u3) u20  ;; guardian: 20% resource share
        u30)))               ;; quantum-master: 30% resource share
)

(define-private (calculate-probability-score (consensus uint) (strategy uint))
    (let ((base-score (/ (+ consensus strategy) u2)))
        (if (> base-score u90) u95
        (if (> base-score u70) u80
        (if (> base-score u50) u65
            u45)))
    )
)

(define-private (calculate-strategy-quality (consensus uint) (strategy uint))
    (let ((quality-base (/ (+ (* consensus u3) strategy) u4)))
        (if (> quality-base u80) u90
        (if (> quality-base u60) u75
            u50))
    )
)

(define-private (calculate-quantum-reward (quality-score uint))
    (if (> quality-score u80) u1000000  ;; 1 STX for high quality
    (if (> quality-score u60) u500000   ;; 0.5 STX for medium quality
        u250000))                       ;; 0.25 STX for basic quality
)

(define-private (calculate-probability-reward (predicted-probability uint) (stake-amount uint))
    (let ((multiplier (if (> predicted-probability u1000000) u150 u120))) ;; 1.5x or 1.2x multiplier
        (/ (* stake-amount multiplier) u100)
    )
)

;; Admin Functions
(define-public (set-quantum-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (<= new-fee u1000) ERR-INVALID-AMOUNT)
        (ok (var-set quantum-fee-rate new-fee))
    )
)

(define-public (update-min-quantum-score (new-score uint))
    (begin
        (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (<= new-score u100) ERR-INVALID-QUANTUM-SCORE)
        (ok (var-set min-quantum-score new-score))
    )
)

(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
        (ok (var-set protocol-owner new-owner))
    )
)

;; Guild Leader Registration and Management
(define-public (register-guild-leader)
    (let ((leader tx-sender))
        (asserts! (is-none (map-get? guild-leaders { leader: leader })) ERR-ALREADY-EXISTS)
        (map-set guild-leaders
            { leader: leader }
            {
                total-quantum-power: u0,
                strategy-score: u50,
                temporal-score: u50,
                crystal-supply: u1000000,
                resources-earned: u0,
                territory-count: u0,
                member-count: u0,
                reputation: u50
            }
        )
        (map-set quantum-crystal-prices
            { leader: leader }
            {
                current-price: u1000000, ;; 1 STX in microSTX
                last-update: block-height,
                price-trend: 0,
                volume-24h: u0
            }
        )
        (map-set guild-resource-pools
            { leader: leader }
            {
                immediate-pool: u0,
                member-reward-pool: u0,
                territory-protection-pool: u0,
                collaboration-pool: u0
            }
        )
        (ok true)
    )
)

(define-public (mint-guild-membership-nft (leader principal) (tier uint))
    (let 
        ((member tx-sender)
         (existing-nft (map-get? guild-membership-nfts { leader: leader, member: member })))
        (asserts! (and (>= tier u1) (<= tier u4)) ERR-INVALID-TIER)
        (asserts! (is-some (map-get? guild-leaders { leader: leader })) ERR-GUILD-NOT-FOUND)
        
        (map-set guild-membership-nfts
            { leader: leader, member: member }
            {
                tier-level: tier,
                quantum-score: u0,
                total-contributions: u0,
                tier-benefits: (calculate-tier-benefits tier),
                resource-share-rate: (calculate-resource-share tier),
                mint-timestamp: block-height
            }
        )
        
        ;; Update guild leader member count
        (match (map-get? guild-leaders { leader: leader })
            leader-data
            (map-set guild-leaders
                { leader: leader }
                (merge leader-data { member-count: (+ (get member-count leader-data) u1) })
            )
            false
        )
        (ok true)
    )
)

(define-public (submit-quantum-consensus-proof (territory-id uint) (consensus-score uint) (strategy-data uint))
    (let ((user tx-sender))
        (asserts! (and (>= consensus-score u1) (<= consensus-score u100)) ERR-INVALID-CONSENSUS-SCORE)
        (asserts! (>= consensus-score (var-get min-quantum-score)) ERR-INVALID-QUANTUM-SCORE)
        
        (let ((probability-score (calculate-probability-score consensus-score strategy-data))
              (quality-score (calculate-strategy-quality consensus-score strategy-data)))
            
            (map-set quantum-consensus-proofs
                { user: user, territory-id: territory-id }
                {
                    consensus-score: consensus-score,
                    probability-score: probability-score,
                    strategy-quality: quality-score,
                    timestamp: block-height,
                    verified: (>= probability-score u70),
                    reward-earned: (calculate-quantum-reward quality-score)
                }
            )
            
            ;; Update territory consensus count if territory exists
            (match (map-get? territory-registry { territory-id: territory-id })
                territory-data
                (map-set territory-registry
                    { territory-id: territory-id }
                    (merge territory-data { consensus-count: (+ (get consensus-count territory-data) u1) })
                )
                false
            )
            (ok probability-score)
        )
    )
)

(define-public (register-quantum-territory (quantum-hash (buff 32)))
    (let 
        ((leader tx-sender)
         (territory-id (var-get next-territory-id)))
        
        (asserts! (is-some (map-get? guild-leaders { leader: leader })) ERR-GUILD-NOT-FOUND)
        
        (map-set territory-registry
            { territory-id: territory-id }
            {
                guild-leader: leader,
                quantum-hash: quantum-hash,
                timestamp: block-height,
                probability-protected: true,
                consensus-count: u0,
                resources-generated: u0
            }
        )
        
        (var-set next-territory-id (+ territory-id u1))
        
        ;; Update guild leader territory count
        (match (map-get? guild-leaders { leader: leader })
            leader-data
            (map-set guild-leaders
                { leader: leader }
                (merge leader-data { territory-count: (+ (get territory-count leader-data) u1) })
            )
            false
        )
        (ok territory-id)
    )
)

(define-public (create-temporal-campaign (target-probability uint) (duration uint))
    (let 
        ((leader tx-sender)
         (timeline-id (var-get next-timeline-id))
         (end-time (+ block-height duration)))
        
        (asserts! (is-some (map-get? guild-leaders { leader: leader })) ERR-GUILD-NOT-FOUND)
        (asserts! (> target-probability u0) ERR-INVALID-AMOUNT)
        (asserts! (> duration u0) ERR-INVALID-TIMESTAMP)
        
        (map-set temporal-campaigns
            { timeline-id: timeline-id }
            {
                guild-leader: leader,
                target-probability: target-probability,
                quantum-pool: u0,
                end-timestamp: end-time,
                actual-outcome: u0,
                settled: false,
                total-stakes: u0
            }
        )
        
        (var-set next-timeline-id (+ timeline-id u1))
        (ok timeline-id)
    )
)

(define-public (stake-on-quantum-probability (timeline-id uint) (predicted-probability uint) (stake-amount uint))
    (let ((member tx-sender))
        (asserts! (> stake-amount u0) ERR-INVALID-AMOUNT)
        
        (match (map-get? temporal-campaigns { timeline-id: timeline-id })
            campaign-data
            (begin
                (asserts! (< block-height (get end-timestamp campaign-data)) ERR-PROBABILITY-CLOSED)
                (asserts! (not (get settled campaign-data)) ERR-ALREADY-SETTLED)
                
                (map-set quantum-predictions
                    { timeline-id: timeline-id, member: member }
                    {
                        predicted-probability: predicted-probability,
                        stake-amount: stake-amount,
                        potential-reward: (calculate-probability-reward predicted-probability stake-amount),
                        claimed: false
                    }
                )
                
                (map-set temporal-campaigns
                    { timeline-id: timeline-id }
                    (merge campaign-data 
                        { 
                            quantum-pool: (+ (get quantum-pool campaign-data) stake-amount),
                            total-stakes: (+ (get total-stakes campaign-data) u1)
                        }
                    )
                )
                (ok true)
            )
            ERR-TERRITORY-NOT-FOUND
        )
    )
)

(define-public (settle-temporal-campaign (timeline-id uint) (actual-outcome uint))
    (let ((settler tx-sender))
        (match (map-get? temporal-campaigns { timeline-id: timeline-id })
            campaign-data
            (begin
                (asserts! (is-eq settler (get guild-leader campaign-data)) ERR-NOT-AUTHORIZED)
                (asserts! (>= block-height (get end-timestamp campaign-data)) ERR-INVALID-TIMESTAMP)
                (asserts! (not (get settled campaign-data)) ERR-ALREADY-SETTLED)
                
                (map-set temporal-campaigns
                    { timeline-id: timeline-id }
                    (merge campaign-data 
                        { 
                            actual-outcome: actual-outcome,
                            settled: true
                        }
                    )
                )
                (ok true)
            )
            ERR-TERRITORY-NOT-FOUND
        )
    )
)

(define-public (claim-prediction-reward (timeline-id uint))
    (let ((member tx-sender))
        (match (map-get? quantum-predictions { timeline-id: timeline-id, member: member })
            prediction-data
            (match (map-get? temporal-campaigns { timeline-id: timeline-id })
                campaign-data
                (begin
                    (asserts! (get settled campaign-data) ERR-NOT-SETTLED)
                    (asserts! (not (get claimed prediction-data)) ERR-ALREADY-CLAIMED)
                    
                    ;; Simple reward calculation - if prediction is within 10% of actual outcome, give reward
                    (let ((accuracy (if (> (get predicted-probability prediction-data) (get actual-outcome campaign-data))
                                       (- (get predicted-probability prediction-data) (get actual-outcome campaign-data))
                                       (- (get actual-outcome campaign-data) (get predicted-probability prediction-data)))))
                        (if (<= accuracy u10) ;; Within 10% accuracy
                            (begin
                                (map-set quantum-predictions
                                    { timeline-id: timeline-id, member: member }
                                    (merge prediction-data { claimed: true })
                                )
                                (ok (get potential-reward prediction-data))
                            )
                            (ok u0) ;; No reward for inaccurate predictions
                        )
                    )
                )
                ERR-TERRITORY-NOT-FOUND
            )
            ERR-TERRITORY-NOT-FOUND
        )
    )
)

;; Read-only functions for querying data
(define-read-only (get-guild-leader-info (leader principal))
    (map-get? guild-leaders { leader: leader })
)

(define-read-only (get-guild-membership-nft (leader principal) (member principal))
    (map-get? guild-membership-nfts { leader: leader, member: member })
)

(define-read-only (get-territory-info (territory-id uint))
    (map-get? territory-registry { territory-id: territory-id })
)

(define-read-only (get-temporal-campaign-info (timeline-id uint))
    (map-get? temporal-campaigns { timeline-id: timeline-id })
)

(define-read-only (get-quantum-prediction (timeline-id uint) (member principal))
    (map-get? quantum-predictions { timeline-id: timeline-id, member: member })
)

(define-read-only (get-consensus-proof (user principal) (territory-id uint))
    (map-get? quantum-consensus-proofs { user: user, territory-id: territory-id })
)

(define-read-only (get-protocol-owner)
    (var-get protocol-owner)
)

(define-read-only (get-quantum-fee-rate)
    (var-get quantum-fee-rate)
)

(define-read-only (get-min-quantum-score)
    (var-get min-quantum-score)
)