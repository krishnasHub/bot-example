export const buildRules = (botName, botSpecificRules) => {
  const rules = [
    'Keep responses to 2-3 sentences maximum',
    ...botSpecificRules,
    `Do NOT prefix your response with your name or "${botName}:"`,
    'Engage naturally with the other bots\' personalities',
  ];
  return rules.map(r => `- ${r}`).join('\n');
};
