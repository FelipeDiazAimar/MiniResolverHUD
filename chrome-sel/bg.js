async function badge(on) {
  try {
    await chrome.action.setBadgeText({ text: on ? "ON" : "" });
    await chrome.action.setBadgeBackgroundColor({ color: "#22c55e" });
  } catch (e) {}
}

async function syncBadge() {
  try {
    const s = await chrome.storage.local.get("on");
    await badge(!!(s && s.on));
  } catch (e) {}
}

chrome.runtime.onInstalled.addListener(syncBadge);
chrome.runtime.onStartup.addListener(syncBadge);
