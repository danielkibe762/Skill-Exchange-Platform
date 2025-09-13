# 🤝 Skill Exchange Platform

> A decentralized P2P skill bartering platform built on the Stacks blockchain

## 🌟 Overview

The Skill Exchange Platform is a revolutionary smart contract that enables people to trade skills and services without money. Built with Clarity on the Stacks blockchain, it creates a trustless environment where users can offer services, request help, and build community connections through skill sharing.

## 🎯 Problem & Solution

**Problem**: Many people lack money to pay for services but have valuable skills to trade.

**Solution**: A P2P barter platform powered by Clarity smart contracts where users can:
- 📝 List services (tutoring, plumbing, design, etc.)
- 💱 Exchange services using a credit system
- 🔒 Use escrow contracts to verify completion
- ⭐ Rate and review service providers

## ✨ Key Features

### 👤 User Management
- **User Registration**: Create profiles with usernames and credit balances
- **Credit System**: Earn and spend platform credits for services
- **Profile Stats**: Track completed services and ratings

### 🛠️ Service Management
- **Create Services**: List your skills with descriptions and credit requirements
- **Service Categories**: Organize services by type
- **Active/Inactive Toggle**: Control service availability

### 🔄 Escrow System
- **Secure Transactions**: Credits held in escrow until service completion
- **Status Tracking**: Monitor request status (pending → accepted → completed → confirmed)
- **Dispute Protection**: Cancel requests if needed

### 📊 Rating & Reviews
- **5-Star Rating System**: Rate completed services
- **Written Feedback**: Leave detailed reviews
- **Reputation Building**: Build trust through verified completions

## 🏗️ Contract Architecture

### Data Structures

```clarity
;; Services map
services: {
    provider: principal,
    title: string-ascii,
    description: string-ascii,
    category: string-ascii,
    credits-required: uint,
    is-active: bool,
    created-at: uint
}

;; User profiles
user-profiles: {
    username: string-ascii,
    total-credits: uint,
    services-completed: uint,
    average-rating: uint,
    is-verified: bool
}

;; Escrow system
escrows: {
    service-id: uint,
    provider: principal,
    consumer: principal,
    credits-amount: uint,
    status: string-ascii,
    created-at: uint,
    completed-at: optional uint
}
```

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- [Node.js](https://nodejs.org/) for testing
- Basic understanding of Clarity smart contracts

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd Skill-Exchange-Platform

# Check contract syntax
clarinet check

# Install testing dependencies
npm install

# Run tests
npm test
```

## 📖 Usage Guide

### 1. Register as a User

```clarity
(contract-call? .skill-exchange-platform register-user "john-doe")
```

### 2. Create a Service Offer

```clarity
(contract-call? .skill-exchange-platform create-service 
    "Math Tutoring" 
    "Help with algebra and calculus" 
    "Education" 
    u50)
```

### 3. Request a Service

```clarity
(contract-call? .skill-exchange-platform request-service u1)
```

### 4. Complete the Service Flow

```clarity
;; Provider accepts the request
(contract-call? .skill-exchange-platform accept-request u1)

;; Provider marks service as completed
(contract-call? .skill-exchange-platform complete-service u1)

;; Consumer confirms completion
(contract-call? .skill-exchange-platform confirm-completion u1)

;; Consumer rates the service
(contract-call? .skill-exchange-platform rate-service u1 u5 "Excellent tutoring!")
```

## 🔍 Contract Functions

### Public Functions

| Function | Purpose | Parameters |
|----------|---------|------------|
| `register-user` | Create user profile | `username` |
| `create-service` | List a new service | `title`, `description`, `category`, `credits-required` |
| `request-service` | Request a service | `service-id` |
| `accept-request` | Accept service request | `escrow-id` |
| `complete-service` | Mark service as done | `escrow-id` |
| `confirm-completion` | Confirm and release payment | `escrow-id` |
| `rate-service` | Rate completed service | `escrow-id`, `rating`, `feedback` |
| `cancel-request` | Cancel pending request | `escrow-id` |
| `deactivate-service` | Disable service listing | `service-id` |
| `add-credits` | Add credits to account | `amount` |

### Read-Only Functions

| Function | Purpose | Returns |
|----------|---------|--------|
| `get-service` | Get service details | Service data |
| `get-user-profile` | Get user profile | Profile data |
| `get-user-credits` | Get user credit balance | Credit amount |
| `get-escrow` | Get escrow details | Escrow data |
| `get-service-rating` | Get service rating | Rating data |

## 🎨 Service Flow Diagram

```
[User A] creates service → [Service Listed]
    ↓
[User B] requests service → [Escrow Created] → [Credits Locked]
    ↓
[User A] accepts request → [Service Active]
    ↓
[User A] completes service → [Awaiting Confirmation]
    ↓
[User B] confirms completion → [Credits Released] → [Rating/Review]
```

## 🧪 Testing

Run the test suite:

```bash
npm test
```

Test individual functions:

```bash
# Test user registration
clarinet console
(contract-call? .skill-exchange-platform register-user "test-user")

# Check user profile
(contract-call? .skill-exchange-platform get-user-profile tx-sender)
```

## 🌍 Impact & Benefits

- 💰 **Financial Inclusion**: Access services without money
- 🤝 **Community Building**: Strengthen local networks
- 🔒 **Trustless Transactions**: Blockchain-secured exchanges
- 📈 **Skill Development**: Learn new skills through bartering
- 🌱 **Sustainable Economy**: Reduce monetary dependency

## 🛣️ Roadmap

- [ ] Mobile app integration
- [ ] Multi-service bundles
- [ ] Reputation scoring algorithms
- [ ] Geographic service filtering
- [ ] Integration with other DeFi protocols

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [Clarity](https://clarity-lang.org/) on [Stacks](https://www.stacks.co/)
- Inspired by the collaborative economy movement
- Thanks to the Stacks community for support and feedback

---

**Made with ❤️ for building stronger communities through skill sharing**
