const STORAGE_KEY = "ipad-barcode-csv.scans.v1";
const CAMERA_SCAN_INTERVAL_MS = 220;
const CAMERA_REPEAT_COOLDOWN_MS = 1200;
const CAMERA_BARCODE_FORMATS = [
  "ean_13",
  "ean_8",
  "upc_a",
  "upc_e",
  "itf",
  "code_128",
  "code_39",
  "codabar",
];

const state = {
  scans: loadScans(),
  scanMode: "keyboard",
  camera: {
    active: false,
    detector: null,
    stream: null,
    loopTimer: null,
    scanInFlight: false,
    lastBarcode: "",
    lastScanAt: 0,
    shouldResumeOnVisible: false,
  },
};

const totalScansEl = document.getElementById("totalScans");
const uniqueCodesEl = document.getElementById("uniqueCodes");
const todayScansEl = document.getElementById("todayScans");
const scanForm = document.getElementById("scanForm");
const scanInput = document.getElementById("scanInput");
const scanStatus = document.getElementById("scanStatus");
const summaryTableBody = document.getElementById("summaryTableBody");
const logTableBody = document.getElementById("logTableBody");
const focusButton = document.getElementById("focusButton");
const exportRawButton = document.getElementById("exportRawButton");
const exportSummaryButton = document.getElementById("exportSummaryButton");
const clearButton = document.getElementById("clearButton");
const demoButton = document.getElementById("demoButton");
const emptyStateTemplate = document.getElementById("emptyStateTemplate");
const keyboardModeButton = document.getElementById("keyboardModeButton");
const cameraModeButton = document.getElementById("cameraModeButton");
const cameraPanel = document.getElementById("cameraPanel");
const cameraPreview = document.getElementById("cameraPreview");
const startCameraButton = document.getElementById("startCameraButton");
const stopCameraButton = document.getElementById("stopCameraButton");
const cameraStatus = document.getElementById("cameraStatus");

render();
syncModeUi();
setCameraStatus(getCameraSupport().message, getCameraSupport().supported ? "" : "error");
registerServiceWorker();
window.setTimeout(focusScanInput, 120);

scanForm.addEventListener("submit", (event) => {
  event.preventDefault();
  addScan(scanInput.value);
});

focusButton.addEventListener("click", focusScanInput);
exportRawButton.addEventListener("click", exportRawCsv);
exportSummaryButton.addEventListener("click", exportSummaryCsv);
clearButton.addEventListener("click", clearAllScans);
demoButton.addEventListener("click", seedDemoData);
keyboardModeButton.addEventListener("click", () => setScanMode("keyboard"));
cameraModeButton.addEventListener("click", () => setScanMode("camera"));
startCameraButton.addEventListener("click", startCamera);
stopCameraButton.addEventListener("click", () => stopCamera());

document.addEventListener("visibilitychange", async () => {
  if (document.hidden) {
    state.camera.shouldResumeOnVisible = state.camera.active;
    stopCamera({ preserveStatus: true });
    return;
  }

  if (state.scanMode === "keyboard") {
    focusScanInput();
    return;
  }

  if (state.camera.shouldResumeOnVisible) {
    state.camera.shouldResumeOnVisible = false;
    await startCamera();
  }
});

window.addEventListener("beforeunload", () => {
  stopCamera({ preserveStatus: true });
});

function loadScans() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    console.error("Unable to parse scans", error);
    return [];
  }
}

function saveScans() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state.scans));
}

