async function setOn(on) {
  await chrome.storage.local.set({ on: on });
  await chrome.action.setBadgeText({ text: on ? "ON" : "" });
  await chrome.action.setBadgeBackgroundColor({ color: "#22c55e" });
  return on ? "ON: se aplica solo en cada pestana" : "resaltado visible";
}

function render(on) {
  const b = document.getElementById("btn");
  const s = document.getElementById("st");
  b.textContent = on ? "DESACTIVAR" : "ACTIVAR";
  b.className = on ? "on" : "off";
  s.textContent = on ? "resaltado invisible" : "resaltado visible";
}

async function diag() {
  const s = document.getElementById("st");
  try {
    const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
    const tab = tabs && tabs[0];
    if (!tab || !tab.url || !/^https?:/.test(tab.url)) { s.textContent = "pestana no valida (usa http/https)"; return; }
    const res = await chrome.scripting.executeScript({
      target: { tabId: tab.id, allFrames: false },
      func: () => {
        const el = document.getElementById("qa-sel-invisible");
        const t = document.createElement("span");
        t.textContent = "x";
        t.style.cssText = "position:fixed;top:0;left:0;z-index:2147483647;";
        document.documentElement.appendChild(t);
        const cs = getComputedStyle(t, "::selection");
        const out = cs.backgroundColor + " | " + cs.color + " | style:" + (el ? "si" : "no");
        t.remove();
        return out;
      }
    });
    s.textContent = "diag: " + (res && res[0] ? res[0].result : "sin resultado");
  } catch (e) { s.textContent = "error diag: " + (e && e.message ? e.message : e); }
}

document.addEventListener("DOMContentLoaded", async () => {
  const s = await chrome.storage.local.get("on");
  render(!!s.on);
  document.getElementById("btn").addEventListener("click", async () => {
    const d = document.getElementById("st");
    try {
      const cur = await chrome.storage.local.get("on");
      const next = !cur.on;
      const msg = await setOn(next);
      render(next);
      d.textContent = msg;
    } catch (e) {
      d.textContent = "error: " + (e && e.message ? e.message : e);
    }
  });
  document.getElementById("diag").addEventListener("click", diag);
});
