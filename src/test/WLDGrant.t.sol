// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {WLDGrant} from "../WLDGrant.sol";
import {IGrant} from "../IGrant.sol";

contract WLDGrantHarness is WLDGrant {
    function expose_calculateYearAndMonth(uint256 timestamp)
        public
        pure
        returns (uint256, uint256)
    {
        return _calculateYearAndMonth(timestamp);
    }

    function expose_monthsSinceAugust2024() public view returns (uint256) {
        return _monthsSinceAugust2024();
    }
}

/// @title WLDGrantTest
/// @notice Contains tests for the WLDGrant claims.
/// @author Worldcoin
contract WLDGrantTest is PRBTest {
    WLDGrant internal grant;
    WLDGrantHarness harness = new WLDGrantHarness();

    function setUp() public {
        grant = new WLDGrant();
    }

    ////////////////////////////////////////////////////////////////
    ///                        activeGrants                      ///
    ////////////////////////////////////////////////////////////////

    // function test_activeGrants_2024_08_01() public {
    //     for (uint64 timestamp = 1722470400; timestamp < 1724284800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 39);
    //         assertEq(two, 39);
    //     }
    // }

    // function test_activeGrants_2024_08_02() public {
    //     for (uint64 timestamp = 1724284800; timestamp < 1725148800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 39);
    //         assertEq(two, 39);
    //     }
    // }

    // function test_activeGrants_2024_09_01() public {

    //     for (uint64 timestamp = 1725148800; timestamp < 1726876800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 39);
    //         assertEq(two, 40);
    //     }
    // }

    // function test_activeGrants_2024_09_02() public {

    //     for (uint64 timestamp = 1726876800; timestamp < 1727740800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 39);
    //         assertEq(two, 40);
    //     }
    // }

    // function test_activeGrants_2024_10_01() public {

    //     for (uint64 timestamp = 1727740800; timestamp < 1729555200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 40);
    //         assertEq(two, 41);
    //     }
    // }

    // function test_activeGrants_2024_10_02() public {

    //     for (uint64 timestamp = 1729555200; timestamp < 1730419200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 40);
    //         assertEq(two, 41);
    //     }
    // }

    // function test_activeGrants_2024_11_01() public {

    //     for (uint64 timestamp = 1730419200; timestamp < 1732147200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 41);
    //         assertEq(two, 42);
    //     }
    // }

    // function test_activeGrants_2024_11_02() public {

    //     for (uint64 timestamp = 1732147200; timestamp < 1733011200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 41);
    //         assertEq(two, 42);
    //     }
    // }

    // function test_activeGrants_2024_12_01() public {

    //     for (uint64 timestamp = 1733011200; timestamp < 1734825600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 42);
    //         assertEq(two, 43);
    //     }
    // }

    // function test_activeGrants_2024_12_02() public {

    //     for (uint64 timestamp = 1734825600; timestamp < 1735689600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 42);
    //         assertEq(two, 43);
    //     }
    // }

    //     function test_activeGrants_2025_01_01() public {

    //     for (uint64 timestamp = 1735689600; timestamp < 1737504000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 43);
    //         assertEq(two, 44);
    //     }
    // }
    // function test_activeGrants_2025_01_02() public {

    //     for (uint64 timestamp = 1737504000; timestamp < 1738368000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 43);
    //         assertEq(two, 44);
    //     }
    // }
    // function test_activeGrants_2025_02_01() public {

    //     for (uint64 timestamp = 1738368000; timestamp < 1739923200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 44);
    //         assertEq(two, 45);
    //     }
    // }
    // function test_activeGrants_2025_02_02() public {

    //     for (uint64 timestamp = 1739923200; timestamp < 1740787200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 44);
    //         assertEq(two, 45);
    //     }
    // }
    // function test_activeGrants_2025_03_01() public {

    //     for (uint64 timestamp = 1740787200; timestamp < 1742601600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 45);
    //         assertEq(two, 46);
    //     }
    // }
    // function test_activeGrants_2025_03_02() public {

    //     for (uint64 timestamp = 1742601600; timestamp < 1743465600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 45);
    //         assertEq(two, 46);
    //     }
    // }
    // function test_activeGrants_2025_04_01() public {

    //     for (uint64 timestamp = 1743465600; timestamp < 1745193600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 46);
    //         assertEq(two, 47);
    //     }
    // }
    // function test_activeGrants_2025_04_02() public {

    //     for (uint64 timestamp = 1745193600; timestamp < 1746057600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 46);
    //         assertEq(two, 47);
    //     }
    // }
    // function test_activeGrants_2025_05_01() public {

    //     for (uint64 timestamp = 1746057600; timestamp < 1747872000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 47);
    //         assertEq(two, 48);
    //     }
    // }
    // function test_activeGrants_2025_05_02() public {

    //     for (uint64 timestamp = 1747872000; timestamp < 1748736000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 47);
    //         assertEq(two, 48);
    //     }
    // }
    // function test_activeGrants_2025_06_01() public {

    //     for (uint64 timestamp = 1748736000; timestamp < 1750464000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 48);
    //         assertEq(two, 49);
    //     }
    // }
    // function test_activeGrants_2025_06_02() public {

    //     for (uint64 timestamp = 1750464000; timestamp < 1751328000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 48);
    //         assertEq(two, 49);
    //     }
    // }
    // function test_activeGrants_2025_07_01() public {

    //     for (uint64 timestamp = 1751328000; timestamp < 1753142400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 49);
    //         assertEq(two, 50);
    //     }
    // }
    // function test_activeGrants_2025_07_02() public {

    //     for (uint64 timestamp = 1753142400; timestamp < 1754006400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 49);
    //         assertEq(two, 50);
    //     }
    // }
    // function test_activeGrants_2025_08_01() public {

    //     for (uint64 timestamp = 1754006400; timestamp < 1755820800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 50);
    //         assertEq(two, 51);
    //     }
    // }
    // function test_activeGrants_2025_08_02() public {

    //     for (uint64 timestamp = 1755820800; timestamp < 1756684800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 50);
    //         assertEq(two, 51);
    //     }
    // }
    // function test_activeGrants_2025_09_01() public {

    //     for (uint64 timestamp = 1756684800; timestamp < 1758412800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 51);
    //         assertEq(two, 52);
    //     }
    // }
    // function test_activeGrants_2025_09_02() public {

    //     for (uint64 timestamp = 1758412800; timestamp < 1759276800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 51);
    //         assertEq(two, 52);
    //     }
    // }
    // function test_activeGrants_2025_10_01() public {

    //     for (uint64 timestamp = 1759276800; timestamp < 1761091200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 52);
    //         assertEq(two, 53);
    //     }
    // }
    // function test_activeGrants_2025_10_02() public {

    //     for (uint64 timestamp = 1761091200; timestamp < 1761955200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 52);
    //         assertEq(two, 53);
    //     }
    // }
    // function test_activeGrants_2025_11_01() public {

    //     for (uint64 timestamp = 1761955200; timestamp < 1763683200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 53);
    //         assertEq(two, 54);
    //     }
    // }
    // function test_activeGrants_2025_11_02() public {

    //     for (uint64 timestamp = 1763683200; timestamp < 1764547200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 53);
    //         assertEq(two, 54);
    //     }
    // }
    // function test_activeGrants_2025_12_01() public {

    //     for (uint64 timestamp = 1764547200; timestamp < 1766361600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 54);
    //         assertEq(two, 55);
    //     }
    // }
    // function test_activeGrants_2025_12_02() public {

    //     for (uint64 timestamp = 1766361600; timestamp < 1767225600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 54);
    //         assertEq(two, 55);
    //     }
    // }

    // function test_activeGrants_2026_01_01() public {

    //     for (uint64 timestamp = 1767225600; timestamp < 1769040000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 55);
    //         assertEq(two, 56);
    //     }
    // }
    // function test_activeGrants_2026_01_02() public {

    //     for (uint64 timestamp = 1769040000; timestamp < 1769904000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 55);
    //         assertEq(two, 56);
    //     }
    // }
    // function test_activeGrants_2026_02_01() public {

    //     for (uint64 timestamp = 1769904000; timestamp < 1771459200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 56);
    //         assertEq(two, 57);
    //     }
    // }
    // function test_activeGrants_2026_02_02() public {

    //     for (uint64 timestamp = 1771459200; timestamp < 1772323200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 56);
    //         assertEq(two, 57);
    //     }
    // }
    // function test_activeGrants_2026_03_01() public {

    //     for (uint64 timestamp = 1772323200; timestamp < 1774137600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 57);
    //         assertEq(two, 58);
    //     }
    // }
    // function test_activeGrants_2026_03_02() public {

    //     for (uint64 timestamp = 1774137600; timestamp < 1775001600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 57);
    //         assertEq(two, 58);
    //     }
    // }
    // function test_activeGrants_2026_04_01() public {

    //     for (uint64 timestamp = 1775001600; timestamp < 1776729600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 58);
    //         assertEq(two, 59);
    //     }
    // }
    // function test_activeGrants_2026_04_02() public {

    //     for (uint64 timestamp = 1776729600; timestamp < 1777593600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 58);
    //         assertEq(two, 59);
    //     }
    // }
    // function test_activeGrants_2026_05_01() public {

    //     for (uint64 timestamp = 1777593600; timestamp < 1779408000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 59);
    //         assertEq(two, 60);
    //     }
    // }
    // function test_activeGrants_2026_05_02() public {

    //     for (uint64 timestamp = 1779408000; timestamp < 1780272000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 59);
    //         assertEq(two, 60);
    //     }
    // }
    // function test_activeGrants_2026_06_01() public {

    //     for (uint64 timestamp = 1780272000; timestamp < 1782000000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 60);
    //         assertEq(two, 61);
    //     }
    // }
    // function test_activeGrants_2026_06_02() public {

    //     for (uint64 timestamp = 1782000000; timestamp < 1782864000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 60);
    //         assertEq(two, 61);
    //     }
    // }
    // function test_activeGrants_2026_07_01() public {

    //     for (uint64 timestamp = 1782864000; timestamp < 1784678400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 61);
    //         assertEq(two, 62);
    //     }
    // }
    // function test_activeGrants_2026_07_02() public {

    //     for (uint64 timestamp = 1784678400; timestamp < 1785542400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 61);
    //         assertEq(two, 62);
    //     }
    // }
    // function test_activeGrants_2026_08_01() public {

    //     for (uint64 timestamp = 1785542400; timestamp < 1787356800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 62);
    //         assertEq(two, 63);
    //     }
    // }
    // function test_activeGrants_2026_08_02() public {

    //     for (uint64 timestamp = 1787356800; timestamp < 1788220800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 62);
    //         assertEq(two, 63);
    //     }
    // }
    // function test_activeGrants_2026_09_01() public {

    //     for (uint64 timestamp = 1788220800; timestamp < 1789948800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 63);
    //         assertEq(two, 64);
    //     }
    // }
    // function test_activeGrants_2026_09_02() public {

    //     for (uint64 timestamp = 1789948800; timestamp < 1790812800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 63);
    //         assertEq(two, 64);
    //     }
    // }
    // function test_activeGrants_2026_10_01() public {

    //     for (uint64 timestamp = 1790812800; timestamp < 1792627200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 64);
    //         assertEq(two, 65);
    //     }
    // }
    // function test_activeGrants_2026_10_02() public {

    //     for (uint64 timestamp = 1792627200; timestamp < 1793491200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 64);
    //         assertEq(two, 65);
    //     }
    // }
    // function test_activeGrants_2026_11_01() public {

    //     for (uint64 timestamp = 1793491200; timestamp < 1795219200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 65);
    //         assertEq(two, 66);
    //     }
    // }
    // function test_activeGrants_2026_11_02() public {

    //     for (uint64 timestamp = 1795219200; timestamp < 1796083200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 65);
    //         assertEq(two, 66);
    //     }
    // }
    // function test_activeGrants_2026_12_01() public {

    //     for (uint64 timestamp = 1796083200; timestamp < 1797897600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 66);
    //         assertEq(two, 67);
    //     }
    // }
    // function test_activeGrants_2026_12_02() public {

    //     for (uint64 timestamp = 1797897600; timestamp < 1798761600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 66);
    //         assertEq(two, 67);
    //     }
    // }

    // function test_activeGrants_2027_01_01() public {

    //     for (uint64 timestamp = 1798761600; timestamp < 1800576000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 67);
    //         assertEq(two, 68);
    //     }
    // }
    // function test_activeGrants_2027_01_02() public {

    //     for (uint64 timestamp = 1800576000; timestamp < 1801440000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 67);
    //         assertEq(two, 68);
    //     }
    // }
    // function test_activeGrants_2027_02_01() public {

    //     for (uint64 timestamp = 1801440000; timestamp < 1802995200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 68);
    //         assertEq(two, 69);
    //     }
    // }
    // function test_activeGrants_2027_02_02() public {

    //     for (uint64 timestamp = 1802995200; timestamp < 1803859200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 68);
    //         assertEq(two, 69);
    //     }
    // }
    // function test_activeGrants_2027_03_01() public {

    //     for (uint64 timestamp = 1803859200; timestamp < 1805673600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 69);
    //         assertEq(two, 70);
    //     }
    // }
    // function test_activeGrants_2027_03_02() public {

    //     for (uint64 timestamp = 1805673600; timestamp < 1806537600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 69);
    //         assertEq(two, 70);
    //     }
    // }
    // function test_activeGrants_2027_04_01() public {

    //     for (uint64 timestamp = 1806537600; timestamp < 1808265600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 70);
    //         assertEq(two, 71);
    //     }
    // }
    // function test_activeGrants_2027_04_02() public {

    //     for (uint64 timestamp = 1808265600; timestamp < 1809129600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 70);
    //         assertEq(two, 71);
    //     }
    // }
    // function test_activeGrants_2027_05_01() public {

    //     for (uint64 timestamp = 1809129600; timestamp < 1810944000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 71);
    //         assertEq(two, 72);
    //     }
    // }
    // function test_activeGrants_2027_05_02() public {

    //     for (uint64 timestamp = 1810944000; timestamp < 1811808000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 71);
    //         assertEq(two, 72);
    //     }
    // }
    // function test_activeGrants_2027_06_01() public {

    //     for (uint64 timestamp = 1811808000; timestamp < 1813536000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 72);
    //         assertEq(two, 73);
    //     }
    // }
    // function test_activeGrants_2027_06_02() public {

    //     for (uint64 timestamp = 1813536000; timestamp < 1814400000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 72);
    //         assertEq(two, 73);
    //     }
    // }
    // function test_activeGrants_2027_07_01() public {

    //     for (uint64 timestamp = 1814400000; timestamp < 1816214400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 73);
    //         assertEq(two, 74);
    //     }
    // }
    // function test_activeGrants_2027_07_02() public {

    //     for (uint64 timestamp = 1816214400; timestamp < 1817078400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 73);
    //         assertEq(two, 74);
    //     }
    // }
    // function test_activeGrants_2027_08_01() public {

    //     for (uint64 timestamp = 1817078400; timestamp < 1818892800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 74);
    //         assertEq(two, 75);
    //     }
    // }
    // function test_activeGrants_2027_08_02() public {

    //     for (uint64 timestamp = 1818892800; timestamp < 1819756800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 74);
    //         assertEq(two, 75);
    //     }
    // }
    // function test_activeGrants_2027_09_01() public {

    //     for (uint64 timestamp = 1819756800; timestamp < 1821484800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 75);
    //         assertEq(two, 76);
    //     }
    // }
    // function test_activeGrants_2027_09_02() public {

    //     for (uint64 timestamp = 1821484800; timestamp < 1822348800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 75);
    //         assertEq(two, 76);
    //     }
    // }
    // function test_activeGrants_2027_10_01() public {

    //     for (uint64 timestamp = 1822348800; timestamp < 1824163200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 76);
    //         assertEq(two, 77);
    //     }
    // }
    // function test_activeGrants_2027_10_02() public {

    //     for (uint64 timestamp = 1824163200; timestamp < 1825027200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 76);
    //         assertEq(two, 77);
    //     }
    // }
    // function test_activeGrants_2027_11_01() public {

    //     for (uint64 timestamp = 1825027200; timestamp < 1826755200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 77);
    //         assertEq(two, 78);
    //     }
    // }
    // function test_activeGrants_2027_11_02() public {

    //     for (uint64 timestamp = 1826755200; timestamp < 1827619200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 77);
    //         assertEq(two, 78);
    //     }
    // }
    // function test_activeGrants_2027_12_01() public {

    //     for (uint64 timestamp = 1827619200; timestamp < 1829433600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 78);
    //         assertEq(two, 79);
    //     }
    // }
    // function test_activeGrants_2027_12_02() public {

    //     for (uint64 timestamp = 1829433600; timestamp < 1830297600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 78);
    //         assertEq(two, 79);
    //     }
    // }

    // function test_activeGrants_2028_01_01() public {

    //     for (uint64 timestamp = 1830297600; timestamp < 1832112000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 79);
    //         assertEq(two, 80);
    //     }
    // }
    // function test_activeGrants_2028_01_02() public {

    //     for (uint64 timestamp = 1832112000; timestamp < 1832976000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 79);
    //         assertEq(two, 80);
    //     }
    // }
    // function test_activeGrants_2028_02_01() public {

    //     for (uint64 timestamp = 1832976000; timestamp < 1834617600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 80);
    //         assertEq(two, 81);
    //     }
    // }
    // function test_activeGrants_2028_02_02() public {

    //     for (uint64 timestamp = 1834617600; timestamp < 1835481600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 80);
    //         assertEq(two, 81);
    //     }
    // }
    // function test_activeGrants_2028_03_01() public {

    //     for (uint64 timestamp = 1835481600; timestamp < 1837296000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 81);
    //         assertEq(two, 82);
    //     }
    // }
    // function test_activeGrants_2028_03_02() public {

    //     for (uint64 timestamp = 1837296000; timestamp < 1838160000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 81);
    //         assertEq(two, 82);
    //     }
    // }
    // function test_activeGrants_2028_04_01() public {

    //     for (uint64 timestamp = 1838160000; timestamp < 1839888000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 82);
    //         assertEq(two, 83);
    //     }
    // }
    // function test_activeGrants_2028_04_02() public {

    //     for (uint64 timestamp = 1839888000; timestamp < 1840752000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 82);
    //         assertEq(two, 83);
    //     }
    // }
    // function test_activeGrants_2028_05_01() public {

    //     for (uint64 timestamp = 1840752000; timestamp < 1842566400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 83);
    //         assertEq(two, 84);
    //     }
    // }
    // function test_activeGrants_2028_05_02() public {

    //     for (uint64 timestamp = 1842566400; timestamp < 1843430400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 83);
    //         assertEq(two, 84);
    //     }
    // }
    // function test_activeGrants_2028_06_01() public {

    //     for (uint64 timestamp = 1843430400; timestamp < 1845158400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 84);
    //         assertEq(two, 85);
    //     }
    // }
    // function test_activeGrants_2028_06_02() public {

    //     for (uint64 timestamp = 1845158400; timestamp < 1846022400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 84);
    //         assertEq(two, 85);
    //     }
    // }
    // function test_activeGrants_2028_07_01() public {

    //     for (uint64 timestamp = 1846022400; timestamp < 1847836800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 85);
    //         assertEq(two, 86);
    //     }
    // }
    // function test_activeGrants_2028_07_02() public {

    //     for (uint64 timestamp = 1847836800; timestamp < 1848700800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 85);
    //         assertEq(two, 86);
    //     }
    // }
    // function test_activeGrants_2028_08_01() public {

    //     for (uint64 timestamp = 1848700800; timestamp < 1850515200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 86);
    //         assertEq(two, 87);
    //     }
    // }
    // function test_activeGrants_2028_08_02() public {

    //     for (uint64 timestamp = 1850515200; timestamp < 1851379200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 86);
    //         assertEq(two, 87);
    //     }
    // }
    // function test_activeGrants_2028_09_01() public {

    //     for (uint64 timestamp = 1851379200; timestamp < 1853107200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 87);
    //         assertEq(two, 88);
    //     }
    // }
    // function test_activeGrants_2028_09_02() public {

    //     for (uint64 timestamp = 1853107200; timestamp < 1853971200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 87);
    //         assertEq(two, 88);
    //     }
    // }
    // function test_activeGrants_2028_10_01() public {

    //     for (uint64 timestamp = 1853971200; timestamp < 1855785600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 88);
    //         assertEq(two, 89);
    //     }
    // }
    // function test_activeGrants_2028_10_02() public {

    //     for (uint64 timestamp = 1855785600; timestamp < 1856649600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 88);
    //         assertEq(two, 89);
    //     }
    // }
    // function test_activeGrants_2028_11_01() public {

    //     for (uint64 timestamp = 1856649600; timestamp < 1858377600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 89);
    //         assertEq(two, 90);
    //     }
    // }
    // function test_activeGrants_2028_11_02() public {

    //     for (uint64 timestamp = 1858377600; timestamp < 1859241600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 89);
    //         assertEq(two, 90);
    //     }
    // }
    // function test_activeGrants_2028_12_01() public {

    //     for (uint64 timestamp = 1859241600; timestamp < 1861056000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 90);
    //         assertEq(two, 91);
    //     }
    // }
    // function test_activeGrants_2028_12_02() public {

    //     for (uint64 timestamp = 1861056000; timestamp < 1861920000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 90);
    //         assertEq(two, 91);
    //     }
    // }

    // function test_activeGrants_2029_01_01() public {

    //     for (uint64 timestamp = 1861920000; timestamp < 1863734400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 91);
    //         assertEq(two, 92);
    //     }
    // }
    // function test_activeGrants_2029_01_02() public {

    //     for (uint64 timestamp = 1863734400; timestamp < 1864598400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 91);
    //         assertEq(two, 92);
    //     }
    // }
    // function test_activeGrants_2029_02_01() public {

    //     for (uint64 timestamp = 1864598400; timestamp < 1866153600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 92);
    //         assertEq(two, 93);
    //     }
    // }
    // function test_activeGrants_2029_02_02() public {

    //     for (uint64 timestamp = 1866153600; timestamp < 1867017600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 92);
    //         assertEq(two, 93);
    //     }
    // }
    // function test_activeGrants_2029_03_01() public {

    //     for (uint64 timestamp = 1867017600; timestamp < 1868832000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 93);
    //         assertEq(two, 94);
    //     }
    // }
    // function test_activeGrants_2029_03_02() public {

    //     for (uint64 timestamp = 1868832000; timestamp < 1869696000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 93);
    //         assertEq(two, 94);
    //     }
    // }
    // function test_activeGrants_2029_04_01() public {

    //     for (uint64 timestamp = 1869696000; timestamp < 1871424000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 94);
    //         assertEq(two, 95);
    //     }
    // }
    // function test_activeGrants_2029_04_02() public {

    //     for (uint64 timestamp = 1871424000; timestamp < 1872288000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 94);
    //         assertEq(two, 95);
    //     }
    // }
    // function test_activeGrants_2029_05_01() public {

    //     for (uint64 timestamp = 1872288000; timestamp < 1874102400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 95);
    //         assertEq(two, 96);
    //     }
    // }
    // function test_activeGrants_2029_05_02() public {

    //     for (uint64 timestamp = 1874102400; timestamp < 1874966400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 95);
    //         assertEq(two, 96);
    //     }
    // }
    // function test_activeGrants_2029_06_01() public {

    //     for (uint64 timestamp = 1874966400; timestamp < 1876694400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 96);
    //         assertEq(two, 97);
    //     }
    // }
    // function test_activeGrants_2029_06_02() public {

    //     for (uint64 timestamp = 1876694400; timestamp < 1877558400; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 96);
    //         assertEq(two, 97);
    //     }
    // }
    // function test_activeGrants_2029_07_01() public {
    //     for (uint64 timestamp = 1877558400; timestamp < 1879372800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 97);
    //         assertEq(two, 98);
    //     }
    // }
    // function test_activeGrants_2029_07_02() public {
    //     for (uint64 timestamp = 1879372800; timestamp < 1880236800; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 97);
    //         assertEq(two, 98);
    //     }
    // }
    // function test_activeGrants_2029_08_01() public {
    //     for (uint64 timestamp = 1880236800; timestamp < 1882051200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 98);
    //         assertEq(two, 99);
    //     }
    // }
    // function test_activeGrants_2029_08_02() public {
    //     for (uint64 timestamp = 1882051200; timestamp < 1882915200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 98);
    //         assertEq(two, 99);
    //     }
    // }
    // function test_activeGrants_2029_09_01() public {
    //     for (uint64 timestamp = 1882915200; timestamp < 1884643200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 99);
    //         assertEq(two, 100);
    //     }
    // }
    // function test_activeGrants_2029_09_02() public {
    //     for (uint64 timestamp = 1884643200; timestamp < 1885507200; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 99);
    //         assertEq(two, 100);
    //     }
    // }
    // function test_activeGrants_2029_10_01() public {
    //     for (uint64 timestamp = 1885507200; timestamp < 1887321600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 100);
    //         assertEq(two, 101);
    //     }
    // }
    // function test_activeGrants_2029_10_02() public {
    //     for (uint64 timestamp = 1887321600; timestamp < 1888185600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 100);
    //         assertEq(two, 101);
    //     }
    // }

    // function test_activeGrants_2029_11_01() public {
    //     for (uint64 timestamp = 1888185600; timestamp < 1889913600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 101);
    //         assertEq(two, 102);
    //     }
    // }
    // function test_activeGrants_2029_11_02() public {
    //     for (uint64 timestamp = 1890777600 - (3600 * 24 * 2); timestamp < 1890777600; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 101);
    //         assertEq(two, 102);
    //     }
    // }

    // function test_activeGrants_2029_12_01() public {
    //     for (uint64 timestamp = 1890777600; timestamp < 1892592000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 102);
    //         assertEq(two, 103);
    //     }
    // }
    // function test_activeGrants_2029_12_02() public {
    //     for (uint64 timestamp = 1892592000; timestamp < 1893456000; timestamp++) {
    //         vm.warp(timestamp);
    //         (uint256 one, uint256 two) = grant.activeGrants();
    //         assertEq(one, 102);
    //         assertEq(two, 103);
    //     }
    // }

    ////////////////////////////////////////////////////////////////
    ///                       checkValidity                      ///
    ////////////////////////////////////////////////////////////////

    function test_checkValidity_August2024_grant39() public {
        vm.warp(1722470400);
        grant.checkValidity(39);
    }

    function test_checkValidity_September2024_grant39() public {
        vm.warp(1725148800);
        grant.checkValidity(39);
    }

    function test_checkValidity_September2024_grant40() public {
        vm.warp(1725148800);
        grant.checkValidity(40);
    }

    function test_checkValidity_January2026_grant55() public {
        vm.warp(1767225600);
        grant.checkValidity(55);
    }

    function test_checkValidity_January2026_grant56() public {
        vm.warp(1767225600);
        grant.checkValidity(56);
    }

    function test_checkValidity_February2026_grant56() public {
        vm.warp(1772323199);
        grant.checkValidity(56);
    }

    function test_checkValidity_Feburary2026_grant57() public {
        vm.warp(1772323199);
        grant.checkValidity(57);
    }

    function test_checkValidity_revertIfGrantIdLessThan21() public {
        vm.expectRevert(abi.encodeWithSelector(IGrant.InvalidGrant.selector));
        grant.checkValidity(20);
    }

    function test_checkValidity_revertIfGrantIdLessThan38ButGrant4LaunchHappened() public {
        vm.warp(1722470400);
        vm.expectRevert(abi.encodeWithSelector(IGrant.InvalidGrant.selector));
        grant.checkValidity(38);
    }

    ////////////////////////////////////////////////////////////////
    ///                         getAmount                        ///
    ////////////////////////////////////////////////////////////////

    function test_getAmount_grant30() public {
        vm.expectRevert(abi.encodeWithSelector(IGrant.InvalidGrant.selector));
        grant.getAmount(30);
    }

    function test_getAmount_grant38() public {
        vm.expectRevert(abi.encodeWithSelector(IGrant.InvalidGrant.selector));
        grant.getAmount(38);
    }

    function test_getAmount_grant39() public {
        assertEq(grant.getAmount(39), 6180000000000000000);
    }

    function test_getAmount_grant40() public {
        assertEq(grant.getAmount(40), 6000000000000000000);
    }

    function test_getAmount_grant75() public {
        assertEq(grant.getAmount(75), 960000000000000000);
    }

    function test_getAmount_grant88() public {
        assertEq(grant.getAmount(88), 370000000000000000);
    }

    function test_getAmount_grant89() public {
        vm.expectRevert(abi.encodeWithSelector(IGrant.InvalidGrant.selector));
        grant.getAmount(89);
    }

    function testFuzz_getAmount_RevertsIfOutsideBounds(uint256 grantId) public {
        vm.assume(grantId < 39 || grantId > 93);
        vm.expectRevert(abi.encodeWithSelector(IGrant.InvalidGrant.selector));
        grant.getAmount(grantId);
    }
}