function addScan(rawValue, options = {}) {
  const barcode = normalizeBarcode(rawValue);
  const shouldFocusInput = options.focusInput ?? state.scanMode === "keyboard";

  if (!barcode) {
    const message = "请输入或扫描有效条码。";
    setStatus(message, "error");
    if (shouldFocusInput) {
      focusScanInput();
    }
    return { saved: false, message };
  }

  const analysis = analyzeBarcode(barcode);
  if (!analysis.accepted) {
    setStatus(analysis.message, "error");
    if (shouldFocusInput) {
      focusScanInput();
    }
    return { saved: false, message: analysis.message };
  }

  const scannedAt = new Date().toISOString();
  const scanRecord = {
    id: generateId(),
    barcode,
    type: analysis.type,
    scannedAt,
    scanDate: formatDate(scannedAt),
    displayTime: formatDateTime(scannedAt),
  };

  state.scans.unshift(scanRecord);
  saveScans();
  render();

  const duplicateCount = state.scans.filter((item) => item.barcode === barcode).length;
  const duplicateMessage = duplicateCount > 1 ? `，当前累计 ${duplicateCount} 件` : "";
  const message = `已记录 ${barcode} (${analysis.type})${duplicateMessage}`;
  setStatus(message, "success");

  scanForm.reset();
  if (shouldFocusInput) {
    focusScanInput();
  }

  return { saved: true, message, type: analysis.type };
}

function normalizeBarcode(rawValue) {
  return String(rawValue || "")
    .trim()
    .replace(/[\s-]+/g, "")
    .toUpperCase();
}

function detectBarcodeType(barcode) {
  return analyzeBarcode(barcode).type;
}

function analyzeBarcode(barcode) {
  if (/^\d{13}$/.test(barcode) && /^(978|979)/.test(barcode)) {
    if (isValidGtinChecksum(barcode)) {
      return { accepted: true, type: "ISBN-13" };
    }
    return {
      accepted: false,
      type: "其他条码",
      message: "ISBN-13 校验失败，请检查扫描结果。",
    };
  }

  if (/^\d{9}[\dX]$/.test(barcode)) {
    if (isValidIsbn10(barcode)) {
      return { accepted: true, type: "ISBN-10" };
    }
    return {
      accepted: false,
      type: "其他条码",
      message: "ISBN-10 校验失败，请检查扫描结果。",
    };
  }

  if (/^\d{8}$/.test(barcode)) {
    if (isValidGtinChecksum(barcode)) {
      return { accepted: true, type: "EAN-8" };
    }
    return {
      accepted: false,
      type: "其他条码",
      message: "EAN-8 校验失败，请检查扫描结果。",
    };
  }

  if (/^\d{12}$/.test(barcode)) {
    if (isValidGtinChecksum(barcode)) {
      return { accepted: true, type: "UPC-A" };
    }
    return {
      accepted: false,
      type: "其他条码",
      message: "UPC-A 校验失败，请检查扫描结果。",
    };
  }

  if (/^\d{13}$/.test(barcode)) {
    if (isValidGtinChecksum(barcode)) {
      return { accepted: true, type: "EAN-13" };
    }
    return {
      accepted: false,
      type: "其他条码",
      message: "EAN-13 校验失败，请检查扫描结果。",
    };
  }

  if (/^\d{14}$/.test(barcode)) {
    if (isValidGtinChecksum(barcode)) {
      return { accepted: true, type: "ITF-14" };
    }
    return {
      accepted: false,
      type: "其他条码",
      message: "ITF-14 校验失败，请检查扫描结果。",
    };
  }

  if (/^\d{6,18}$/.test(barcode)) {
    return { accepted: true, type: "零售条码" };
  }

  return { accepted: true, type: "其他条码" };
}

function isValidGtinChecksum(barcode) {
  if (!/^\d{2,}$/.test(barcode)) {
    return false;
  }

  let sum = 0;
  let weight = 3;

  for (let index = barcode.length - 2; index >= 0; index -= 1) {
    sum += Number(barcode[index]) * weight;
    weight = weight === 3 ? 1 : 3;
  }

  const expectedCheckDigit = (10 - (sum % 10)) % 10;
  return expectedCheckDigit === Number(barcode.charAt(barcode.length - 1));
}

