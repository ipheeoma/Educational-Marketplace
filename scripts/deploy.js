async function main() {
  // Get the signer of the tx and address for deploying the contracts
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  try {
    // Step 1: Deploy the main Educational Content Marketplace contract
    console.log("\n=== Deploying Educational Content Marketplace ===");
    
    const EducationalContentMarketplace = await ethers.getContractFactory("EducationalContentMarketplace", deployer);
    const marketplace = await EducationalContentMarketplace.deploy(deployer.address);
    
    // Wait for deployment to be mined
    await marketplace.waitForDeployment();
    
    console.log("✅ EducationalContentMarketplace deployed at:", marketplace.target);
    console.log("✅ Owner address:", deployer.address);

    // Step 2: Verify contract deployment
    console.log("\n=== Verifying Deployment ===");
    
    // Check if contract is properly deployed
    const code = await ethers.provider.getCode(marketplace.target);
    if (code === "0x") {
      throw new Error("Contract deployment failed - no code at address");
    }
    console.log("✅ Contract code verified at address");

    // Step 3: Initialize contract with basic settings
    console.log("\n=== Initializing Contract ===");
    
    // Get initial contract state
    const marketplaceStats = await marketplace.getMarketplaceStats();
    console.log("📊 Initial marketplace stats:", {
      totalContent: marketplaceStats[0].toString(),
      activeContent: marketplaceStats[1].toString(),
      totalSales: marketplaceStats[2].toString(),
      totalRevenue: ethers.formatEther(marketplaceStats[3]),
      currentBlock: marketplaceStats[4].toString()
    });

    // Check platform parameters
    const platformFee = await marketplace.platformFeePercent();
    const defaultRoyalty = await marketplace.defaultRoyaltyPercent();
    const minPrice = await marketplace.minContentPrice();
    const maxPrice = await marketplace.maxContentPrice();
    
    console.log("⚙  Platform configuration:", {
      platformFeePercent: (platformFee / 100).toString() + "%",
      defaultRoyaltyPercent: (defaultRoyalty / 100).toString() + "%",
      minContentPrice: ethers.formatEther(minPrice) + " ETH",
      maxContentPrice: ethers.formatEther(maxPrice) + " ETH"
    });

    // Step 4: Verify roles are properly set
    console.log("\n=== Verifying Access Control ===");
    
    const DEFAULT_ADMIN_ROLE = await marketplace.DEFAULT_ADMIN_ROLE();
    const MODERATOR_ROLE = await marketplace.MODERATOR_ROLE();
    const CONTENT_MANAGER_ROLE = await marketplace.CONTENT_MANAGER_ROLE();
    const EMERGENCY_ROLE = await marketplace.EMERGENCY_ROLE();
    
    const hasAdminRole = await marketplace.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
    const hasModeratorRole = await marketplace.hasRole(MODERATOR_ROLE, deployer.address);
    const hasContentManagerRole = await marketplace.hasRole(CONTENT_MANAGER_ROLE, deployer.address);
    const hasEmergencyRole = await marketplace.hasRole(EMERGENCY_ROLE, deployer.address);
    
    console.log("🔐 Role assignments for deployer:", {
      adminRole: hasAdminRole ? "✅" : "❌",
      moderatorRole: hasModeratorRole ? "✅" : "❌", 
      contentManagerRole: hasContentManagerRole ? "✅" : "❌",
      emergencyRole: hasEmergencyRole ? "✅" : "❌"
    });

    // Step 5: Test basic functionality (optional)
    console.log("\n=== Testing Basic Functionality ===");
    
    // Test content hash generation
    const testHash = await marketplace.generateContentHash(
      deployer.address,
      "Test Course",
      "Test Description",
      Math.floor(Date.now() / 1000)
    );
    console.log("🧪 Generated test content hash:", testHash);

    // Check user creation status
    const [canCreate, statusHash] = await marketplace.canUserCreateContent(deployer.address);
    console.log("👤 Can deployer create content:", canCreate ? "✅ Yes" : "❌ No");

    // Step 6: Fund the contract for testing (optional)
    if (process.env.FUND_CONTRACT === "true") {
      console.log("\n=== Funding Contract ===");
      const fundAmount = ethers.parseEther("0.1"); // 0.1 ETH
      const fundTx = await marketplace.fundPlatform({ value: fundAmount });
      await fundTx.wait();
      console.log("💰 Contract funded with:", ethers.formatEther(fundAmount), "ETH");
    }

    // Step 7: Output deployment summary
    console.log("\n=== Deployment Summary ===");
    console.log("🎉 Educational Content Marketplace successfully deployed!");
    console.log("📍 Contract Address:", marketplace.target);
    console.log("👤 Owner Address:", deployer.address);
    console.log("⛽ Deployment Gas Used: Check transaction receipt");
    console.log("🌐 Network:", (await ethers.provider.getNetwork()).name);
    console.log("🔗 Block Number:", (await ethers.provider.getBlockNumber()).toString());
    
    // Save deployment info to file
    const deploymentInfo = {
      contractAddress: marketplace.target,
      ownerAddress: deployer.address,
      network: (await ethers.provider.getNetwork()).name,
      blockNumber: await ethers.provider.getBlockNumber(),
      timestamp: new Date().toISOString(),
      platformFeePercent: platformFee.toString(),
      defaultRoyaltyPercent: defaultRoyalty.toString(),
      minContentPrice: minPrice.toString(),
      maxContentPrice: maxPrice.toString()
    };

    // Write to file (if in Node.js environment)
    if (typeof require !== 'undefined') {
      const fs = require('fs');
      fs.writeFileSync('deployment.json', JSON.stringify(deploymentInfo, null, 2));
      console.log("📄 Deployment info saved to deployment.json");
    }

    return {
      contract: marketplace,
      address: marketplace.target,
      owner: deployer.address
    };

  } catch (error) {
    console.error("❌ Deployment failed:", error);
    throw error;
  }
}

// Enhanced error handling and execution
main()
  .then((result) => {
    console.log("\n✅ Deployment completed successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Deployment failed with error:", error);
    process.exit(1);
  });
