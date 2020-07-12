import assert from 'assert';
import { ethers } from 'ethers';
import { SimpleStorageFactory, GovernanceOnchainEqualFactory } from '../../build/typechain';
import { SimpleStorage } from '../../build/typechain/SimpleStorage';
import { GovernanceOnchainEqual } from '../../build/typechain/GovernanceOnchainEqual';

let storageInstance: SimpleStorage;
let governanceInstance: GovernanceOnchainEqual;

let governors: ethers.Wallet[] = [
  new ethers.Wallet('0x' + '1'.repeat(64)),
  new ethers.Wallet('0x' + '2'.repeat(64)),
  new ethers.Wallet('0x' + '3'.repeat(64)),
  new ethers.Wallet('0x' + '4'.repeat(64)),
  new ethers.Wallet('0x' + '5'.repeat(64)),
];

export const OnchainEqual = () =>
  describe('Governance Onchain Equal', () => {
    let txId: ethers.BigNumber;

    it('deploys governance contract with initial governors', async () => {
      const governanceFactory = new GovernanceOnchainEqualFactory(global.provider.getSigner(0));

      const governorAddresses = governors.map((w) => w.address);
      governanceInstance = await governanceFactory.deploy(governorAddresses);

      for (const governorAddress of governorAddresses) {
        const isGovernor = await governanceInstance.isGovernor(governorAddress);
        assert.ok(isGovernor, 'should be governor');
      }

      const result = await governanceInstance.getGovernors();
      assert.deepEqual(result, governorAddresses, 'governor addresses should be set');

      const count = await governanceInstance.governorsCount();
      assert.strictEqual(count.toNumber(), governors.length);
    });

    it('checks if contract supports EIP-2767 Onchain Interface', async () => {
      const supports = await governanceInstance.supportsInterface('0x947133b4');
      assert.ok(supports, 'should support EIP-2767 Onchain Interface');
    });

    it('checks if contract supports EIP-2767 Equal Voting Rights Interface', async () => {
      const supports = await governanceInstance.supportsInterface('0xbfca4246');
      assert.ok(supports, 'should support EIP-2767 Equal Voting Rights Interface');
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

    it('creates a set consensus transaction checks for immediate execution', async () => {
      // setting 50% as consensus
      const data = governanceInstance.interface.encodeFunctionData('setConsensus', [1, 2]);

      txId = await governanceInstance
        .connect(global.provider)
        .callStatic.createTransaction(governanceInstance.address, 0, data, {
          // @ts-ignore https://github.com/ethereum-ts/TypeChain/pull/258
          from: governors[0].address,
        });

      const requiredBefore = await governanceInstance.required();
      assert.strictEqual(requiredBefore.toNumber(), 0, 'required should be 0 initially');

      await governanceInstance
        .connect(governors[0].connect(global.provider))
        .createTransaction(governanceInstance.address, 0, data);

      // since before setting consensus, required consensus is zero, the transaction gets executed
      const t = await governanceInstance.getTransaction(txId);
      assert.ok(t.executed, 'should be executed');

      const consensus = await governanceInstance.getConsensus();
      assert.strictEqual(consensus[0].toNumber(), 1, 'numerator should be set 1');
      assert.strictEqual(consensus[1].toNumber(), 2, 'denominator should be set 2');

      const requiredAfter = await governanceInstance.required();
      assert.strictEqual(requiredAfter.toNumber(), 3, 'required should be 3 as 50%+ of 5');
    });

    it('creates a transaction from first governor to update storage and tries to execute it expecting revert', async () => {
      const data = storageInstance.interface.encodeFunctionData('setText', ['ilovemusic']);

      txId = await governanceInstance
        .connect(global.provider)
        .callStatic.createTransaction(storageInstance.address, 0, data, {
          // @ts-ignore https://github.com/ethereum-ts/TypeChain/pull/258
          from: governors[0].address,
        });

      await governanceInstance
        .connect(governors[0].connect(global.provider))
        .createTransaction(storageInstance.address, 0, data);

      const t = await governanceInstance.getTransaction(txId);
      assert.strictEqual(t.votes.toNumber(), 1, 'should get voted by self');

      try {
        await governanceInstance
          .connect(governors[0].connect(global.provider))
          .executeTransaction(txId);

        assert(false, 'should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('Gov: Consensus not acheived'), `Invalid error message: ${msg}`);
      }
    });

    it('tries to reconfirm transaction using governor 1 expecting revert', async () => {
      try {
        await governanceInstance
          .connect(governors[0].connect(global.provider))
          .confirmTransaction(txId);

        assert(false, 'should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('Gov: Already confirmed'), `Invalid error message: ${msg}`);
      }
    });

    it('confirms transaction using governor 2 and tries to execute expecting revert', async () => {
      await governanceInstance
        .connect(governors[1].connect(global.provider))
        .confirmTransaction(txId);

      const t = await governanceInstance.getTransaction(txId);
      assert.strictEqual(t.votes.toNumber(), 2, 'should get voted');

      try {
        await governanceInstance
          .connect(governors[1].connect(global.provider))
          .executeTransaction(txId);

        assert(false, 'should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('Gov: Consensus not acheived'), `Invalid error message: ${msg}`);
      }
    });

    it('confirms transaction using governor 3 and tx gets executed', async () => {
      await governanceInstance
        .connect(governors[2].connect(global.provider))
        .confirmTransaction(txId);

      const t = await governanceInstance.getTransaction(txId);
      assert.strictEqual(t.votes.toNumber(), 3, 'should get voted');
      assert.ok(t.executed, 'tx should be executed since 51% acheived');
    });

    it('tries to re-execute transaction expecting revert', async () => {
      try {
        await governanceInstance
          .connect(governors[1].connect(global.provider))
          .executeTransaction(txId);

        assert(false, 'should have thrown error');
      } catch (error) {
        const msg = error.error?.message || error.message;

        assert.ok(msg.includes('Gov: Tx already executed'), `Invalid error message: ${msg}`);
      }
    });
  });
