# 🚀 Batch Transaction Executor

A powerful Clarity smart contract that enables efficient batch transaction execution with meta-transaction support on the Stacks blockchain.

## 🌟 Features

- **⚡ Batch Execution**: Execute multiple transactions in a single call
- **🔐 Meta-Transactions**: Allow third parties to execute transactions on behalf of users
- **🛡️ Security**: Nonce-based replay protection and authorization controls
- **💰 Fee Management**: Configurable fee structure for batch operations
- **📊 Transaction History**: Complete audit trail of all batch executions
- **🎯 Simulation**: Test batch executions before committing

## 📋 Contract Overview

The Batch Transaction Executor contract allows users to:
- Execute multiple contract calls in a single transaction
- Enable meta-transactions where authorized executors can perform operations on behalf of users
- Manage fees and access control
- Track execution history and results

## 🔧 Core Functions

### 🎯 Main Execution Functions

#### `execute-batch-transaction`
Execute a batch of transactions directly as the sender.

```clarity
(execute-batch-transaction 
  (list principal1 principal2) 
  (list "function-name-1" "function-name-2")
  (list (list u1 u2) (list u3 u4)))
```

#### `execute-batch-meta-transaction`
Execute a batch of transactions on behalf of another user (meta-transaction).

```clarity
(execute-batch-meta-transaction
  user-principal
  nonce
  (list target1 target2)
  (list "function1" "function2")
  (list (list u1) (list u2))
  signature
  fee-payment)
```

### 🔍 Read-Only Functions

#### `get-user-nonce`
Get the current nonce for a user.

```clarity
(get-user-nonce 'SP1234567890...)
```

#### `get-batch-execution-result`
Get detailed results of a batch execution.

```clarity
(get-batch-execution-result u1)
```

#### `calculate-batch-fee`
Calculate the fee for a batch of given size.

```clarity
(calculate-batch-fee u5)
```

#### `simulate-batch-execution`
Simulate a batch execution without executing it.

```clarity
(simulate-batch-execution
  (list target1 target2)
  (list "function1" "function2")
  (list (list u1) (list u2)))
```

### ⚙️ Admin Functions

#### `authorize-executor`
Authorize an executor to perform meta-transactions.

```clarity
(authorize-executor 'SP1234567890...)
```

#### `set-fees`
Update the fee structure.

```clarity
(set-fees u1000 u100)
```

#### `set-max-batch-size`
Set the maximum number of transactions per batch.

```clarity
(set-max-batch-size u50)
```

## 🚀 Usage Examples

### Basic Batch Execution

```clarity
;; Execute 3 transactions in one batch
(contract-call? .batch-transaction-executor execute-batch-transaction
  (list 'SP123... 'SP456... 'SP789...)
  (list "transfer" "mint" "burn")
  (list (list u100) (list u5) (list u2)))
```

### Meta-Transaction Execution

```clarity
;; Execute transactions on behalf of another user
(contract-call? .batch-transaction-executor execute-batch-meta-transaction
  'SP-USER-ADDRESS
  u1
  (list 'SP-CONTRACT-1 'SP-CONTRACT-2)
  (list "function-a" "function-b")
  (list (list u10 u20) (list u30))
  0x1234567890...
  u1200)
```

### Fee Calculation

```clarity
;; Calculate fee for 5 transactions
(contract-call? .batch-transaction-executor calculate-batch-fee u5)
;; Returns: u1500 (base fee: u1000 + per-tx fee: u100 * 5)
```

## 🛠️ Development Setup

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js and npm/yarn for testing

### Getting Started

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd batch-transaction-executor
   npm install
   ```

2. **Run tests**:
   ```bash
   clarinet test
   ```

3. **Deploy locally**:
   ```bash
   clarinet integrate
   ```

## 📊 Fee Structure

- **Base Fee**: Fixed cost per batch execution
- **Per-Transaction Fee**: Additional cost for each transaction in the batch
- **Default Values**:
  - Base fee: 1000 micro-STX
  - Per-transaction fee: 100 micro-STX

## 🔒 Security Features

- **Nonce Management**: Prevents replay attacks
- **Authorization System**: Control who can execute meta-transactions
- **Owner Controls**: Admin functions restricted to contract owner
- **Batch Size Limits**: Prevents gas limit issues

## 🧪 Testing

The contract includes comprehensive tests covering:
- Basic batch execution
- Meta-transaction flows
- Security validations
- Fee calculations
- Error handling

Run tests with:
```bash
clarinet test
```

## 📈 Gas Optimization

- Efficient batch processing
- Minimal storage operations
- Optimized data structures
- Configurable batch limits

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/write-smart-contracts/clarity-language/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)

---

Built with ❤️ for the Stacks ecosystem
