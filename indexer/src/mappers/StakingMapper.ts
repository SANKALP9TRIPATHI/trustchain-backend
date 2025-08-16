export const mapStakingData = (staking: any) => {
  return {
    user: staking.user.toLowerCase(),
    amount: Number(staking.amount),
    timestamp: Number(staking.timestamp)
  };
};
