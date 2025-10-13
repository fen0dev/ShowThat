/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
*/

const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const UAParser = require("ua-parser-js");
const geoip = require("geoip-lite");

admin.initializeApp();

// Imposta regione e limiti
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

// Endpoint di tracking scansioni QR
exports.trackQRScan = onRequest(async (req, res) => {
  // CORS base
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "GET, POST");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.set("Access-Control-Max-Age", "3600");
    return res.status(204).send("");
  }

  try {
    const db = admin.firestore();
    const { qrCodeId, shortCode } = req.query;

    if (!qrCodeId && !shortCode) {
      return res.status(400).json({ error: "Missing qrCodeId or shortCode" });
    }

    // Risolvi qrCodeId da shortCode se serve e ottieni destinazione
    let qrId = qrCodeId || null;
    let destination = null;
    if (!qrId && shortCode) {
      const routeDoc = await db.collection("routes").doc(shortCode).get();
      if (!routeDoc.exists) return res.status(404).json({ error: "QR Code not found" });
      const route = routeDoc.data();
      qrId = route.qrCodeId;
      destination = route.destination || null;
    }

    // Device info da User-Agent
    const ua = req.headers["user-agent"] || "";
    const parsedUA = new UAParser(ua);
    const device = {
      platform: parsedUA.os.name || "Unknown",
      browser: parsedUA.browser.name || "Unknown",
      osVersion: parsedUA.os.version || "Unknown",
      deviceType: parsedUA.device.type || inferDeviceType(parsedUA),
      os: parsedUA.os.name || "Unknown",
      id: generateDeviceId(req),
    };

    // Geo da IP (best-effort)
    const ipHeader = req.headers["x-forwarded-for"] || "";
    const ip = ipHeader.split(",")[0] || (req.socket && req.socket.remoteAddress) || "";
    const g = geoip.lookup(ip);
    const location = g ? {
      country: g.country || null,
      city: g.city || null,
      region: g.region || null,
      latitude: (g.ll && g.ll.length > 0) ? g.ll[0] : null,
      longitude: (g.ll && g.ll.length > 1) ? g.ll[1] : null,
    } : null;

    // Scrivi evento realtime compatibile con ScanEvent dell’app
    const scanEvent = {
      qrCodeId: qrId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      device,
      location,
      referrer: req.headers.referer || null,
    };
    await db.collection("scans").add(scanEvent);

    // Aggregazioni
    await updateAggregates(db, qrId, scanEvent);

    // Aggiorna il QR per UI (scanCount/lastScanned)
    await db.collection("qrCodes").doc(qrId).update({
      scanCount: admin.firestore.FieldValue.increment(1),
      lastScanned: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (destination) return res.redirect(destination);
    return res.json({ ok: true, qrCodeId: qrId });
  } catch (err) {
    logger.error("trackQRScan error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
});

function inferDeviceType(parsedUA) {
  const os = parsedUA.os.name || "";
  if (["iOS", "Android"].includes(os)) return "mobile";
  return "desktop";
}

function generateDeviceId(req) {
  const ua = req.headers["user-agent"] || "";
  const ip = (req.headers["x-forwarded-for"] || "").split(",")[0] || "";
  return Buffer.from(`${ua}-${ip}`).toString("base64").slice(0, 22);
}

async function updateAggregates(db, qrCodeId, event) {
  const now = new Date();
  const dateKey = now.toISOString().slice(0, 10);
  const hour = now.getHours();

  const updates = {
    qrCodeId,
    totalScans: admin.firestore.FieldValue.increment(1),
    [`scansByDay.${dateKey}`]: admin.firestore.FieldValue.increment(1),
    [`scansByHour.${hour}`]: admin.firestore.FieldValue.increment(1),
    [`scansByDevice.${event.device.platform}`]: admin.firestore.FieldValue.increment(1),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (event.location && event.location.country) {
    updates[`scansByCountry.${event.location.country}`] = admin.firestore.FieldValue.increment(1);
  }
  if (event.location && event.location.city) {
    updates[`scansByLocation.${event.location.city}`] = admin.firestore.FieldValue.increment(1);
  }
  if (event.device && event.device.browser) {
    updates[`scansByBrowser.${event.device.browser}`] = admin.firestore.FieldValue.increment(1);
  }
  if (event.device && event.device.os) {
    updates[`scansByOS.${event.device.os}`] = admin.firestore.FieldValue.increment(1);
  }

  await db.collection("analytics").doc(qrCodeId).set(updates, { merge: true });
}
