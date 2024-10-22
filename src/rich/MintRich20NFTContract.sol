// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./MintRichCommonStorage.sol";
import "../libs/MintRich20PriceLib.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @custom:oz-upgrades-from MintRich20NFTContract
contract MintRich20NFTContract is ERC20PermitUpgradeable, MintRichCommonStorage, ReentrancyGuardUpgradeable {

    using Address for address payable;

    error PoolNotFound();
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        bytes32,
        bytes calldata
    ) external initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        __ReentrancyGuard_init();

        salePhase = SalePhase.PUBLIC;
        factoryAddress = msg.sender;
        MINT_RICH_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    modifier checkSalePhase() {
        require(salePhase == SalePhase.PUBLIC, "Public sale ended");
        _;

        if (activeSupply == MAX_SUPPLY_20) {
            salePhase = SalePhase.CLOSED;
            emit SaleClosed(address(this));
        }
    }

    function amountInBank() external view returns (uint256) {
        return bank20;
    }

    function owner() external view returns (address) {
        if (salePhase == SalePhase.CLOSED) {
            return address(0);
        }
        return IERC721(factoryAddress).ownerOf(uint256(uint160(address(this))));
    }

    function buy(uint256 amount) external payable nonReentrant checkSalePhase {
        require(amount > 0 && activeSupply + amount <= MAX_SUPPLY_20, "Buy amount exceeds MAX_SUPPLY_404 limit");

        (uint256 prices, uint256 fees) = buyQuota(amount);
        uint256 totalPrices = prices + fees;
        require(totalPrices <= msg.value, "Not enough ETH to buy NFTs");

        totalFees += fees;
        uint256 preSupply = activeSupply;
        activeSupply += amount;

        buyNFTs(amount);
        emit BuyItems(msg.sender, amount, prices, fees, preSupply, activeSupply);

        if (msg.value > totalPrices) {
            payable(msg.sender).sendValue(msg.value - totalPrices);
        }
    }

    function buyNFTs(uint256 amount) internal {
        address buyer = msg.sender;
        uint256 mintAmount = amount;

        if (bank20 > 0) {
            uint256 withdrawAmount = Math.min(amount, bank20);
            _transfer(address(this), buyer, withdrawAmount * 10 ** decimals());
            
            bank20 -= withdrawAmount;
            mintAmount = amount - withdrawAmount;
        }

        if (mintAmount > 0) {
            _mint(buyer, mintAmount * 10 ** decimals());
        }
    }

    function sell(uint256 amount) external nonReentrant checkSalePhase {
        require(amount > 0 && amount * 10 ** decimals() <= balanceOf(msg.sender), "Sell amount exceeds owned amount");
        
        (uint256 prices, uint256 fees) = sellQuota(amount);
        uint256 receivedPrices = prices - fees;

        totalFees += fees;
        uint256 preSupply = activeSupply;
        activeSupply -= amount;

        sellNFTs(amount);
        emit SellItems(msg.sender, amount, prices, fees, preSupply, activeSupply);

        payable(msg.sender).sendValue(receivedPrices);
    }

    function sellNFTs(uint256 amount) internal {
        transfer(address(this), amount * 10 ** decimals());
        bank20 += amount;
    }

    function buyQuota(uint256 amount) public view returns (uint256 prices, uint256 fees) {
        prices = MintRich20PriceLib.totalTokenPrices(activeSupply, amount);
        fees = (prices * PROTOCOL_FEE) / BASIS_POINTS;
    }
    
    function sellQuota(uint256 amount) public view returns (uint256 prices, uint256 fees) {
        prices = MintRich20PriceLib.totalTokenPrices(activeSupply - amount, amount);
        fees = (prices * PROTOCOL_FEE) / BASIS_POINTS;
    }

    function saleBalance() public view returns (uint256 balance) {
        balance = MintRich20PriceLib.totalTokenPrices(0, activeSupply);
    }

    function processSaleClosed() external nonReentrant {
        require(msg.sender == MINT_RICH_ADMIN, "Only admin can process");
        require(salePhase == SalePhase.CLOSED, "Sale not closed");

        uint256 liquidityETH = saleBalance();
        uint256 liquidityERC20 = 2e8 * 10 ** decimals();
        _mint(address(this), liquidityERC20);

        (address token0, address token1) = address(this) < WETH9 ? (address(this), WETH9) : (WETH9, address(this));
        (uint24 fee, address pool) = swapPool(token0, token1);
        if (pool == address(0)) {
            revert PoolNotFound();
        } else {
            IERC20(address(this)).approve(MINTSWAP_DEX_MANAGER, liquidityERC20);

            uint256 liquidityETHMin = 7.2 ether;
            uint256 liquidityERC20Min = 18e7 * 10 ** decimals();
            bool isToken0WETH9 = token0 == WETH9;

            MintParams memory params = MintParams({
                token0: token0,
                token1: token1,
                fee: fee,
                tickLower: -886800,
                tickUpper: 886800,
                amount0Desired: isToken0WETH9 ? liquidityETH : liquidityERC20,
                amount1Desired: isToken0WETH9 ? liquidityERC20 : liquidityETH,
                amount0Min: isToken0WETH9 ? liquidityETHMin : liquidityERC20Min,
                amount1Min: isToken0WETH9 ? liquidityERC20Min : liquidityETHMin,
                recipient: address(this),
                deadline: block.timestamp
            });

            Address.functionCallWithValue(MINTSWAP_DEX_MANAGER, abi.encodeWithSelector(
                MINTSWAP_DEX_MINT_SELECTOR,
                params
            ), liquidityETH);
            Address.functionCall(MINTSWAP_DEX_MANAGER, abi.encodeWithSelector(
                MINTSWAP_DEX_REFUNDETH_SELECTOR
            ));
        }

        Address.functionCall(factoryAddress, abi.encodeWithSelector(FACTORY_BURN_SELECTOR));
    }

    function swapPool(address token0, address token1) internal returns (uint24 fee, address pool) {
        fee = availablePool(token0, token1);
        if (fee == 0) {
            return (0, address(0));
        }

        bytes memory newPool = Address.functionCall(MINTSWAP_DEX_MANAGER,
            abi.encodeWithSelector(
                MINTSWAP_DEX_CREATEPOOL_SELECTOR,
                token0, 
                token1,
                fee,
                token0 == WETH9 ? 396140812571321687967719751680000 : 15845632502852867518708790
            ));

        pool = abi.decode(newPool, (address));
        return (fee, pool);
    }

    function availablePool(address token0, address token1) internal view returns(uint24 fee) {
        address pool;

        pool = computeAddress(token0, token1, 500);
        if (pool.code.length == 0) {
            return 500;
        }

        pool = computeAddress(token0, token1, 3000);
        if (pool.code.length == 0) {
            return 3000;
        }

        pool = computeAddress(token0, token1, 10000);
        if (pool.code.length == 0) {
            return 10000;
        }

        return 0;
    }

    function computeAddress(address token0, address token1, uint24 fee) internal pure returns (address pool) {
        require(token0 < token1);
        pool = address(uint160(uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        MINTSWAP_DEX_FACTORY,
                        keccak256(abi.encode(token0, token1, fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
        )));
    }

    function claimRewards(
        address claimer,
        uint256 totalRewards,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external nonReentrant {
        require(msg.sender == ROUTER_ADDRESS, "Invalid caller");

        address payable recipient = payable(claimer);
        require(_verfySigner(recipient, totalRewards, _v, _r, _s) == REWARDS_SIGNER, "Invalid signer");

        if (totalRewards <= rewardsClaimed[recipient]) {
            return;
        }

        uint256 toClaim = totalRewards - rewardsClaimed[recipient];
        require(toClaim <= totalFees - claimedFees, "Invalid claim amount");

        claimedFees += toClaim;
        rewardsClaimed[recipient] = totalRewards;
        emit ClaimRewards(recipient, toClaim);

        recipient.sendValue(toClaim);
    }

    function _verfySigner(
        address recipient,
        uint256 totalRewards,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (address _signer) {
        _signer = ECDSA.recover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    MINT_RICH_DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            keccak256("MintRichRewards(address recipient,uint256 totalRewards)"),
                            recipient,
                            totalRewards
                        )
                    )
                )
            ), _v, _r, _s
        );
    }

    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("MintRichNFTContract")),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    receive() external payable {}

}