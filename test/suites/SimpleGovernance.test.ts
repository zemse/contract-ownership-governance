import assert from 'assert';
import { ethers } from 'ethers';
import { GovernanceFactory, GovernedStorageFactory } from '../../build/typechain/';
import { GovernedStorage } from '../../build/typechain/GovernedStorage';
import { Governance } from '../../build/typechain/Governance';

let governanceInstance: Governance;
let storageInstance: GovernedStorage;

const validatorWallets: ethers.Wallet[] = [
  new ethers.Wallet('0x' + '1'.repeat(64)),
  new ethers.Wallet('0x' + '2'.repeat(64)),
  new ethers.Wallet('0x' + '3'.repeat(64)),
  new ethers.Wallet('0x' + '4'.repeat(64)),
  new ethers.Wallet('0x' + '5'.repeat(64)),
];

export const SimpleGovernance = () =>
  describe('Simple Governance', () => {
    it('deploys governance contract with initial validators', async () => {
      const governanceFactory = new GovernanceFactory(global.provider.getSigner(0));

      const validatorAddresses = validatorWallets.map((vw) => vw.address);
      governanceInstance = await governanceFactory.deploy(validatorAddresses);

      for (const validatorAddress of validatorAddresses) {
        assert.ok(
          await governanceInstance.isValidator(validatorAddress),
          'should have become validator'
        );
      }

      const validatorCount = await governanceInstance.validatorCount();
      assert.strictEqual(
        validatorCount.toNumber(),
        validatorAddresses.length,
        'validator count should be correct'
      );
    });

    it('deploys storage contract with governance address as constructor arg', async () => {
      const storageFactory = new GovernedStorageFactory(global.provider.getSigner(0));

      storageInstance = await storageFactory.deploy(governanceInstance.address);

      const governanceAddress = await storageInstance.governance();
      assert.strictEqual(
        governanceAddress,
        governanceInstance.address,
        'governance contract address should be set'
      );
    });

    it('tries to call setText from normal wallet expecting revert', async () => {
      try {
        await storageInstance.setText('hi');

        assert(false, 'should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('Only governance allowed'), `Invalid error message: ${msg}`);
      }
    });

    it('calls setText though governance', async () => {
      const data = storageInstance.interface.encodeFunctionData('setText', ['ilovemyplanet']);

      await governanceInstance.makeGovernedCall(storageInstance.address, data);

      const text = await storageInstance.getText();
      assert.strictEqual(text, 'ilovemyplanet', 'text should be set in the storage');
    });
  });
