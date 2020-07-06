import assert from 'assert';
import { ethers } from 'ethers';
import { SimpleStorageFactory, GovernanceOffchainFactory } from '../../build/typechain/';
import { SimpleStorage } from '../../build/typechain/SimpleStorage';
import { GovernanceOffchain } from '../../build/typechain/GovernanceOffchain';

let governanceInstance: GovernanceOffchain;
let storageInstance: SimpleStorage;

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
      const governanceFactory = new GovernanceOffchainFactory(global.provider.getSigner(0));

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
        'governance should be next owner'
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
        await governanceInstance.makeGovernedCall(nonce, storageInstance.address, data, signatures);

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

      await governanceInstance.makeGovernedCall(nonce, storageInstance.address, data, signatures);

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
        await governanceInstance.makeGovernedCall(nonce, storageInstance.address, data, signatures);

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

      await governanceInstance.makeGovernedCall(
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

        await governanceInstance.makeGovernedCall(
          nonce,
          storageInstance.address,
          data,
          signatures.slice(0, 3)
        );

        assert(false, 'less signatures should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('Gov: Not 66% validators'), `Invalid error message: ${msg}`);
      }
    });

    it('tries with duplicate signatures expecting revert', async () => {
      try {
        const data = storageInstance.interface.encodeFunctionData('setText', ['ilovemydesk']);

        const nonce = await governanceInstance.transactionsCount();
        const signatures = await prepareSignatures(nonce, storageInstance.address, data, {
          sortSignatures: true,
        });

        await governanceInstance.makeGovernedCall(
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
  });

async function prepareSignatures(
  nonce: ethers.BigNumber,
  to: string,
  data: string,
  options?: { sortSignatures: boolean }
): Promise<string[]> {
  const PREFIX = await governanceInstance.PREFIX();
  const DOMAIN_SEPERATOR = await governanceInstance.DOMAIN_SEPERATOR();

  const digest = ethers.utils.keccak256(
    ethers.utils.concat([
      PREFIX,
      DOMAIN_SEPERATOR,
      ethers.utils.hexZeroPad(nonce.toHexString(), 32),
      to,
      data,
    ])
  );

  let signatures = validatorWallets
    .map((w) => {
      return w._signingKey().signDigest(digest);
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
