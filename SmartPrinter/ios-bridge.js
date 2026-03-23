// ios-bridge.js
// Inject this file into Smart PDF's static build (www/ folder).
// Add before </body> in www/index.html:  <script src="ios-bridge.js"></script>
//
// This file wires Smart PDF's existing download/open actions to the
// native Swift message handlers registered in PDFToolsViewController.

(function () {
    "use strict";

    // ── Environment detection ─────────────────────────────────────────────────
    const IS_IOS = !!(window.webkit && window.webkit.messageHandlers);
    if (!IS_IOS) return; // Only activate inside WKWebView

    // ── Post helper ───────────────────────────────────────────────────────────
    function post(handler, body) {
        window.webkit.messageHandlers[handler].postMessage(body);
    }

    // ── Receive a single file from Swift (after UIDocumentPicker) ─────────────
    // Called by Swift: window.receiveFileFromiOS(base64, filename)
    window.receiveFileFromiOS = function (base64, filename) {
        const bytes = Uint8Array.from(atob(base64), function (c) { return c.charCodeAt(0); });
        const mimeType = mimeForFilename(filename);
        const file = new File([bytes], filename, { type: mimeType });
        window.dispatchEvent(new CustomEvent("ios-file-received", {
            detail: { file: file, filename: filename }
        }));
    };

    // ── Receive multiple files from Swift (merge, alternate-merge, etc.) ──────
    // Called by Swift: window.receiveMultipleFilesFromiOS([{data, name}, …])
    window.receiveMultipleFilesFromiOS = function (items) {
        const files = items.map(function (item) {
            const bytes = Uint8Array.from(atob(item.data), function (c) { return c.charCodeAt(0); });
            return new File([bytes], item.name, { type: mimeForFilename(item.name) });
        });
        window.dispatchEvent(new CustomEvent("ios-files-received", {
            detail: { files: files }
        }));
    };

    // ── Receive scanned pages from VNDocumentCameraViewController ────────────
    // Called by Swift: window.receiveScanFromiOS([{data, name}, …])
    window.receiveScanFromiOS = function (pages) {
        const files = pages.map(function (p) {
            const bytes = Uint8Array.from(atob(p.data), function (c) { return c.charCodeAt(0); });
            return new File([bytes], p.name, { type: "image/jpeg" });
        });
        window.dispatchEvent(new CustomEvent("ios-scan-received", {
            detail: { files: files }
        }));
    };

    // ── Download interception (anchor[download] clicks) ──────────────────────
    document.addEventListener("click", function (e) {
        var a = e.target.closest("a[download]");
        if (!a) return;
        e.preventDefault();
        var filename = a.getAttribute("download") || "output.pdf";
        fetch(a.href)
            .then(function (r) { return r.blob(); })
            .then(function (blob) { sendBlobToSwift(blob, filename, "save"); });
    }, true);

    // ── Public API for Smart PDF tools to call directly ───────────────────────

    // Save a Blob or base64 string as a file
    window.__iosSave = function (blobOrBase64, filename) {
        if (typeof blobOrBase64 === "string") {
            post("saveFile", { data: blobOrBase64, filename: filename });
        } else {
            sendBlobToSwift(blobOrBase64, filename, "save");
        }
    };

    // Share a Blob or base64 string
    window.__iosShare = function (blobOrBase64, filename) {
        if (typeof blobOrBase64 === "string") {
            post("sharePDF", { data: blobOrBase64, filename: filename });
        } else {
            sendBlobToSwift(blobOrBase64, filename, "share");
        }
    };

    // Send a Blob or base64 string to the native print sheet
    window.__iosPrint = function (blobOrBase64) {
        if (typeof blobOrBase64 === "string") {
            post("printPDF", blobOrBase64);
        } else {
            var reader = new FileReader();
            reader.onloadend = function () {
                post("printPDF", reader.result.split(",")[1]);
            };
            reader.readAsDataURL(blobOrBase64);
        }
    };

    // Save a ZIP blob
    window.__iosSaveZip = function (blob, filename) {
        sendBlobToSwift(blob, filename || "archive.zip", "zip");
    };

    // Open native file picker (single file)
    window.__iosOpenFile = function () {
        post("openFile", null);
    };

    // Open native file picker (multiple files)
    window.__iosOpenFiles = function () {
        post("openMultipleFiles", null);
    };

    // Trigger document camera scanner
    window.__iosRequestCamera = function () {
        post("requestCamera", null);
    };

    // ── Internal helpers ──────────────────────────────────────────────────────

    function sendBlobToSwift(blob, filename, action) {
        var reader = new FileReader();
        reader.onloadend = function () {
            var base64 = reader.result.split(",")[1];
            if (action === "share") {
                post("sharePDF", { data: base64, filename: filename });
            } else if (action === "zip") {
                post("saveZip", { data: base64, filename: filename });
            } else {
                post("saveFile", { data: base64, filename: filename });
            }
        };
        reader.readAsDataURL(blob);
    }

    function mimeForFilename(name) {
        var ext = (name.split(".").pop() || "").toLowerCase();
        var map = {
            "pdf":  "application/pdf",
            "jpg":  "image/jpeg",
            "jpeg": "image/jpeg",
            "png":  "image/png",
            "webp": "image/webp",
            "gif":  "image/gif",
            "bmp":  "image/bmp",
            "tiff": "image/tiff",
            "tif":  "image/tiff",
            "heic": "image/heic",
            "svg":  "image/svg+xml",
            "txt":  "text/plain",
            "html": "text/html",
            "htm":  "text/html",
            "json": "application/json",
            "csv":  "text/csv",
            "md":   "text/markdown",
            "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "doc":  "application/msword",
            "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "xls":  "application/vnd.ms-excel",
            "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "ppt":  "application/vnd.ms-powerpoint",
            "zip":  "application/zip",
            "epub": "application/epub+zip",
            "rtf":  "application/rtf"
        };
        return map[ext] || "application/octet-stream";
    }

})();
