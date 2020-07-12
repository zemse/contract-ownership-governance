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
      // setting 66% as consensus
      const data = governanceInstance.interface.encodeFunctionData('setConsensus', [2, 3]);

      const txId = await governanceInstance.callStatic.createTransaction(
        governanceInstance.address,
        0,
        data
      );

      const requiredBefore = await governanceInstance.required();
      assert.strictEqual(requiredBefore.toNumber(), 0, 'required should be 0 initially');

      await governanceInstance.createTransaction(governanceInstance.address, 0, data);

      // since before setting consensus, required consensus is zero, the transaction gets executed
      const t = await governanceInstance.getTransaction(txId);
      assert.ok(t.executed, 'should be executed');

      const consensus = await governanceInstance.getConsensus();
      assert.strictEqual(consensus[0].toNumber(), 2, 'numerator should be set 2');
      assert.strictEqual(consensus[1].toNumber(), 3, 'denominator should be set 3');

      const requiredAfter = await governanceInstance.required();
      assert.strictEqual(requiredAfter.toNumber(), 4, 'required should be 4 as 66%+ of 5');
    });
  });
