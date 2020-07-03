/*
  In this file you should write tests for your smart contract as you progress in developing your smart contract. For reference of Mocha testing framework, you can check out https://devdocs.io/mocha/.
*/

/// @dev importing packages required
import assert from 'assert';
import { ethers } from 'ethers';
import { SimpleStorageFactory } from '../../build/typechain/';
import { SimpleStorage } from '../../build/typechain/SimpleStorage';

/// @dev when you make this true, the parseTx helper will output transaction gas consumption and logs
const DEBUG_MODE = false;

/// @dev initialize file level global variables, you can also register it global.ts if needed across files.
let simpleStorageInstance: SimpleStorage;

/// @dev this is another test case collection
export const SimpleStorageContract = () =>
  describe('Simple Storage Contract', () => {
    it('deploys Simple Storage contract from first account', async () => {
      /// @dev you create a contract factory for deploying contract. Refer to ethers.js documentation at https://docs.ethers.io/ethers.js/html/
      const simpleStorageContractFactory = new SimpleStorageFactory(
        global.provider.getSigner(global.accounts[0])
      );
      simpleStorageInstance = await simpleStorageContractFactory.deploy();

      assert.ok(simpleStorageInstance.address, 'conract address should be present');
    });

    it('changes storage text to a new text from first account', async () => {
      /// @dev you sign and submit a transaction to local blockchain (ganache) initialized on line 10.
      ///   you can use the parseTx wrapper to parse tx and output gas consumption and logs.
      ///   use parseTx with non constant methods
      await simpleStorageInstance.functions.setText('hi');

      /// @dev now get the text at storage
      const currentText = await simpleStorageInstance.functions.getText();

      /// @dev then comparing with expectation text
      assert.equal(currentText, 'hi', 'text set must be able to get');
    });

    it('tries to change storage text using second account expecting revert', async () => {
      const _simpleStorageInstance = simpleStorageInstance.connect(
        global.provider.getSigner(global.accounts[1])
      );

      try {
        await _simpleStorageInstance.functions.setText('hi');

        assert(false, 'should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('Only owner allowed'), `Invalid error message: ${msg}`);
      }
    });
  });
