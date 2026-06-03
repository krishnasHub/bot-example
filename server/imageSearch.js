const pexelsReady = () =>
  process.env.PEXELS_API_KEY && !process.env.PEXELS_API_KEY.startsWith('your_');

const googleReady = () =>
  process.env.GOOGLE_API_KEY && !process.env.GOOGLE_API_KEY.startsWith('your_') &&
  process.env.GOOGLE_CX && !process.env.GOOGLE_CX.startsWith('your_');

export const imageSearchEnabled = () => pexelsReady() || googleReady();

const searchPexels = async (query) => {
  if (!pexelsReady()) return null;
  try {
    const res = await fetch(
      `https://api.pexels.com/v1/search?query=${encodeURIComponent(query)}&per_page=5`,
      { headers: { Authorization: process.env.PEXELS_API_KEY } }
    );
    if (!res.ok) return null;
    const data = await res.json();
    if (!data.photos?.length) return null;
    const photo = data.photos[Math.floor(Math.random() * Math.min(3, data.photos.length))];
    return photo.src.large;
  } catch {
    return null;
  }
};

const searchGoogle = async (query) => {
  if (!googleReady()) return null;
  try {
    const res = await fetch(
      `https://www.googleapis.com/customsearch/v1?key=${process.env.GOOGLE_API_KEY}&cx=${process.env.GOOGLE_CX}&q=${encodeURIComponent(query)}&searchType=image&num=5`
    );
    if (!res.ok) return null;
    const data = await res.json();
    if (!data.items?.length) return null;
    const item = data.items[Math.floor(Math.random() * Math.min(3, data.items.length))];
    return item.link;
  } catch {
    return null;
  }
};

// Google takes precedence if both are configured
export const searchImage = async (query) =>
  (await searchGoogle(query)) ?? (await searchPexels(query));
