-include .env

build:; forge build

deploy-sepolia: 
	forge script script/DeployFundMe.s.sol:DeployFundMe --network sepolia --rpc-url $SEPOLIA_DEPLOYER 