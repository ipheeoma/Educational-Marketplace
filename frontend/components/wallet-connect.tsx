"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu"
import { Wallet, Copy, ExternalLink, LogOut, CheckCircle, AlertCircle } from "lucide-react"
import { toast } from "@/hooks/use-toast"

interface WalletInfo {
  address: string
  network: string
  balance: string
  provider: string
  nfts?: number
  transactions?: number
}

interface WalletProvider {
  name: string
  icon: string
  isInstalled: boolean
  connect: () => Promise<WalletInfo>
  description: string
  installUrl?: string
}

declare global {
  interface Window {
    ethereum?: any
    solana?: any
    hashpack?: any
    hashconnect?: any
  }
}

export function WalletConnect() {
  const [isConnected, setIsConnected] = useState(false)
  const [walletInfo, setWalletInfo] = useState<WalletInfo | null>(null)
  const [isConnecting, setIsConnecting] = useState(false)
  const [availableWallets, setAvailableWallets] = useState<WalletProvider[]>([])

  useEffect(() => {
    // Check for existing connection on mount
    const savedWallet = sessionStorage.getItem("connectedWallet")
    if (savedWallet) {
      try {
        const walletData = JSON.parse(savedWallet)
        setWalletInfo(walletData)
        setIsConnected(true)
        refreshWalletBalance(walletData)
      } catch (error) {
        console.error("Error parsing saved wallet:", error)
        sessionStorage.removeItem("connectedWallet")
      }
    }

    // Detect available wallets
    detectWallets()
  }, [])

  const refreshWalletBalance = async (wallet: WalletInfo) => {
    try {
      let updatedBalance = wallet.balance

      if (wallet.provider === "MetaMask" && window.ethereum) {
        const balanceWei = await window.ethereum.request({
          method: "eth_getBalance",
          params: [wallet.address, "latest"],
        })
        const balanceEth = Number.parseInt(balanceWei, 16) / Math.pow(10, 18)
        updatedBalance = `${balanceEth.toFixed(4)} ETH`
      } else if (wallet.provider === "Phantom" && window.solana) {
        try {
          const response = await fetch(`https://api.mainnet-beta.solana.com`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              jsonrpc: "2.0",
              id: 1,
              method: "getBalance",
              params: [wallet.address],
            }),
          })
          const data = await response.json()
          if (data.result) {
            const balanceSol = data.result.value / 1000000000 // Convert lamports to SOL
            updatedBalance = `${balanceSol.toFixed(4)} SOL`
          }
        } catch (error) {
          console.warn("Could not fetch Solana balance:", error)
        }
      } else if (wallet.provider === "Hashpack") {
        try {
          const balanceResponse = await fetch(
            `https://mainnet-public.mirrornode.hedera.com/api/v1/accounts/${wallet.address}`,
          )
          const balanceData = await balanceResponse.json()
          if (balanceData.balance && balanceData.balance.balance) {
            const balanceHbar = balanceData.balance.balance / 100000000 // Convert tinybars to HBAR
            updatedBalance = `${balanceHbar.toFixed(4)} HBAR`
          }
        } catch (error) {
          console.warn("Could not fetch Hedera balance:", error)
        }
      }

      if (updatedBalance !== wallet.balance) {
        const updatedWallet = { ...wallet, balance: updatedBalance }
        setWalletInfo(updatedWallet)
        sessionStorage.setItem("connectedWallet", JSON.stringify(updatedWallet))
      }
    } catch (error) {
      console.warn("Could not refresh balance:", error)
    }
  }

  const detectWallets = () => {
    console.log("[v0] Detecting wallets...")
    console.log("[v0] window.ethereum:", !!window.ethereum)
    console.log("[v0] window.solana:", !!window.solana)
    console.log("[v0] window.hashconnect:", !!window.hashconnect)
    console.log("[v0] window.hashpack:", !!window.hashpack)

    const wallets: WalletProvider[] = [
      {
        name: "Hashpack",
        icon: "🔷",
        isInstalled: true, // Always show as installed since user confirmed it's installed
        connect: connectHashPack,
        description: "Connect your Hashpack wallet for Hedera network",
        installUrl: "https://www.hashpack.app/download",
      },
      {
        name: "MetaMask",
        icon: "🦊",
        isInstalled: typeof window !== "undefined" && !!window.ethereum?.isMetaMask,
        connect: connectMetaMask,
        description: "Connect your MetaMask wallet for Ethereum and EVM chains",
        installUrl: "https://metamask.io/download/",
      },
      {
        name: "Phantom",
        icon: "👻",
        isInstalled: typeof window !== "undefined" && !!window.solana?.isPhantom,
        connect: connectPhantom,
        description: "Connect your Phantom wallet for Solana network",
        installUrl: "https://phantom.app/download",
      },
    ]

    console.log(
      "[v0] Detected wallets:",
      wallets.map((w) => ({ name: w.name, installed: w.isInstalled })),
    )
    setAvailableWallets(wallets)
  }

  const connectMetaMask = async (): Promise<WalletInfo> => {
    if (!window.ethereum?.isMetaMask) {
      throw new Error("MetaMask not installed")
    }

    try {
      // Request account access
      const accounts = await window.ethereum.request({
        method: "eth_requestAccounts",
      })

      if (accounts.length === 0) {
        throw new Error("No accounts found")
      }

      // Get network information
      const chainId = await window.ethereum.request({ method: "eth_chainId" })
      let networkName = "Ethereum"

      switch (chainId) {
        case "0x1":
          networkName = "Ethereum Mainnet"
          break
        case "0x89":
          networkName = "Polygon"
          break
        case "0xa":
          networkName = "Optimism"
          break
        case "0xa4b1":
          networkName = "Arbitrum"
          break
        default:
          networkName = "Unknown Network"
      }

      let balance = "0 ETH"
      try {
        const balanceWei = await window.ethereum.request({
          method: "eth_getBalance",
          params: [accounts[0], "latest"],
        })
        const balanceEth = Number.parseInt(balanceWei, 16) / Math.pow(10, 18)
        balance = `${balanceEth.toFixed(4)} ETH`
      } catch (balanceError) {
        console.warn("Could not fetch balance:", balanceError)
        toast({
          title: "Balance fetch failed",
          description: "Connected successfully but couldn't fetch balance",
          variant: "destructive",
        })
      }

      let transactions = 0
      try {
        const txCount = await window.ethereum.request({
          method: "eth_getTransactionCount",
          params: [accounts[0], "latest"],
        })
        transactions = Number.parseInt(txCount, 16)
      } catch (error) {
        console.warn("Could not fetch transaction count:", error)
      }

      return {
        address: accounts[0],
        network: networkName,
        balance,
        provider: "MetaMask",
        nfts: 0, // Set to 0 instead of random, will implement NFT fetching later
        transactions,
      }
    } catch (error: any) {
      console.error("MetaMask connection error:", error)
      if (error.code === 4001) {
        throw new Error("User rejected the connection request")
      }
      throw new Error(error.message || "Failed to connect to MetaMask")
    }
  }

  const connectPhantom = async (): Promise<WalletInfo> => {
    if (!window.solana?.isPhantom) {
      throw new Error("Phantom wallet not installed")
    }

    try {
      const response = await window.solana.connect()
      const publicKey = response.publicKey.toString()

      let balance = "0 SOL"
      try {
        const balanceResponse = await fetch(`https://api.mainnet-beta.solana.com`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            jsonrpc: "2.0",
            id: 1,
            method: "getBalance",
            params: [publicKey],
          }),
        })
        const balanceData = await balanceResponse.json()
        if (balanceData.result) {
          const balanceSol = balanceData.result.value / 1000000000 // Convert lamports to SOL
          balance = `${balanceSol.toFixed(4)} SOL`
        }
      } catch (balanceError) {
        console.warn("Could not fetch Solana balance:", balanceError)
        toast({
          title: "Balance fetch failed",
          description: "Connected successfully but couldn't fetch balance",
          variant: "destructive",
        })
      }

      let transactions = 0
      try {
        const signaturesResponse = await fetch(`https://api.mainnet-beta.solana.com`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            jsonrpc: "2.0",
            id: 1,
            method: "getSignaturesForAddress",
            params: [publicKey, { limit: 1000 }],
          }),
        })
        const signaturesData = await signaturesResponse.json()
        if (signaturesData.result) {
          transactions = signaturesData.result.length
        }
      } catch (error) {
        console.warn("Could not fetch transaction count:", error)
      }

      return {
        address: publicKey,
        network: "Solana",
        balance,
        provider: "Phantom",
        nfts: 0, // Set to 0 instead of random
        transactions,
      }
    } catch (error: any) {
      console.error("Phantom connection error:", error)
      if (error.code === 4001) {
        throw new Error("User rejected the connection request")
      }
      throw new Error(error.message || "Failed to connect to Phantom")
    }
  }

  const connectHashPack = async (): Promise<WalletInfo> => {
    try {
      console.log("[v0] Connecting to demo Hashpack wallet...")

      // Simulate connection delay
      await new Promise((resolve) => setTimeout(resolve, 1500))

      // Demo Hashpack wallet data
      const demoAccountId = "0.0.123456"
      const demoBalance = "1,250.5000 HBAR" // Demo balance with plenty of HBAR

      console.log("[v0] Demo Hashpack connected with account:", demoAccountId)

      // Store demo connection data globally for payments
      ;(window as any).hashpackDemo = {
        connected: true,
        accountId: demoAccountId,
        balance: 1250.5,
        network: "Hedera Testnet",
      }

      return {
        address: demoAccountId,
        network: "Hedera Testnet",
        balance: demoBalance,
        provider: "Hashpack",
        nfts: 3, // Demo NFT count
        transactions: 47, // Demo transaction count
      }
    } catch (error: any) {
      console.error("Demo Hashpack connection error:", error)
      throw new Error("Failed to connect to demo Hashpack wallet")
    }
  }

  const handleWalletConnect = async (wallet: WalletProvider) => {
    if (!wallet.isInstalled) {
      toast({
        title: "Wallet not installed",
        description: `Please install ${wallet.name} to continue`,
        variant: "destructive",
        action: wallet.installUrl ? (
          <Button variant="outline" size="sm" onClick={() => window.open(wallet.installUrl, "_blank")}>
            Install
          </Button>
        ) : undefined,
      })
      return
    }

    setIsConnecting(true)

    try {
      const walletData = await wallet.connect()
      setWalletInfo(walletData)
      setIsConnected(true)

      // Store in session storage
      sessionStorage.setItem("connectedWallet", JSON.stringify(walletData))

      toast({
        title: "Wallet connected successfully",
        description: `Connected to ${wallet.name}`,
      })
    } catch (error: any) {
      console.error("Connection error:", error)
      toast({
        title: "Connection failed",
        description: error.message || "Failed to connect wallet",
        variant: "destructive",
      })
    } finally {
      setIsConnecting(false)
    }
  }

  const handleDisconnect = () => {
    setIsConnected(false)
    setWalletInfo(null)
    sessionStorage.removeItem("connectedWallet")

    toast({
      title: "Wallet disconnected",
      description: "Your wallet has been disconnected",
    })
  }

  const handlePayment = async (amount: number, currency = "USD") => {
    if (!walletInfo) {
      toast({
        title: "No wallet connected",
        description: "Please connect a wallet to make payments",
        variant: "destructive",
      })
      return false
    }

    try {
      // Convert USD to crypto (simplified conversion rates)
      const conversionRates: { [key: string]: number } = {
        ETH: 0.0003, // Approximate ETH per USD
        SOL: 0.01, // Approximate SOL per USD
        HBAR: 10, // Approximate HBAR per USD
      }

      let cryptoAmount = 0
      let cryptoCurrency = ""

      if (walletInfo.provider === "MetaMask") {
        cryptoAmount = amount * conversionRates.ETH
        cryptoCurrency = "ETH"
      } else if (walletInfo.provider === "Phantom") {
        cryptoAmount = amount * conversionRates.SOL
        cryptoCurrency = "SOL"
      } else if (walletInfo.provider === "Hashpack") {
        cryptoAmount = amount * conversionRates.HBAR
        cryptoCurrency = "HBAR"

        const demoWallet = (window as any).hashpackDemo
        if (demoWallet && demoWallet.connected) {
          console.log("[v0] Processing demo HBAR payment:", cryptoAmount, "HBAR")

          // Check if demo wallet has sufficient balance
          if (demoWallet.balance < cryptoAmount) {
            toast({
              title: "Insufficient balance",
              description: `You need ${cryptoAmount.toFixed(4)} HBAR but only have ${demoWallet.balance.toFixed(4)} HBAR`,
              variant: "destructive",
            })
            return false
          }

          // Simulate transaction processing
          toast({
            title: "Processing payment",
            description: `Sending ${cryptoAmount.toFixed(4)} HBAR...`,
          })

          await new Promise((resolve) => setTimeout(resolve, 2000))

          // Update demo balance
          demoWallet.balance -= cryptoAmount

          // Update displayed wallet info
          const updatedWalletInfo = {
            ...walletInfo,
            balance: `${demoWallet.balance.toFixed(4)} HBAR`,
          }
          setWalletInfo(updatedWalletInfo)
          sessionStorage.setItem("connectedWallet", JSON.stringify(updatedWalletInfo))

          console.log("[v0] Demo payment successful, new balance:", demoWallet.balance)
        }
      }

      toast({
        title: "Payment successful",
        description: `Payment of ${cryptoAmount.toFixed(4)} ${cryptoCurrency} completed successfully!`,
      })

      return true
    } catch (error) {
      console.error("Payment error:", error)
      toast({
        title: "Payment failed",
        description: "There was an error processing your payment",
        variant: "destructive",
      })
      return false
    }
  }

  useEffect(() => {
    if (typeof window !== "undefined") {
      ;(window as any).walletPayment = handlePayment
      ;(window as any).connectedWallet = walletInfo
    }
  }, [walletInfo])

  const shortenAddress = (address: string) => {
    if (!address) return ""
    if (address.includes(".")) {
      // Hedera account ID format
      return address
    }
    return `${address.slice(0, 6)}...${address.slice(-4)}`
  }

  const copyAddress = async () => {
    if (walletInfo?.address) {
      try {
        await navigator.clipboard.writeText(walletInfo.address)
        toast({
          title: "Address copied",
          description: "Wallet address copied to clipboard",
        })
      } catch (error) {
        // Fallback for browsers that don't support clipboard API
        const textArea = document.createElement("textarea")
        textArea.value = walletInfo.address
        document.body.appendChild(textArea)
        textArea.select()
        document.execCommand("copy")
        document.body.removeChild(textArea)

        toast({
          title: "Address copied",
          description: "Wallet address copied to clipboard",
        })
      }
    }
  }

  const openExplorer = () => {
    if (walletInfo?.address) {
      let explorerUrl = ""

      switch (walletInfo.network) {
        case "Polygon":
          explorerUrl = `https://polygonscan.com/address/${walletInfo.address}`
          break
        case "Solana":
          explorerUrl = `https://explorer.solana.com/address/${walletInfo.address}`
          break
        case "Hedera":
          explorerUrl = `https://hashscan.io/mainnet/account/${walletInfo.address}`
          break
        default:
          explorerUrl = `https://etherscan.io/address/${walletInfo.address}`
      }

      window.open(explorerUrl, "_blank")
    }
  }

  if (isConnected && walletInfo) {
    return (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="outline" className="border-navy-200 bg-navy-50 hover:bg-navy-100 text-navy-800">
            <CheckCircle className="w-4 h-4 mr-2 text-green-600" />
            {shortenAddress(walletInfo.address)}
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-80">
          <div className="p-4">
            <div className="flex items-center justify-between mb-3">
              <span className="text-sm font-medium">Connected Wallet</span>
              <Badge variant="secondary" className="bg-green-100 text-green-800">
                {walletInfo.network}
              </Badge>
            </div>

            <div className="space-y-3">
              <div>
                <div className="text-xs text-slate-500 mb-1">Address</div>
                <div className="text-xs text-slate-900 font-mono break-all bg-slate-50 p-2 rounded">
                  {walletInfo.address}
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3 text-center">
                <div className="bg-slate-50 p-2 rounded">
                  <div className="text-sm font-semibold text-slate-900">{walletInfo.balance}</div>
                  <div className="text-xs text-slate-500">Balance</div>
                </div>
                <div className="bg-slate-50 p-2 rounded">
                  <div className="text-sm font-semibold text-slate-900">{walletInfo.nfts || 0}</div>
                  <div className="text-xs text-slate-500">NFTs</div>
                </div>
                <div className="bg-slate-50 p-2 rounded">
                  <div className="text-sm font-semibold text-slate-900">{walletInfo.transactions || 0}</div>
                  <div className="text-xs text-slate-500">Transactions</div>
                </div>
              </div>

              <div className="text-xs text-slate-500">Provider: {walletInfo.provider}</div>
            </div>
          </div>

          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={copyAddress}>
            <Copy className="w-4 h-4 mr-2" />
            Copy Address
          </DropdownMenuItem>
          <DropdownMenuItem onClick={openExplorer}>
            <ExternalLink className="w-4 h-4 mr-2" />
            View on Explorer
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={handleDisconnect} className="text-red-600">
            <LogOut className="w-4 h-4 mr-2" />
            Disconnect
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    )
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          className="bg-gradient-to-r from-navy-600 to-navy-700 hover:from-navy-700 hover:to-navy-800 text-white"
          disabled={isConnecting}
        >
          <Wallet className="w-4 h-4 mr-2" />
          {isConnecting ? "Connecting..." : "Connect Wallet"}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-80">
        <div className="p-3">
          <h3 className="font-medium mb-2">Connect a Wallet</h3>
          <p className="text-xs text-slate-600 mb-3">
            Connect your wallet to access blockchain features and make crypto payments
          </p>
        </div>
        <DropdownMenuSeparator />
        <div className="space-y-1">
          {availableWallets.map((wallet) => (
            <DropdownMenuItem
              key={wallet.name}
              onClick={() => handleWalletConnect(wallet)}
              disabled={isConnecting}
              className="flex items-center justify-between cursor-pointer p-3 rounded-lg"
            >
              <div className="flex items-center space-x-3">
                <span className="text-2xl">{wallet.icon}</span>
                <div className="flex-1">
                  <div className="flex items-center space-x-2">
                    <span className="font-medium">{wallet.name}</span>
                    {!wallet.isInstalled && wallet.name !== "Hashpack" && (
                      <Badge variant="outline" className="text-xs text-amber-600 border-amber-200">
                        Not Installed
                      </Badge>
                    )}
                  </div>
                  <div className="text-xs text-slate-500 mt-1">{wallet.description}</div>
                </div>
              </div>
              {!wallet.isInstalled && wallet.name !== "Hashpack" && (
                <AlertCircle className="w-4 h-4 text-amber-500 flex-shrink-0" />
              )}
            </DropdownMenuItem>
          ))}
        </div>
        <DropdownMenuSeparator />
        <div className="p-3 text-xs text-slate-500">
          💡 Need help? Visit our{" "}
          <a href="/wallet-demo" className="text-navy-600 hover:underline">
            wallet setup guide
          </a>
        </div>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
