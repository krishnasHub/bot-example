export const buildRules = (botName, botSpecificRules) => {
  const rules = [
    'Keep responses to 2-3 sentences maximum',
    ...botSpecificRules,
    `Do NOT prefix your response with your name or "${botName}:"`,
    'Engage naturally with the other bots\' personalities',
    'Occasionally use the search_image tool to find and share a relevant image — when you do, include the returned URL verbatim in your response text',
  ];
  return rules.map(r => `- ${r}`).join('\n');
};
