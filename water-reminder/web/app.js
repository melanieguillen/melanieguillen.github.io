const STORAGE_KEYS = {
  refillTime: "waterReminder.refillTime",
  lastReminder: "waterReminder.lastReminder",
};

const EMPTY_AFTER_MS = 90 * 60 * 1000;
const LOW_THRESHOLD = 0.28;
const REMINDER_COOLDOWN_MS = 20 * 60 * 1000;

const water = document.getElementById("water");
const levelLabel = document.getElementById("levelLabel");
const statusLabel = document.getElementById("statusLabel");
const messageLabel = document.getElementById("messageLabel");
const refillButton = document.getElementById("refillButton");
const glassButton = document.getElementById("glassButton");
const notifyButton = document.getElementById("notifyButton");

function getRefillTime() {
  const saved = Number(localStorage.getItem(STORAGE_KEYS.refillTime));
  if (!saved || Number.isNaN(saved)) {
    const now = Date.now();
    localStorage.setItem(STORAGE_KEYS.refillTime, String(now));
    return now;
  }

  return saved;
}

function setRefillTime(time) {
  localStorage.setItem(STORAGE_KEYS.refillTime, String(time));
}

function setLastReminder(time) {
  localStorage.setItem(STORAGE_KEYS.lastReminder, String(time));
}

function getLastReminder() {
  return Number(localStorage.getItem(STORAGE_KEYS.lastReminder) || 0);
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function levelFromTime(now = Date.now()) {
  const elapsed = now - getRefillTime();
  return clamp(1 - elapsed / EMPTY_AFTER_MS, 0, 1);
}

function relativeText(targetTime) {
  const formatter = new Intl.RelativeTimeFormat(undefined, { numeric: "auto" });
  const diffMs = targetTime - Date.now();
  const diffMinutes = Math.round(diffMs / 60000);

  if (Math.abs(diffMinutes) < 60) {
    return formatter.format(diffMinutes, "minute");
  }

  return formatter.format(Math.round(diffMinutes / 60), "hour");
}

function requestNotifications() {
  if (!("Notification" in window)) {
    statusLabel.textContent = "Browser notifications are not supported here.";
    return;
  }

  Notification.requestPermission().then((permission) => {
    if (permission === "granted") {
      notifyButton.textContent = "Reminders enabled";
    }
  });
}

function maybeNotify(level) {
  if (!("Notification" in window) || Notification.permission !== "granted") {
    return;
  }

  if (level > LOW_THRESHOLD) {
    return;
  }

  const now = Date.now();
  const lastReminder = getLastReminder();
  if (now - lastReminder < REMINDER_COOLDOWN_MS) {
    return;
  }

  setLastReminder(now);

  const body = level <= 0
    ? "Your glass is empty. Drink water and tap the glass to refill it."
    : "Your glass is getting low. Time for a few sips.";

  new Notification("Water Reminder", { body });
}

function refillGlass() {
  const now = Date.now();
  setRefillTime(now);
  setLastReminder(0);
  render();
}

function render() {
  const level = levelFromTime();
  const percent = Math.round(level * 100);

  water.style.setProperty("--water-level", `${percent}%`);
  levelLabel.textContent = `${percent}%`;

  const emptyTime = getRefillTime() + EMPTY_AFTER_MS;
  statusLabel.textContent = `Empty ${relativeText(emptyTime)}`;

  if (level > 0.65) {
    messageLabel.textContent = "Your glass is still nice and full.";
  } else if (level > 0.30) {
    messageLabel.textContent = "Time for a few sips soon.";
  } else if (level > 0) {
    messageLabel.textContent = "Your water is running low.";
  } else {
    messageLabel.textContent = "Glass empty. Drink and tap to refill.";
  }

  maybeNotify(level);
}

refillButton.addEventListener("click", refillGlass);
glassButton.addEventListener("click", refillGlass);
notifyButton.addEventListener("click", requestNotifications);

if ("Notification" in window && Notification.permission === "granted") {
  notifyButton.textContent = "Reminders enabled";
}

render();
setInterval(render, 1000);
