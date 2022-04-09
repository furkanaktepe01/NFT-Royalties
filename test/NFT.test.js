const NFT = artifacts.require("./NFT");

require('chai')
    .use(require('chai-as-promised'))
    .should()

contract('NFT', ([deployer, artist, owner1, owner2]) => {
    const cost = web3.utils.toWei('1', 'ether')
    const royaltyFee = 25 // 25%
    let nft

    beforeEach(async () => {
        nft = await NFT.new(
            "Famous Paintings",
            "PAINT",
            "ipfs://some_link_here/",
            royaltyFee, // 25%
            artist // Artist
        )
    })

    describe('deployment', () => {
        it('returns the deployer', async () => {
            const result = await nft.owner()
            result.should.equal(deployer)
        })

        it('returns the artist', async () => {
            const result = await nft.artist()
            result.should.equal(artist)
        })

        it('returns the royalty fee', async () => {
            const result = await nft.royaltyFee()
            result.toString().should.equal(royaltyFee.toString())
        })

        it('sets the royalty fee', async () => {
            const newRoyaltyFee = 50 // 50%

            await nft.setRoyaltyFee(newRoyaltyFee)

            const result = await nft.royaltyFee()
            result.toString().should.equal(newRoyaltyFee.toString())
        })
    })

    describe('royalties', async () => {
        const salePrice = web3.utils.toWei('10', 'ether')
        const totalRoyalty = salePrice * 0.25
        let result

        beforeEach(async () => {
            await nft.mint({ from: owner1, value: cost })
        })

        it('initially belongs to owner1', async () => {
            const result = await nft.balanceOf(owner1)
            result.toString().should.equal('1')
        })

        it('successfully transfers to owner2', async () => {
            await nft.approve(owner2, 1, { from: owner1 })
            await nft.transferFrom(owner1, owner2, 1, { from: owner2, value: salePrice })

            result = await nft.balanceOf(owner1)
            result.toString().should.equal('0')

            result = await nft.balanceOf(owner2)
            result.toString().should.equal('1')
        })

        it('updates ether balances', async () => {
            // Approve sale
            await nft.approve(owner2, 1, { from: owner1 })

            const artistBalanceBefore = await web3.eth.getBalance(artist)
            const owner1BalanceBefore = await web3.eth.getBalance(owner1)

            // Initiate transfer
            await nft.transferFrom(owner1, owner2, 1, { from: owner2, value: salePrice })

            const artistBalanceAfter = await web3.eth.getBalance(artist)
            const owner1BalanceAfter = await web3.eth.getBalance(owner1)  

            // If balances update, we know owner2 paid
            artistBalanceAfter.toString().should.equal((Number(artistBalanceBefore) + totalRoyalty).toString())
            owner1BalanceAfter.toString().should.equal((Number(owner1BalanceBefore) + (salePrice - totalRoyalty)).toString())
        })
    })
})