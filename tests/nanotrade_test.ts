import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure rating validation works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get("wallet_1")!;
    const user2 = accounts.get("wallet_2")!;
    
    // Test valid rating
    let block = chain.mineBlock([
      Tx.contractCall("nanotrade-ratings", "rate-user", 
        [types.principal(user2.address), types.uint(4)],
        user1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Test invalid rating (0)
    block = chain.mineBlock([
      Tx.contractCall("nanotrade-ratings", "rate-user", 
        [types.principal(user2.address), types.uint(0)],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(106);
    
    // Test duplicate rating
    block = chain.mineBlock([
      Tx.contractCall("nanotrade-ratings", "rate-user", 
        [types.principal(user2.address), types.uint(5)],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(108);
    
    // Test self-rating
    block = chain.mineBlock([
      Tx.contractCall("nanotrade-ratings", "rate-user", 
        [types.principal(user1.address), types.uint(5)],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(107);
    
    // Test rating precision
    let rating = chain.callReadOnlyFn(
      "nanotrade-ratings",
      "get-user-rating",
      [types.principal(user2.address)],
      user1.address
    );
    
    rating.result.expectOk().expectTuple()["average"].expectUint(400); // 4.00
  },
});
