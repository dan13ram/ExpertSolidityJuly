const { solidityKeccak256 } = require('ethers/lib/utils');
const keccak256 = require('keccak256');
const { MerkleTree } = require('merkletreejs');

const generateLeaf = (address, tier) =>
  Buffer.from(
    // Hash in appropriate Merkle format
    solidityKeccak256(['address', 'uint256'], [address, tier]).slice(2),
    'hex',
  );

class Snapshot {
  merkleTree;

  constructor(addresses, tiers) {
    this.merkleTree = new MerkleTree(
      addresses.map((address, i) => generateLeaf(address, tiers[i])),
      keccak256,
      { sortPairs: true },
    );
  }

  getMerkleRoot() {
    return this.merkleTree.getHexRoot();
  }

  getMerkleProof(address, tier) {
    const leaf = generateLeaf(address, tier);
    return this.merkleTree.getHexProof(leaf);
  }

  verifyAddress(address, tier) {
    const leaf = generateLeaf(address, tier);
    const proof = this.merkleTree.getHexProof(leaf);
    const root = this.getMerkleRoot();
    return this.merkleTree.verify(proof, leaf, root);
  }
}

module.exports.getSnapshot = (addresses, tiers) => {
  if (addresses.length != tiers.length) throw new Error('incorrect params');
  const snapshot = new Snapshot(addresses, tiers);
  return snapshot;
};
