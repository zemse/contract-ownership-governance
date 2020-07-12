import assert from 'assert';
import { ethers } from 'ethers';
import { SimpleStorageFactory, GovernanceOffchainPrivilegedFactory } from '../../build/typechain';
import { SimpleStorage } from '../../build/typechain/SimpleStorage';
import { GovernanceOffchainPrivileged } from '../../build/typechain/GovernanceOffchainPrivileged';

let storageInstance: SimpleStorage;
let governanceInstance: GovernanceOffchainPrivileged;

let governorsPowers: [ethers.Wallet, number][] = [
  [new ethers.Wallet('0x' + '1'.repeat(64)), 1],
  [new ethers.Wallet('0x' + '2'.repeat(64)), 1],
  [new ethers.Wallet('0x' + '3'.repeat(64)), 1],
  [new ethers.Wallet('0x' + '4'.repeat(64)), 1],
  [new ethers.Wallet('0x' + '5'.repeat(64)), 1],
];

export const OffchainPrivileged = () =>
  describe('Governance Offchain Privileged', () => {
    it('deploys governance contract with initial governors', async () => {
      const governanceFactory = new GovernanceOffchainPrivilegedFactory(
        global.provider.getSigner(0)
      );

      const governorAddresses = governorsPowers.map((vw) => vw[0].address);
      const governorPrivileges = governorsPowers.map((vw) => vw[1]);
      governanceInstance = await governanceFactory.deploy(governorAddresses, governorPrivileges);

      for (const governorAddress of governorAddresses) {
        const power = await governanceInstance.powerOf(governorAddress);
        assert.strictEqual(power.toNumber(), 1, 'should have 1 power');
      }

      const totalPower = await governanceInstance.totalPower();
      assert.strictEqual(
        totalPower.toNumber(),
        governorAddresses.length,
        'governor count should be correct'
      );
    });

    it('deploys simple storage contract', async () => {
      const storageFactory = new SimpleStorageFactory(global.provider.getSigner(0));

      storageInstance = await storageFactory.deploy();

      const currentOwner = await storageInstance.owner();
      assert.strictEqual(
        currentOwner,
        global.accounts[0],
        'governance contract address should be set'
      );
    });

    it('transfers ownership of simple storage contract to governance contract', async () => {
      await storageInstance.transferOwnership(governanceInstance.address);

      const currentOwner = await storageInstance.owner();
      assert.strictEqual(
        currentOwner,
        governanceInstance.address,
        'governance should be next governor'
      );
    });

    it('tries to call setText from normal wallet expecting revert', async () => {
      try {
        await storageInstance.setText('hi');

        assert(false, 'should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('SS: Only owner allowed'), `Invalid error message: ${msg}`);
      }
    });

    it('tries to setText though governance with unsorted signatures expecting revert', async () => {
      const data = storageInstance.interface.encodeFunctionData('setText', ['ilovemyplanet']);

      const nonce = await governanceInstance.transactionsCount();
      const signatures = await prepareSignatures(nonce, storageInstance.address, data);

      try {
        await governanceInstance.executeTransaction(
          nonce,
          storageInstance.address,
          data,
          signatures
        );

        assert(false, 'unsorted signatures should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('Gov: Invalid arrangement'), `Invalid error message: ${msg}`);
      }
    });

    it('executes setText though governance with sorted signatures', async () => {
      const data = storageInstance.interface.encodeFunctionData('setText', ['ilovemyplanet']);

      const nonce = await governanceInstance.transactionsCount();
      const signatures = await prepareSignatures(nonce, storageInstance.address, data, {
        sortSignatures: true,
      });

      await governanceInstance.executeTransaction(nonce, storageInstance.address, data, signatures);

      const text = await storageInstance.getText();
      assert.strictEqual(text, 'ilovemyplanet', 'text should be set in the storage');
    });

    it('tries to replay the existing transaction expecting revert', async () => {
      const data = storageInstance.interface.encodeFunctionData('setText', ['ilovemykeyboard']);

      const nonce = ethers.BigNumber.from(0);
      const signatures = await prepareSignatures(nonce, storageInstance.address, data, {
        sortSignatures: true,
      });

      try {
        await governanceInstance.executeTransaction(
          nonce,
          storageInstance.address,
          data,
          signatures
        );

        assert(false, 'should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('Gov: Nonce is already used'), `Invalid error message: ${msg}`);
      }
    });

    it('calls with 4/5 signatures success', async () => {
      const data = storageInstance.interface.encodeFunctionData('setText', ['ilovemykeyboard']);

      const nonce = await governanceInstance.transactionsCount();
      const signatures = await prepareSignatures(nonce, storageInstance.address, data, {
        sortSignatures: true,
      });

      await governanceInstance.executeTransaction(
        nonce,
        storageInstance.address,
        data,
        signatures.slice(0, 4)
      );

      const text = await storageInstance.getText();
      assert.strictEqual(text, 'ilovemykeyboard', 'text should be set in the storage');
    });

    it('tries with 3/5 signatures expecting revert', async () => {
      try {
        const data = storageInstance.interface.encodeFunctionData('setText', ['ilovemychair']);

        const nonce = await governanceInstance.transactionsCount();
        const signatures = await prepareSignatures(nonce, storageInstance.address, data, {
          sortSignatures: true,
        });

        await governanceInstance.executeTransaction(
          nonce,
          storageInstance.address,
          data,
          signatures.slice(0, 3)
        );

        assert(false, 'less signatures should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('Gov: Not 66% consensus'), `Invalid error message: ${msg}`);
      }
    });

    it('tries with duplicate signatures expecting revert', async () => {
      try {
        const data = storageInstance.interface.encodeFunctionData('setText', ['ilovemydesk']);

        const nonce = await governanceInstance.transactionsCount();
        const signatures = await prepareSignatures(nonce, storageInstance.address, data, {
          sortSignatures: true,
        });

        await governanceInstance.executeTransaction(
          nonce,
          storageInstance.address,
          data,
          Array(5).fill(signatures[0])
        );

        assert(false, 'duplicate signatures should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('Gov: Invalid arrangement'), `Invalid error message: ${msg}`);
      }
    });

    it('removes a governor', async () => {
      const data = governanceInstance.interface.encodeFunctionData('updatePower', [
        governorsPowers[0][0].address,
        0,
      ]);

      const nonce = await governanceInstance.transactionsCount();
      const signatures = await prepareSignatures(nonce, governanceInstance.address, data, {
        sortSignatures: true,
      });

      const governorPrivilegeBefore = await governanceInstance.powerOf(
        governorsPowers[0][0].address
      );
      const totalPowerBefore = await governanceInstance.totalPower();
      assert.strictEqual(
        governorPrivilegeBefore.toNumber(),
        1,
        'should have 1 governor power initially'
      );
      assert.deepEqual(totalPowerBefore.toNumber(), 5, 'intially there should be 5 governors');

      await governanceInstance.executeTransaction(
        nonce,
        governanceInstance.address,
        data,
        signatures
      );

      const governorPrivilegeAfter = await governanceInstance.powerOf(
        governorsPowers[0][0].address
      );
      const totalPowerAfter = await governanceInstance.totalPower();
      assert.strictEqual(governorPrivilegeAfter.toNumber(), 0, 'governor power should be zeroed');
      assert.deepEqual(totalPowerAfter.toNumber(), 4, 'governor count should be decreased by 1');

      // removing element from governorsPowers
      governorsPowers = governorsPowers.slice(1);
    });

    it('adds a governor', async () => {
      const newGovernor = ethers.Wallet.createRandom();
      const data = governanceInstance.interface.encodeFunctionData('updatePower', [
        newGovernor.address,
        1,
      ]);

      const nonce = await governanceInstance.transactionsCount();
      const signatures = await prepareSignatures(nonce, governanceInstance.address, data, {
        sortSignatures: true,
      });

      const newGovernorPowerBefore = await governanceInstance.powerOf(newGovernor.address);
      const totalPowerBefore = await governanceInstance.totalPower();

      assert.strictEqual(
        newGovernorPowerBefore.toNumber(),
        0,
        'should not be a governor initially'
      );
      assert.deepEqual(totalPowerBefore.toNumber(), 4, 'intially there should be 4 governors');

      const tx = await governanceInstance.executeTransaction(
        nonce,
        governanceInstance.address,
        data,
        signatures
      );
      const r = await tx.wait();
      // console.log(r.gasUsed.toNumber());

      const newGovernorPowerAfter = await governanceInstance.powerOf(newGovernor.address);
      const totalPowerAfter = await governanceInstance.totalPower();

      assert.strictEqual(newGovernorPowerAfter.toNumber(), 1, 'governor power should be given');
      assert.deepEqual(totalPowerAfter.toNumber(), 5, 'governor count should be same');

      // removing element from governorsPowers
      governorsPowers = governorsPowers.slice(1);
      governorsPowers.push([newGovernor, 1]);
    });
  });

async function prepareSignatures(
  nonce: ethers.BigNumber,
  to: string,
  data: string,
  options?: { sortSignatures: boolean }
): Promise<string[]> {
  const PREFIX = await governanceInstance.PREFIX();

  const digest = ethers.utils.keccak256(
    ethers.utils.concat([PREFIX, ethers.utils.hexZeroPad(nonce.toHexString(), 32), to, data])
  );

  let signatures = governorsPowers
    .map((w) => {
      return w[0]._signingKey().signDigest(digest);
    })
    .map(ethers.utils.joinSignature);

  if (options?.sortSignatures) {
    signatures = signatures.sort((signatureA, signatureB) => {
      const a = ethers.BigNumber.from(ethers.utils.recoverAddress(digest, signatureA));
      const b = ethers.BigNumber.from(ethers.utils.recoverAddress(digest, signatureB));
      return a.gt(b) ? 1 : -1;
    });
  }

  return signatures;
}
