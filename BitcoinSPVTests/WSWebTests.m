//
//  WSWebTests.m
//  BitcoinSPV
//
//  Created by Davide De Rosa on 07/12/14.
//  Copyright (c) 2014 Davide De Rosa. All rights reserved.
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

@interface WSWebUtilsTests : XCTestCase

@end

@implementation WSWebUtilsTests

- (void)setUp
{
    [super setUp];

    self.networkType = WSNetworkTypeTestnet3;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExplorers
{
    self.networkType = WSNetworkTypeTestnet3;
    
    WSWebExplorerObjectType objectType = WSWebExplorerObjectTypeTransaction;
    WSHash256 *hash = WSHash256FromHex(@"d5a5851dfa20a6404e4d4b7b6e0329c3952a29aa897f509b27457fb3c83920e5");
    
    NSDictionary *expURLStrings = @{WSWebExplorerProviderBiteasy: @"https://www.biteasy.com/testnet/transactions/d5a5851dfa20a6404e4d4b7b6e0329c3952a29aa897f509b27457fb3c83920e5",
                                    WSWebExplorerProviderBlockExplorer: @"https://blockexplorer.com/testnet/tx/d5a5851dfa20a6404e4d4b7b6e0329c3952a29aa897f509b27457fb3c83920e5",
                                    WSWebExplorerProviderBlockr: @"http://tbtc.blockr.io/tx/info/d5a5851dfa20a6404e4d4b7b6e0329c3952a29aa897f509b27457fb3c83920e5"};

    for (NSString *provider in [expURLStrings allKeys]) {
        id<WSWebExplorer> explorer = [WSWebExplorerFactory explorerForProvider:provider networkType:self.networkParameters.networkType];
        NSURL *url = [explorer URLForObjectType:objectType hash:hash];
        
        DDLogInfo(@"%@: %@", provider, [url absoluteURL]);
        XCTAssertEqualObjects([url absoluteString], expURLStrings[provider]);
    }
}

//- (void)testSweep
//{
//    WSKey *key = WSKeyFromWIF(self.networkParameters, @"cU5m4wLDcMPHVWqYRdRYzJDDZc6VKPFhLy5Fwcvb439e8N3EQipo"); // muqqZmhjF7u2nNmYTi7KoDpQh8TLvqBSTd
////    WSAddress *address = WSAddressFromString(self.networkParameters, @"muyDoehpBExCbRRXLtDUpw5DaTb33UZeyG");
//    WSAddress *address = WSAddressFromString(self.networkParameters, @"2N66DDrmjDCMM3yMSYtAQyAqRtasSkFhbmX");
//    id<WSWebExplorer> explorer = [WSWebExplorerFactory explorerForProvider:WSWebExplorerProviderBiteasy networkType:self.networkType];
//    
//    [explorer buildSweepTransactionsFromKey:key toAddress:address fee:0 maxTxSize:1000 callback:^(WSSignedTransaction *transaction) {
//        DDLogInfo(@"Transaction: %@", transaction);
//    } completion:^(NSUInteger numberOfTransactions) {
//        DDLogInfo(@"Total transactions: %u", numberOfTransactions);
//    } failure:^(NSError *error) {
//        DDLogError(@"Error building transactions: %@", error);
//    }];
//    
//    [self runForSeconds:5.0];
//}
//
//- (void)testSweepBIP38
//{
//    WSBIP38Key *bip38Key = WSBIP38KeyFromString(@"6PYLdaRqCvj77isRyypqsX2kZyPvM6ESG2LXbm7bXwNYfDbd1Q5KuYqvtZ"); // cU5m4wLDcMPHVWqYRdRYzJDDZc6VKPFhLy5Fwcvb439e8N3EQipo
//    WSAddress *address = WSAddressFromString(self.networkParameters, @"2N66DDrmjDCMM3yMSYtAQyAqRtasSkFhbmX");
//    NSString *passphrase = @"foobar";
//    id<WSWebExplorer> explorer = [WSWebExplorerFactory explorerForProvider:WSWebExplorerProviderBiteasy networkType:self.networkType];
//    
//    [explorer buildSweepTransactionsFromBIP38Key:bip38Key passphrase:passphrase toAddress:address fee:0 maxTxSize:1000 callback:^(WSSignedTransaction *transaction) {
//        DDLogInfo(@"Transaction: %@", transaction);
//    } completion:^(NSUInteger numberOfTransactions) {
//        DDLogInfo(@"Total transactions: %u", numberOfTransactions);
//    } failure:^(NSError *error) {
//        DDLogError(@"Error building transactions: %@", error);
//    }];
//    
//    [self runForSeconds:5.0];
//}
//
//- (void)testTicker
//{
//    id<WSWebTicker> ticker = [WSWebTickerFactory tickerForProvider:WSWebTickerProviderBitstamp];
//    
//    [ticker fetchRatesWithSuccess:^(NSDictionary *rates) {
//        DDLogInfo(@"Rates: %@", rates);
//    } failure:^(NSError *error) {
//        DDLogError(@"Error: %@", error);
//    }];
//    
//    [self runForSeconds:3.0];
//}
//
//- (void)testTickerMonitor
//{
//    WSWebTickerMonitor *monitor = [WSWebTickerMonitor sharedInstance];
//    
//    [monitor startWithProviders:[NSSet setWithObjects:WSWebTickerProviderBitstamp, WSWebTickerProviderBlockchain, nil] updateInterval:20.0];
//    
//    [[NSNotificationCenter defaultCenter] addObserverForName:WSWebTickerMonitorDidUpdateConversionRatesNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//        for (NSString *code in [monitor availableCurrencyCodes]) {
//            DDLogInfo(@"BTC/%@ = %@", code, [monitor averageConversionRateToCurrencyCode:code]);
//        }
//    }];
//
//    [self runForever];
//}

@end
