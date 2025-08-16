export const mapDeFiData = (interaction: any) => {
  return {
    user: interaction.user.toLowerCase(),
    protocol: interaction.protocol,
    action: interaction.action,
    amount: Number(interaction.amount),
    timestamp: Number(interaction.timestamp)
  };
};
