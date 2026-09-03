import jsPDF from "jspdf";
import "jspdf-autotable";

/**
 * Export tabular data as a CSV file download.
 * @param {string[]} headers - Column header labels
 * @param {Array<Array<string|number>>} rows - 2D array of row data
 * @param {string} filename - Download filename (without extension)
 */
export function exportToCSV(headers, rows, filename = "export") {
  const escape = (v) => `"${String(v ?? "").replace(/"/g, '""')}"`;
  const csvContent = [
    headers.map(escape).join(","),
    ...rows.map((row) => row.map(escape).join(",")),
  ].join("\n");

  const blob = new Blob(["\uFEFF" + csvContent], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `${filename}.csv`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/**
 * Export tabular data as a styled PDF file download.
 * @param {string} title - Report title
 * @param {string[]} headers - Column header labels
 * @param {Array<Array<string|number>>} rows - 2D array of row data
 * @param {string} filename - Download filename (without extension)
 */
export function exportToPDF(title, headers, rows, filename = "report") {
  const doc = new jsPDF({ orientation: "landscape", unit: "mm", format: "a4" });

  // Header bar
  doc.setFillColor(13, 59, 54); // #0D3B36
  doc.rect(0, 0, 297, 22, "F");
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(14);
  doc.setFont("helvetica", "bold");
  doc.text("PharmaGo", 14, 14);

  // Title
  doc.setTextColor(13, 59, 54);
  doc.setFontSize(16);
  doc.text(title, 14, 34);

  // Date
  doc.setFontSize(9);
  doc.setTextColor(120, 120, 120);
  doc.text(`${new Date().toLocaleDateString()} — ${new Date().toLocaleTimeString()}`, 14, 40);

  // Table
  doc.autoTable({
    startY: 46,
    head: [headers],
    body: rows,
    theme: "grid",
    headStyles: {
      fillColor: [15, 155, 142], // #0F9B8E
      textColor: [255, 255, 255],
      fontStyle: "bold",
      fontSize: 9,
    },
    bodyStyles: {
      fontSize: 8,
      textColor: [50, 50, 50],
    },
    alternateRowStyles: {
      fillColor: [246, 245, 239], // #F6F5EF
    },
    styles: {
      cellPadding: 3,
      lineColor: [220, 230, 226], // #DCE6E2
      lineWidth: 0.2,
    },
    margin: { left: 14, right: 14 },
  });

  // Footer
  const pageCount = doc.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.setFontSize(8);
    doc.setTextColor(150, 150, 150);
    doc.text(`PharmaGo — Page ${i}/${pageCount}`, 14, doc.internal.pageSize.height - 8);
  }

  doc.save(`${filename}.pdf`);
}