function isValidIsbn10(barcode) {
  if (!/^\d{9}[\dX]$/.test(barcode)) {
    return false;
  }

  const sum = barcode.split("").reduce((total, character, index) => {
    const digit = character === "X" ? 10 : Number(character);
    return total + digit * (10 - index);
  }, 0);

  return sum % 11 === 0;
}

function buildSummaryRows() {
  const summaryMap = new Map();

  for (const scan of state.scans) {
    if (!summaryMap.has(scan.barcode)) {
      summaryMap.set(scan.barcode, {
        barcode: scan.barcode,
        type: scan.type,
        quantity: 0,
        firstScannedAt: scan.scannedAt,
        lastScannedAt: scan.scannedAt,
        scanDates: new Set(),
      });
    }

    const current = summaryMap.get(scan.barcode);
    current.quantity += 1;
    current.scanDates.add(scan.scanDate);
    if (scan.scannedAt < current.firstScannedAt) {
      current.firstScannedAt = scan.scannedAt;
    }
    if (scan.scannedAt > current.lastScannedAt) {
      current.lastScannedAt = scan.scannedAt;
    }
  }

  return Array.from(summaryMap.values()).sort((a, b) => {
    if (b.quantity !== a.quantity) {
      return b.quantity - a.quantity;
    }
    return a.barcode.localeCompare(b.barcode);
  });
}

function render() {
  const summaryRows = buildSummaryRows();
  const today = formatDate(new Date().toISOString());
  const todayCount = state.scans.filter((scan) => scan.scanDate === today).length;

  totalScansEl.textContent = String(state.scans.length);
  uniqueCodesEl.textContent = String(summaryRows.length);
  todayScansEl.textContent = String(todayCount);

  renderSummaryTable(summaryRows);
  renderLogTable();
}

function renderSummaryTable(summaryRows) {
  summaryTableBody.innerHTML = "";

  if (summaryRows.length === 0) {
    const emptyRow = emptyStateTemplate.content.firstElementChild.cloneNode(true);
    summaryTableBody.appendChild(emptyRow);
    return;
  }

  for (const row of summaryRows) {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${escapeHtml(row.barcode)}</td>
      <td>${escapeHtml(row.type)}</td>
      <td>${row.quantity}</td>
      <td>${escapeHtml(formatDateTime(row.firstScannedAt))}</td>
      <td>${escapeHtml(formatDateTime(row.lastScannedAt))}</td>
    `;
    summaryTableBody.appendChild(tr);
  }
}

function renderLogTable() {
  logTableBody.innerHTML = "";

  if (state.scans.length === 0) {
    const emptyRow = document.createElement("tr");
    emptyRow.innerHTML = '<td colspan="4" class="empty-state">还没有明细记录。</td>';
    logTableBody.appendChild(emptyRow);
    return;
  }

  for (const scan of state.scans.slice(0, 200)) {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${escapeHtml(scan.displayTime || formatDateTime(scan.scannedAt))}</td>
      <td>${escapeHtml(scan.scanDate || formatDate(scan.scannedAt))}</td>
      <td>${escapeHtml(scan.barcode)}</td>
      <td>${escapeHtml(scan.type)}</td>
    `;
    logTableBody.appendChild(tr);
  }
}

function exportRawCsv() {
  if (state.scans.length === 0) {
    setStatus("没有可导出的明细数据。", "error");
    return;
  }

  const rows = [
    ["barcode", "type", "scan_date", "scanned_at_local"],
    ...state.scans
      .slice()
      .reverse()
      .map((scan) => [
        scan.barcode,
        scan.type,
        scan.scanDate || formatDate(scan.scannedAt),
        scan.displayTime || formatDateTime(scan.scannedAt),
      ]),
  ];

  downloadCsv(rows, createFileName("barcode-raw"));
  setStatus("明细 CSV 已导出。", "success");
}

