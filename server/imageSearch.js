export const searchImage = async (query) => {
  const apiKey = process.env.PEXELS_API_KEY;
  if (!apiKey || apiKey.startsWith('your_')) return null;

  try {
    const res = await fetch(
      `https://api.pexels.com/v1/search?query=${encodeURIComponent(query)}&per_page=5`,
      { headers: { Authorization: apiKey } }
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
