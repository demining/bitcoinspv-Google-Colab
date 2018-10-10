//
//  WSDownloadWalletTests.m
//  BitcoinSPV
//
//  Created by Davide De Rosa on 20/07/14.
//  Copyright (c) 2014 Davide De Rosa. All rights reserved.
//
//  https://github.com/keeshux
//
//  This file is part of BitcoinSPV.
//
//  BitcoinSPV is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  BitcoinSPV is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with BitcoinSPV.  If not, see <http://www.gnu.org/licenses/>.
//

#import "XCTestCase+BitcoinSPV.h"

#define WALLET_GAP_LIMIT            10

@interface WSDownloadWalletTests : XCTestCase

@property (nonatomic, strong) id<WSWallet> persistentWallet;
@property (nonatomic, assign) volatile BOOL stopOnSync;

@end

@implementation WSDownloadWalletTests

- (void)setUp
{
    [super setUp];

    self.networkType = WSNetworkTypeTestnet3;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:WSPeerGroupDidFinishDownloadNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self runForSeconds:3.0];
        if (self.stopOnSync) {
            [self stopRunning];
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:WSPeerGroupDidRelayTransactionNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        WSSignedTransaction *tx = note.userInfo[WSPeerGroupRelayTransactionKey];
        const BOOL isPublished = [note.userInfo[WSPeerGroupRelayIsPublishedKey] boolValue];
        NSString *peerHost = note.userInfo[WSPeerGroupPeerHostKey];

        DDLogInfo(@"Relayed transaction (%@, isPublished = %u): %@", peerHost, isPublished, tx);
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:WSPeerGroupDidRejectNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if (!note.userInfo[WSPeerGroupRejectTransactionIdKey]) {
            return;
        }
        WSHash256 *txId = note.userInfo[WSPeerGroupRejectTransactionIdKey];
        const BOOL wasPending = [note.userInfo[WSPeerGroupRejectWasPendingKey] boolValue];
        NSString *peerHost = note.userInfo[WSPeerGroupPeerHostKey];
        
        DDLogInfo(@"Rejected transaction (%@, wasPending = %u): %@", peerHost, wasPending, txId);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:WSWalletDidUpdateBalanceNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        id<WSWallet> wallet = note.object;
        
        DDLogInfo(@"Balance: %llu", [wallet balance]);
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:WSWalletDidUpdateAddressesNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        id<WSWallet> wallet = note.object;
        
        DDLogInfo(@"Receive address: %@", [wallet receiveAddress]);
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:WSWalletDidUpdateTransactionsMetadataNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSDictionary *metadataById = note.userInfo[WSWalletTransactionsMetadataKey];
        
        DDLogInfo(@"Mined transactions: %@", metadataById);
    }];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSync
{
    self.stopOnSync = YES;

    WSHDWallet *wallet = [[WSHDWallet alloc] initWithParameters:self.networkParameters
                                                           seed:[self walletSeed]
                                                     chainsPath:WSBIP32PathForAccount(0)
                                                       gapLimit:WALLET_GAP_LIMIT];
    [wallet saveToPath:[self walletPath]];
    self.persistentWallet = wallet;
    
    DDLogInfo(@"Receive address: %@", [wallet receiveAddress]);

    id<WSBlockStore> store = [self memoryStore];
    WSBlockChainDownloader *downloader = [[WSBlockChainDownloader alloc] initWithStore:store wallet:wallet];
    downloader.coreDataManager = [self persistentManager];
    
    WSPeerGroup *peerGroup = [[WSPeerGroup alloc] initWithParameters:self.networkParameters];
    peerGroup.maxConnections = 5;
    [peerGroup startConnections];
    [peerGroup startDownloadWithDownloader:downloader];
    [self runForever];
}

- (void)testRestartSync
{
    self.stopOnSync = YES;
    
    WSHDWallet *wallet = [self loadWallet];
    self.persistentWallet = wallet;
    
    DDLogInfo(@"Receive address: %@", [wallet receiveAddress]);
    
    id<WSBlockStore> store = [self memoryStore];
    WSBlockChainDownloader *downloader = [[WSBlockChainDownloader alloc] initWithStore:store wallet:wallet];
    downloader.coreDataManager = [self persistentManager];
    
    WSPeerGroup *peerGroup = [[WSPeerGroup alloc] initWithParameters:self.networkParameters];
    peerGroup.maxConnections = 5;
    [peerGroup startConnections];
    [peerGroup startDownloadWithDownloader:downloader];
    [self runForever];
}

