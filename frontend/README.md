# Educational Marketplace - Web3 Learning Platform

## Overview

A modern educational marketplace built on the Hedera blockchain, enabling students to discover, purchase, and access courses using cryptocurrency payments. The platform combines traditional e-learning features with Web3 functionality, supporting multiple wallet integrations for seamless crypto transactions.

## Features

### Core Functionality
- **Course Catalog**: Browse and search through a comprehensive library of courses
- **Category Filtering**: Organize courses by subjects and skill levels
- **Course Details**: Detailed course information with instructor profiles and curriculum
- **User Authentication**: Traditional email/password and Web3 wallet authentication
- **Responsive Design**: Mobile-first design optimized for all devices

### Web3 Integration
- **Multi-Wallet Support**: 
  - **Hashpack** (Primary) - Hedera network integration with HBAR payments
  - **MetaMask** - Ethereum and EVM chain support
  - **Phantom** - Solana network integration
- **Crypto Payments**: Purchase courses using HBAR, ETH, or SOL
- **Demo Mode**: Test wallet functionality with simulated balances
- **Real-time Balance Updates**: Live wallet balance tracking during transactions

### User Experience
- **Modern UI/UX**: Clean, intuitive interface with smooth animations
- **Dark/Light Mode**: Theme switching for user preference
- **Loading States**: Skeleton loaders and progress indicators
- **Error Handling**: Comprehensive error messages and fallback states

## Technology Stack

### Frontend
- **Next.js 14** - React framework with App Router
- **TypeScript** - Type-safe development
- **Tailwind CSS** - Utility-first styling
- **Shadcn/ui** - Component library
- **Lucide React** - Icon library

### Web3 & Blockchain
- **Hedera SDK** - Hedera network integration
- **HashConnect** - Hashpack wallet connection
- **Web3.js** - Ethereum blockchain interaction
- **Solana Web3.js** - Solana network integration

### Development Tools
- **ESLint** - Code linting
- **Prettier** - Code formatting
- **Vercel** - Deployment and hosting

## Getting Started

### Prerequisites
- Node.js 18+ 
- npm or yarn package manager
- Web3 wallet extension (Hashpack, MetaMask, or Phantom)

### Installation

1. **Clone the repository**
   \`\`\`bash
   git clone https://github.com/ipheeoma/educational-marketplace.git
   cd educational-marketplace
   \`\`\`

2. **Install dependencies**
   \`\`\`bash
   npm install
   # or
   yarn install
   \`\`\`

3. **Set up environment variables**
   \`\`\`bash
   cp .env.example .env.local
   \`\`\`
   
   Configure the following variables:
   \`\`\`env
   NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID=your_project_id
   NEXT_PUBLIC_APP_URL=http://localhost:3000
   \`\`\`

4. **Run the development server**
   \`\`\`bash
   npm run dev
   # or
   yarn dev
   \`\`\`

5. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

##  Wallet Integration

### Supported Wallets

#### Hashpack (Primary)
- **Network**: Hedera
- **Currency**: HBAR
- **Installation**: [Chrome Extension](https://chrome.google.com/webstore/detail/hashpack/gjagmgiddbbciopjhllkdnddhcglnemk)
- **Demo Balance**: 1,250.5000 HBAR

#### MetaMask
- **Network**: Ethereum, Polygon, BSC
- **Currency**: ETH, MATIC, BNB
- **Installation**: [metamask.io](https://metamask.io)

#### Phantom
- **Network**: Solana
- **Currency**: SOL
- **Installation**: [phantom.app](https://phantom.app)

### Payment Flow
1. Connect your preferred wallet
2. Browse and select a course
3. Click "Enroll Now" 
4. Confirm transaction in wallet
5. Access purchased course content

##  Project Structure

\`\`\`
├── app/                    # Next.js App Router pages
│   ├── auth/              # Authentication pages
│   ├── course/            # Individual course pages
│   ├── courses/           # Course catalog
│   ├── categories/        # Course categories
│   ├── wallet-demo/       # Wallet testing page
│   └── page.tsx           # Homepage
├── components/            # Reusable components
│   ├── ui/               # Shadcn/ui components
│   ├── wallet-connect.tsx # Wallet integration
│   └── wallet-features.tsx # Wallet feature showcase
├── lib/                  # Utility functions
├── public/               # Static assets
└── styles/               # Global styles
\`\`\`

##  Usage Guide

### For Students
1. **Browse Courses**: Explore the course catalog or use category filters
2. **Connect Wallet**: Use the "Connect Wallet" button on auth pages
3. **Purchase Courses**: Select a course and pay with crypto
4. **Access Content**: View purchased courses in your dashboard

### For Developers
1. **Wallet Testing**: Visit `/wallet-demo` to test wallet connections
2. **Component Library**: Explore reusable components in `/components`
3. **API Integration**: Extend wallet functionality in `wallet-connect.tsx`

##  Configuration

### Wallet Configuration
Edit `components/wallet-connect.tsx` to:
- Add new wallet providers
- Modify payment processing logic
- Update demo balances and currencies

### Styling
- **Colors**: Modify theme in `app/globals.css`
- **Components**: Customize UI components in `components/ui/`
- **Layout**: Adjust responsive breakpoints in Tailwind config

### Development Guidelines
- Follow TypeScript best practices
- Use Tailwind CSS for styling
- Test wallet integrations thoroughly
- Maintain responsive design principles