function exportSummaryCsv() {
  const summaryRows = buildSummaryRows();

  if (summaryRows.length === 0) {
    setStatus("没有可导出的汇总数据。", "error");
    return;
  }

  const rows = [
    ["barcode", "type", "quantity", "first_scanned_at_local", "last_scanned_at_local", "scan_dates"],
    ...summaryRows.map((row) => [
      row.barcode,
      row.type,
      row.quantity,
      formatDateTime(row.firstScannedAt),
      formatDateTime(row.lastScannedAt),
      Array.from(row.scanDates).sort().join(" | "),
    ]),
  ];

  downloadCsv(rows, createFileName("barcode-summary"));
  setStatus("汇总 CSV 已导出。", "success");
}

function clearAllScans() {
  const confirmed = window.confirm("确认清空所有扫描记录吗？此操作不会保留历史数据。");
  if (!confirmed) {
    return;
  }

  state.scans = [];
  saveScans();
  render();
  setStatus("所有扫描记录已清空。", "success");
  if (state.scanMode === "keyboard") {
    focusScanInput();
  }
}

function seedDemoData() {
  const demoValues = [
    "9787111128069",
    "9787111128069",
    "6901028075886",
    "9787302511850",
    "4901777302150",
  ];

  for (const value of demoValues) {
    addScan(value, { focusInput: false });
  }

  if (state.scanMode === "keyboard") {
    focusScanInput();
  }
}

