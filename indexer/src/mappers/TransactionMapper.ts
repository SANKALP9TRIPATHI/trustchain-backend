export const mapTransactionData = (tx: any) => {
  return {
    user: tx.from.toLowerCase(),
    hash: tx.id,
    amount: Number(tx.value),
    timestamp: Number(tx.timestamp)
  };
};