- (void)testRescan
{
    self.stopOnSync = YES;
    
    WSHDWallet *wallet = [[WSHDWallet alloc] initWithParameters:self.networkParameters
                                                           seed:[self walletSeed]
                                                     chainsPath:WSBIP32PathForAccount(0)
                                                       gapLimit:WALLET_GAP_LIMIT];
    [wallet saveToPath:[self walletPath]];
    self.persistentWallet = wallet;
    
    DDLogInfo(@"Receive address: %@", [wallet receiveAddress]);
    
    id<WSBlockStore> store = [self memoryStore];
    WSBlockChainDownloader *downloader = [[WSBlockChainDownloader alloc] initWithStore:store wallet:wallet];
    downloader.coreDataManager = [self persistentManager];

    WSPeerGroup *peerGroup = [[WSPeerGroup alloc] initWithParameters:self.networkParameters];
    peerGroup.maxConnections = 5;
    [peerGroup startConnections];
    [peerGroup startDownloadWithDownloader:downloader];
    [peerGroup rescanBlockChain];
    [self runForever];
}

- (void)testChain
{
    id<WSBlockStore> store = [self memoryStore];
    WSBlockChain *chain = [[WSBlockChain alloc] initWithStore:store];
    [chain loadFromCoreDataManager:[self persistentManager]];
    
    DDLogInfo(@"Blockchain: %@", [chain descriptionWithMaxBlocks:50]);
}

- (void)testWallet
{
    WSHDWallet *wallet = [self loadWallet];
    NSArray *txs = wallet.sortedTransactions;

    DDLogInfo(@"Balance: %llu", wallet.balance);
    DDLogInfo(@"UTXO: %@", wallet.unspentOutputs);
    DDLogInfo(@"Transactions: %lu", (unsigned long)txs.count);

    for (WSSignedTransaction *tx in txs) {
        DDLogInfo(@"%@", tx);
        DDLogInfo(@"Sent:     %llu", [wallet sentValueByTransaction:tx]);
        DDLogInfo(@"Received: %llu", [wallet receivedValueFromTransaction:tx]);
        DDLogInfo(@"Internal: %u", [wallet isInternalTransaction:tx]);

        DDLogInfo(@"Value:    %lld", [wallet valueForTransaction:tx]);
        DDLogInfo(@"Fee:      %llu", [wallet feeForTransaction:tx]);
    }

    DDLogInfo(@"Receive addresses: %@", wallet.allReceiveAddresses);
    DDLogInfo(@"Change addresses: %@", wallet.allChangeAddresses);
    DDLogInfo(@"Watched receive addresses: %@", wallet.watchedReceiveAddresses);
    DDLogInfo(@"Used addresses: %@", wallet.usedAddresses);
    DDLogInfo(@"Current receive address: %@", wallet.receiveAddress);
    DDLogInfo(@"Current change address: %@", wallet.changeAddress);
}

- (void)testBasicTransaction
{
    WSHDWallet *wallet = [self loadWallet];

    WSAddress *address = WSAddressFromString(self.networkParameters, @"mnChN9xy1zvyixmkof6yKxPyuuTb6YDPTX");
    
    NSError *error;
    uint64_t value;
    WSTransactionBuilder *builder;
    WSSignedTransaction *tx;
    
    value = 500000;
    builder = [wallet buildTransactionToAddress:address forValue:value fee:0 error:&error];
    XCTAssertNotNil(builder, @"Unable to build transaction: %@", error);
    tx = [wallet signedTransactionWithBuilder:builder error:&error];
    XCTAssertNotNil(tx, @"Unable to sign transaction: %@", error);
    
    DDLogInfo(@"Tx (fee: %llu): %@", [builder fee], tx);
    
    value = [wallet balance] + 1;
    builder = [wallet buildTransactionToAddress:address forValue:value fee:0 error:&error];
    XCTAssertNil(builder, @"Should fail for insufficient funds");
    
    value = [wallet balance];
    builder = [wallet buildTransactionToAddress:address forValue:value fee:0 error:&error];
    XCTAssertNil(builder, @"Should fail for insufficient funds");
    
    builder = [wallet buildSweepTransactionToAddress:address fee:25000 error:&error];
    XCTAssertNotNil(builder, @"Unable to build wipe transaction: %@", error);
    XCTAssertEqual([builder fee], 25000);
    
    tx = [wallet signedTransactionWithBuilder:builder error:&error];
    XCTAssertNotNil(tx, @"Unable to sign transaction: %@", error);

    DDLogInfo(@"Wipe tx (fee: %llu): %@", [builder fee], tx);
}