function downloadCsv(rows, fileName) {
  const csv = rows
    .map((row) => row.map(csvEscape).join(","))
    .join("\r\n");

  const blob = new Blob(["\uFEFF", csv], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = fileName;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

function csvEscape(value) {
  const stringValue = String(value ?? "");
  if (/[",\r\n]/.test(stringValue)) {
    return `"${stringValue.replace(/"/g, '""')}"`;
  }
  return stringValue;
}

function createFileName(prefix) {
  const dateStamp = formatDate(new Date());
  return `${prefix}-${dateStamp}.csv`;
}

function focusScanInput() {
  if (state.scanMode !== "keyboard") {
    return;
  }

  scanInput.focus();
  scanInput.select();
}

function setStatus(message, type) {
  scanStatus.textContent = message;
  scanStatus.classList.remove("success", "error");
  if (type) {
    scanStatus.classList.add(type);
  }
}

function setCameraStatus(message, type) {
  cameraStatus.textContent = message;
  cameraStatus.classList.remove("success", "error");
  if (type) {
    cameraStatus.classList.add(type);
  }
}

function formatDate(value) {
  const date = new Date(value);
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

function formatDateTime(value) {
  const date = new Date(value);
  return `${formatDate(date)} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
}

function generateId() {
  if (window.crypto && typeof window.crypto.randomUUID === "function") {
    return window.crypto.randomUUID();
  }

  return `scan-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function pad(value) {
  return String(value).padStart(2, "0");
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function registerServiceWorker() {
  if (!("serviceWorker" in navigator)) {
    return;
  }

  window.addEventListener("load", () => {
    navigator.serviceWorker.register("./sw.js").catch((error) => {
      console.error("Service worker registration failed", error);
    });
  });
}

function syncModeUi() {
  const isKeyboardMode = state.scanMode === "keyboard";
  const support = getCameraSupport();

  keyboardModeButton.classList.toggle("active", isKeyboardMode);
  keyboardModeButton.setAttribute("aria-pressed", String(isKeyboardMode));
  cameraModeButton.classList.toggle("active", !isKeyboardMode);
  cameraModeButton.setAttribute("aria-pressed", String(!isKeyboardMode));

  cameraPanel.hidden = isKeyboardMode;
  focusButton.disabled = !isKeyboardMode;

  if (!isKeyboardMode) {
    setCameraStatus(
      support.supported
        ? "摄像头模式已就绪。点击“启动摄像头”后，将条码放入取景框中即可自动记录。"
        : support.message,
      support.supported ? "" : "error"
    );
  }

  updateCameraButtons();
}

function setScanMode(mode) {
  if (mode === state.scanMode) {
    if (mode === "keyboard") {
      focusScanInput();
    }
    return;
  }

  state.scanMode = mode;
  syncModeUi();

  if (mode === "keyboard") {
    state.camera.shouldResumeOnVisible = false;
    stopCamera({ preserveStatus: true });
    setStatus("已切换到键盘扫码模式。可继续使用蓝牙扫描枪或手动输入。", "success");
    focusScanInput();
    return;
  }

  setStatus("已切换到摄像头扫码模式。现有记录和 CSV 导出逻辑保持不变。", "success");
}

function getCameraSupport() {
  if (!window.isSecureContext) {
    return {
      supported: false,
      message: "摄像头扫码需要在 HTTPS 或 localhost 环境中打开此页面。",
    };
  }

  if (!navigator.mediaDevices || typeof navigator.mediaDevices.getUserMedia !== "function") {
    return {
      supported: false,
      message: "当前浏览器无法访问摄像头，请改用蓝牙扫描枪模式。",
    };
  }

  if (!("BarcodeDetector" in window)) {
    return {
      supported: false,
      message: "当前浏览器不支持 BarcodeDetector，暂时无法在网页里用摄像头识别条码。",
    };
  }

  return {
    supported: true,
    message: "当前浏览器支持摄像头扫码。点击“启动摄像头”后即可开始识别。",
  };
}

async function startCamera() {
  if (state.camera.active) {
    return;
  }

  const support = getCameraSupport();
  if (!support.supported) {
    setCameraStatus(support.message, "error");
    return;
  }

  startCameraButton.disabled = true;
  setCameraStatus("正在请求摄像头权限并初始化识别器...", "");

  try {
    state.camera.detector = await createBarcodeDetector();
    state.camera.stream = await navigator.mediaDevices.getUserMedia({
      audio: false,
      video: {
        facingMode: { ideal: "environment" },
        width: { ideal: 1920 },
        height: { ideal: 1080 },
      },
    });

    cameraPreview.srcObject = state.camera.stream;
    await cameraPreview.play();

    state.camera.active = true;
    state.camera.lastBarcode = "";
    state.camera.lastScanAt = 0;
    state.camera.shouldResumeOnVisible = false;

    updateCameraButtons();
    setCameraStatus("摄像头已启动。将条码对准取景框，识别后会自动记入下方列表。", "success");
    scheduleNextCameraScan();
  } catch (error) {
    console.error("Unable to start camera scanner", error);
    state.camera.detector = null;
    cleanupCameraStream();
    updateCameraButtons();
    setCameraStatus(buildCameraErrorMessage(error), "error");
  } finally {
    if (!state.camera.active) {
      startCameraButton.disabled = false;
    }
  }
}

function stopCamera(options = {}) {
  const preserveStatus = options.preserveStatus ?? false;

  if (state.camera.loopTimer) {
    window.clearTimeout(state.camera.loopTimer);
    state.camera.loopTimer = null;
  }

  state.camera.active = false;
  state.camera.scanInFlight = false;
  state.camera.detector = null;
  state.camera.lastBarcode = "";
  state.camera.lastScanAt = 0;

  cleanupCameraStream();
  updateCameraButtons();

  if (!preserveStatus) {
    setCameraStatus("摄像头已停止。你可以重新启动，或切回键盘扫码模式。", "");
  }
}

function cleanupCameraStream() {
  if (state.camera.stream) {
    for (const track of state.camera.stream.getTracks()) {
      track.stop();
    }
  }

  state.camera.stream = null;
  cameraPreview.pause();
  cameraPreview.srcObject = null;
}

async function createBarcodeDetector() {
  let formats = CAMERA_BARCODE_FORMATS.slice();

  if (typeof BarcodeDetector.getSupportedFormats === "function") {
    try {
      const supportedFormats = await BarcodeDetector.getSupportedFormats();
      formats = formats.filter((format) => supportedFormats.includes(format));
    } catch (error) {
      console.warn("Unable to read supported barcode formats", error);
    }
  }

  try {
    return formats.length > 0 ? new BarcodeDetector({ formats }) : new BarcodeDetector();
  } catch (error) {
    console.warn("Falling back to default BarcodeDetector configuration", error);
    return new BarcodeDetector();
  }
}

function scheduleNextCameraScan(delay = CAMERA_SCAN_INTERVAL_MS) {
  if (!state.camera.active) {
    return;
  }

  state.camera.loopTimer = window.setTimeout(scanCameraFrame, delay);
}

async function scanCameraFrame() {
  if (!state.camera.active || !state.camera.detector) {
    return;
  }

  if (state.camera.scanInFlight || cameraPreview.readyState < HTMLMediaElement.HAVE_CURRENT_DATA) {
    scheduleNextCameraScan();
    return;
  }

  state.camera.scanInFlight = true;
  let nextDelay = CAMERA_SCAN_INTERVAL_MS;

  try {
    const detections = await state.camera.detector.detect(cameraPreview);
    const rawValue = pickDetectedBarcode(detections);

    if (rawValue) {
      const accepted = handleCameraDetection(rawValue);
      nextDelay = accepted ? CAMERA_REPEAT_COOLDOWN_MS : 380;
    } else if (state.camera.lastBarcode && Date.now() - state.camera.lastScanAt > 600) {
      state.camera.lastBarcode = "";
    }
  } catch (error) {
    console.error("Camera barcode detection failed", error);
    setCameraStatus("摄像头已启动，但当前帧识别失败。请稍微移动设备后重试。", "error");
    nextDelay = 600;
  } finally {
    state.camera.scanInFlight = false;
    scheduleNextCameraScan(nextDelay);
  }
}

function pickDetectedBarcode(detections) {
  if (!Array.isArray(detections) || detections.length === 0) {
    return "";
  }

  for (const detection of detections) {
    const rawValue = normalizeBarcode(detection.rawValue);
    if (rawValue) {
      return rawValue;
    }
  }

  return "";
}

function handleCameraDetection(rawValue) {
  const barcode = normalizeBarcode(rawValue);
  if (!barcode) {
    return false;
  }

  const now = Date.now();
  if (barcode === state.camera.lastBarcode && now - state.camera.lastScanAt < CAMERA_REPEAT_COOLDOWN_MS) {
    setCameraStatus(`已识别 ${barcode}，等待条码离开镜头后再继续。`, "success");
    return false;
  }

  state.camera.lastBarcode = barcode;
  state.camera.lastScanAt = now;
  const result = addScan(barcode, { focusInput: false });
  setCameraStatus(result.message, result.saved ? "success" : "error");
  return result.saved;
}

function updateCameraButtons() {
  const support = getCameraSupport();
  startCameraButton.disabled = state.camera.active || !support.supported;
  stopCameraButton.disabled = !state.camera.active;
}

function buildCameraErrorMessage(error) {
  if (!error || typeof error !== "object") {
    return "摄像头启动失败，请检查权限和浏览器兼容性。";
  }

  switch (error.name) {
    case "NotAllowedError":
    case "SecurityError":
      return "没有摄像头权限。请在 Safari 设置里允许此页面访问摄像头。";
    case "NotFoundError":
    case "DevicesNotFoundError":
      return "没有检测到可用摄像头，请确认当前设备存在后置摄像头。";
    case "NotReadableError":
    case "TrackStartError":
      return "摄像头正在被其他应用占用，请关闭后重试。";
    case "OverconstrainedError":
      return "当前摄像头不支持请求的分辨率，刷新后重试即可。";
    default:
      return `摄像头启动失败：${error.message || "请检查权限和浏览器兼容性。"}`;
  }
}
