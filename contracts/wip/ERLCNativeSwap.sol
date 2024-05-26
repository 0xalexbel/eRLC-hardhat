// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2020 IEXEC BLOCKCHAIN TECH                                       *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IERC677.sol";
import "../ERLC.sol";

contract ERLCNativeSwap is ERLC {
    using SafeMath for uint256;

    uint256 public ConversionRate;
    uint8 private m_decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _softcap,
        address[] memory _admins,
        address[] memory _kycadmins
    ) ERLC(_name, _symbol, _softcap, _admins, _kycadmins) {
        ConversionRate = 10 ** SafeMath.sub(18, _decimals, "SafeMath: subtraction overflow");
        m_decimals = _decimals;
    }

    /*************************************************************************
     *                      Overload ERC20 decimals                          *
     *************************************************************************/

    function decimals() public view override returns (uint8) {
        return m_decimals;
    }

    /*************************************************************************
     *                       Escrow - public interface                       *
     *************************************************************************/
    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _mint(_msgSender(), msg.value.div(ConversionRate));
        Address.sendValue(payable(_msgSender()), msg.value.mod(ConversionRate));
    }

    function withdraw(uint256 amount) public {
        _burn(_msgSender(), amount);
        Address.sendValue(payable(_msgSender()), amount.mul(ConversionRate));
    }

    function recover()
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 delta = address(this).balance.sub(
            totalSupply().mul(ConversionRate), "SafeMath: subtraction overflow"
        );

        _mint(_msgSender(), delta.div(ConversionRate));
        Address.sendValue(payable(_msgSender()), delta.mod(ConversionRate));
    }

    function claim(
        address token,
        address to
    )
        public
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super.claim(token, to);
    }
}
