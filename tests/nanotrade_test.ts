import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can list innovation with valid inputs",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("nanotrade", "list-innovation", 
        [types.uint(1000000), types.utf8("Nano Sensor"), types.uint(5)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    block.receipts[0].result.expectOk().expectUint(0);
  },
});

Clarinet.test({
  name: "Ensure listing fails with invalid price",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("nanotrade", "list-innovation", 
        [types.uint(0), types.utf8("Nano Sensor"), types.uint(5)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr().expectUint(104);
  },
});

Clarinet.test({
  name: "Ensure listing fails with invalid royalty",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("nanotrade", "list-innovation", 
        [types.uint(1000000), types.utf8("Nano Sensor"), types.uint(101)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr().expectUint(105);
  },
});

Clarinet.test({
  name: "Ensure can purchase innovation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const buyer = accounts.get("wallet_1")!;
    const seller = accounts.get("wallet_2")!;
    
    // First list an innovation
    let block = chain.mineBlock([
      Tx.contractCall("nanotrade", "list-innovation",
        [types.uint(1000000), types.utf8("Nano Sensor"), types.uint(5)],
        seller.address
      )
    ]);
    
    // Then purchase it
    block = chain.mineBlock([
      Tx.contractCall("nanotrade", "purchase-innovation",
        [types.uint(0)],
        buyer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
  },
});
