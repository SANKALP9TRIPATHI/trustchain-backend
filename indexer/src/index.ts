import { GraphService } from "./services/GraphService";
import { DatabaseService } from "./services/DatabaseService";
import { mapTransactionData } from "./mappers/TransactionMapper";
import { logger } from "./utils/logger";

(async () => {
  const graphService = new GraphService();
  const dbService = new DatabaseService();

  logger.info("Fetching transactions from subgraph...");
  const transactions = await graphService.fetchTransactions();

  for (const tx of transactions) {
    const mapped = mapTransactionData(tx);
    await dbService.saveTransaction(mapped);
  }

  logger.info("Indexing complete.");
})();