- (void)testPublishTransactionSingleInput
{
    WSHDWallet *wallet = [self loadWallet];
    
    NSError *error;
    WSAddress *address = WSAddressFromString(self.networkParameters, @"mnChN9xy1zvyixmkof6yKxPyuuTb6YDPTX");
    const uint64_t value = 99000;

    WSTransactionBuilder *builder = [wallet buildTransactionToAddress:address forValue:value fee:0 error:&error];
    XCTAssertNotNil(builder, @"Unable to build transaction: %@", error);
    XCTAssertEqual([builder fee], 1000);

    WSSignedTransaction *tx = [wallet signedTransactionWithBuilder:builder error:&error];
    XCTAssertNotNil(tx, @"Unable to sign transaction: %@", error);

    DDLogInfo(@"Tx: %@", tx);
    
    WSPeerGroup *peerGroup = [[WSPeerGroup alloc] initWithParameters:self.networkParameters];
    peerGroup.maxConnections = 5;
    [peerGroup startConnections];
    [self runForSeconds:5.0];
    if (![peerGroup publishTransaction:tx]) {
        DDLogInfo(@"Publish failed, no connected peers");
        return;
    }
    [self runForever];
}

- (void)testPublishTransactionMultipleInputs
{
    WSHDWallet *wallet = [self loadWallet];
    
    NSArray *addresses = @[WSAddressFromString(self.networkParameters, @"mvm26jv7vPUruu9RAgo4fL5ib5ewirdrgR"),  // account 5
                           WSAddressFromString(self.networkParameters, @"n2Rne11pvJBtpVX7KkinPcSs5JJdpLPvaz")]; // account 6
    
    NSArray *values = @[@(120000),
                        @(350000)];
    
    NSMutableArray *txs = [[NSMutableArray alloc] initWithCapacity:2];

    for (NSUInteger i = 0; i < 2; ++i) {
        NSError *error;
        WSTransactionBuilder *builder = [wallet buildTransactionToAddress:addresses[i]
                                                                 forValue:[values[i] unsignedLongLongValue]
                                                                      fee:2500
                                                                    error:&error];

        XCTAssertNotNil(builder, @"Unable to build transaction: %@", error);
        XCTAssertEqual([builder fee], 2500);

        WSSignedTransaction *tx = [wallet signedTransactionWithBuilder:builder error:&error];
        XCTAssertNotNil(tx, @"Unable to sign transaction: %@", error);

        DDLogInfo(@"Tx: %@", tx);
        [txs addObject:tx];
    }
    
    WSPeerGroup *peerGroup = [[WSPeerGroup alloc] initWithParameters:self.networkParameters];
    peerGroup.maxConnections = 5;
    [peerGroup startConnections];
    [self runForSeconds:3.0];
    for (WSSignedTransaction *tx in txs) {
        [peerGroup publishTransaction:tx];
    }
    [self runForever];
}

#pragma mark Helpers

- (id<WSBlockStore>)memoryStore
{
    return [[WSMemoryBlockStore alloc] initWithParameters:self.networkParameters];
}

- (WSCoreDataManager *)persistentManager
{
    return [[WSCoreDataManager alloc] initWithPath:[self storePath] error:NULL];
}

- (WSHDWallet *)loadWallet
{
    return [WSHDWallet loadFromPath:[self walletPath] parameters:self.networkParameters seed:[self walletSeed]];
}

- (NSString *)storePath
{
    return [self mockNetworkPathForFilename:@"DownloadWalletTests" extension:@"sqlite"];
}

- (NSString *)walletPath
{
    return [self mockNetworkPathForFilename:@"DownloadWalletTests" extension:@"wallet"];
}

- (WSSeed *)walletSeed
{
//    // spam blocks around #205000 on testnet + dropped blocks analysis
//    const NSTimeInterval creationTime = WSTimestampFromISODate(@"2014-01-01") - NSTimeIntervalSince1970;
//    const NSTimeInterval creationTime = 1393813869 - NSTimeIntervalSince1970;
    
    const NSTimeInterval creationTime = WSTimestampFromISODate(@"2014-06-02") - NSTimeIntervalSince1970;
//    const NSTimeInterval creationTime = WSTimestampFromISODate(@"2014-07-16") - NSTimeIntervalSince1970;
//    const NSTimeInterval creationTime = 0.0;
    
    return WSSeedMake(@"remind crush angry snake speak refuse social hungry movie expect venue assault", creationTime);
}

@end
