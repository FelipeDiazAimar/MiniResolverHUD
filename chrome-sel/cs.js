const QA_CSS = "html *::selection{background:transparent!important;color:inherit!important;text-shadow:none!important}html input::selection,html textarea::selection{background:transparent!important;color:inherit!important}";
const QA_ID = "qa-sel-invisible";

function qaApply(on) {
  try {
    const root = document.head || document.documentElement;
    if (!root) return;
    let st = document.getElementById(QA_ID);
    if (on) {
      if (!st) {
        st = document.createElement("style");
        st.id = QA_ID;
        st.textContent = QA_CSS;
        root.appendChild(st);
      }
    } else if (st) {
      st.remove();
    }
  } catch (e) {}
}

try {
  chrome.storage.local.get("on", (s) => { qaApply(!!(s && s.on)); });
  chrome.storage.onChanged.addListener((ch, area) => {
    if (area === "local" && ch.on) qaApply(!!ch.on.newValue);
  });
} catch (e) {}
