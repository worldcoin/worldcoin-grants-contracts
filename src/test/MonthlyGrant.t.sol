// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {WorldIDIdentityManagerRouterMock} from "src/test/mock/WorldIDIdentityManagerRouterMock.sol";
import {TestERC20} from "./mock/TestERC20.sol";
import {RecurringGrantDrop} from "../RecurringGrantDrop.sol";
import {MonthlyGrant} from "../MonthlyGrant.sol";

/// @title MonthlyGrantTest
/// @notice Contains tests for the monthly claims.
/// @author Worldcoin
contract MonthlyGrantTest is PRBTest {
    uint256 public startTime = 1680307200; // Saturday, 1 April 2023 00:00:00 GMT
    MonthlyGrant internal monthlyGrant;

    function setUp() public {
        vm.warp(startTime);
        monthlyGrant = new MonthlyGrant(4, 2023, 1 ether);
    }

    /// @notice Tests that the id of first grant is 0.
    function testInitialMonth() public {
        vm.warp(startTime);
        assertEq(monthlyGrant.getCurrentId(), 0);
    }

    /// @notice Tests the ids of the next 100 grants.
    function testMoreMonths() public {
        // 100 pre-generated utc timestamps of 1st of each month at 00:00:00 
        // Python: from datetime import datetime, timezone;[int(datetime(2023+i//12,i%12+1,1,tzinfo=timezone.utc).timestamp()) for i in range(3,103)]
        uint32[100] memory startTimes = [1680307200, 1682899200, 1685577600, 1688169600, 1690848000, 1693526400, 1696118400, 1698796800, 1701388800, 1704067200, 1706745600, 1709251200, 1711929600, 1714521600, 1717200000, 1719792000, 1722470400, 1725148800, 1727740800, 1730419200, 1733011200, 1735689600, 1738368000, 1740787200, 1743465600, 1746057600, 1748736000, 1751328000, 1754006400, 1756684800, 1759276800, 1761955200, 1764547200, 1767225600, 1769904000, 1772323200, 1775001600, 1777593600, 1780272000, 1782864000, 1785542400, 1788220800, 1790812800, 1793491200, 1796083200, 1798761600, 1801440000, 1803859200, 1806537600, 1809129600, 1811808000, 1814400000, 1817078400, 1819756800, 1822348800, 1825027200, 1827619200, 1830297600, 1832976000, 1835481600, 1838160000, 1840752000, 1843430400, 1846022400, 1848700800, 1851379200, 1853971200, 1856649600, 1859241600, 1861920000, 1864598400, 1867017600, 1869696000, 1872288000, 1874966400, 1877558400, 1880236800, 1882915200, 1885507200, 1888185600, 1890777600, 1893456000, 1896134400, 1898553600, 1901232000, 1903824000, 1906502400, 1909094400, 1911772800, 1914451200, 1917043200, 1919721600, 1922313600, 1924992000, 1927670400, 1930089600, 1932768000, 1935360000, 1938038400, 1940630400];
        for (uint i=0;i<startTimes.length;i++) {
            vm.warp(startTimes[i]);
            assertEq(monthlyGrant.getCurrentId(), i);
        }
    }

}
