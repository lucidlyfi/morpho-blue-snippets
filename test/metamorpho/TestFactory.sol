// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {console} from "../../lib/forge-std/src/console.sol";
import {Test} from "../../lib/forge-std/src/Test.sol";
import {MetaMorphoFactory} from "../../lib/metamorpho/src/MetaMorphoFactory.sol";
import {IMetaMorpho, MarketAllocation} from "../../lib/metamorpho/src/interfaces/IMetaMorpho.sol";
import {MarketParamsLib} from "../../lib/metamorpho/lib/morpho-blue/src/libraries/MarketParamsLib.sol";
import {MarketParams, Id} from "../../lib/metamorpho/lib/morpho-blue/src/interfaces/IMorpho.sol";

import {MetaMorphoSnippets} from "../../src/metamorpho/MetaMorphoSnippets.sol";
import {IntegrationTest} from "../../lib/metamorpho/test/forge/helpers/IntegrationTest.sol";
import {IIrm} from "../../lib/metamorpho/lib/morpho-blue/src/interfaces/IIrm.sol";
import {IOracle} from "../../lib/metamorpho/lib/morpho-blue/src/interfaces/IOracle.sol";
import {MAX_FEE} from "../../lib/metamorpho/lib/morpho-blue/src/libraries/ConstantsLib.sol";
import {SafeCast} from "../../lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TestFactory is Test {
    address public immutable ADMIN_ADDRESS = 0x1b514df3413DA9931eB31f2Ab72e32c0A507Cad5;
    address public immutable MORPHO_VAULT_FACTORY_ADDRESS = 0xA9c3D3a366466Fa809d1Ae982Fb2c46E5fC41101;
    address public immutable WBTC_ADDRESS = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    MetaMorphoFactory _factory = MetaMorphoFactory(MORPHO_VAULT_FACTORY_ADDRESS);

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("http://127.0.0.1:1234"));
    }

    function testDeployNewVault() public {
        vm.startPrank(ADMIN_ADDRESS);
        IMetaMorpho newVault = _factory.createMetaMorpho(
            ADMIN_ADDRESS,
            86400,
            WBTC_ADDRESS,
            "Lucidly swBTC/wBTC 94.5 lltv wrapper",
            "swBTCwBTC94.5lltv",
            0xcfea05bc34a0ddc944166c0720f3c2f1f8d06951e0740dd50fd3130da96906dd
        );
        vm.stopPrank();

        vm.startPrank(ADMIN_ADDRESS);

        newVault.setCurator(ADMIN_ADDRESS);
        newVault.setIsAllocator(ADMIN_ADDRESS, true);

        MarketParams memory params = MarketParams(
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, // wBTC address
            0x8DB2350D78aBc13f5673A411D4700BCF87864dDE, // swBTC address
            0x99ADb404Ec05f43B897Ae2f917BfA7C5FDd24708, // oracle
            0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC, // irm
            945000000000000000 // lltv
        );

        newVault.submitCap(params, 1000e8);
        vm.warp(vm.getBlockTimestamp() + 86400);
        newVault.acceptCap(params);

        Id[] memory supplyQueue = new Id[](1);
        supplyQueue[0] = MarketParamsLib.id(params);

        newVault.setSupplyQueue(supplyQueue);
        vm.stopPrank();

        deal(WBTC_ADDRESS, ADMIN_ADDRESS, 100e8);

        vm.startPrank(ADMIN_ADDRESS);

        IERC20(WBTC_ADDRESS).approve(address(newVault), 100e8);
        newVault.deposit(20e8, msg.sender);

        vm.stopPrank();
    }
}
