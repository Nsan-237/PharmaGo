import React, { useState, useEffect } from "react";
import { Plus, Pencil, Trash2, Search, Download, FileText, Filter } from "lucide-react";
import { drugs as initialDrugs } from "../../mockData/index";
import { useT } from "../../i18n/TranslationContext";
import { exportToCSV, exportToPDF } from "../../utils/exportUtils";
import { apiSearchProducts, apiAddProduct, apiUpdateProduct, apiDeleteProduct } from "../../utils/api";
import StatusBadge from "../../components/shared/StatusBadge";
import { PageHeader, Card, TableWrapper, Th, Td, PrimaryButton, SecondaryButton, Modal, InputField, SelectField } from "../../components/shared/UI";

export default function PharmaStock() {
  const t = useT();
  const [drugs, setDrugs] = useState(initialDrugs);
  const [search, setSearch] = useState("");
  const [catFilter, setCatFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [modalOpen, setModalOpen] = useState(false);
  const [editDrug, setEditDrug] = useState(null);
  const [form, setForm] = useState({ name: "", category: "", quantity: "", price: "", requiresPrescription: false });

  const categories = ["Analgésique","Antibiotique","Anti-inflammatoire","Antipaludéen","Vitamines","Pédiatrie","Cardiovasculaire","Autre"];

  useEffect(() => {
    async function loadLiveProducts() {
      try {
        const res = await apiSearchProducts("");
        if (res && res.products && res.products.length > 0) {
          const formatted = res.products.map(p => ({
            id: p.id,
            name: p.name,
            category: p.category || "Général",
            quantity: p.stockQuantity,
            price: p.price,
            requiresPrescription: p.requiresPrescription,
            status: p.stockQuantity === 0 ? "rupture" : p.stockQuantity <= 30 ? "stock_faible" : "en_stock",
          }));
          setDrugs(formatted);
        }
      } catch (err) {
        console.log("Using fallback mock stock data");
      }
    }
    loadLiveProducts();
  }, []);

  const filtered = drugs.filter(d => {
    const matchSearch = d.name.toLowerCase().includes(search.toLowerCase()) || d.category.toLowerCase().includes(search.toLowerCase());
    const matchCat    = catFilter === "all" || d.category === catFilter;
    const matchStatus = statusFilter === "all" || d.status === statusFilter;
    return matchSearch && matchCat && matchStatus;
  });

  const openAdd  = () => { setForm({ name: "", category: categories[0], quantity: "", price: "", requiresPrescription: false }); setEditDrug(null); setModalOpen(true); };
  const openEdit = (d) => { setForm({ name: d.name, category: d.category, quantity: d.quantity, price: d.price, requiresPrescription: d.requiresPrescription }); setEditDrug(d); setModalOpen(true); };

  const deleteDrug = async (id) => {
    try {
      await apiDeleteProduct(id);
    } catch (_) {}
    setDrugs(prev => prev.filter(d => d.id !== id));
  };

  const getStatus = (qty) => qty === 0 ? "rupture" : qty <= 30 ? "stock_faible" : "en_stock";

  const handleSave = async () => {
    const qty = parseInt(form.quantity) || 0;
    const prc = parseInt(form.price) || 0;
    if (editDrug) {
      try {
        await apiUpdateProduct(editDrug.id, {
          name: form.name,
          category: form.category,
          stockQuantity: qty,
          price: prc,
          requiresPrescription: form.requiresPrescription,
        });
      } catch (_) {}
      setDrugs(prev => prev.map(d => d.id === editDrug.id ? { ...d, ...form, quantity: qty, price: prc, status: getStatus(qty) } : d));
    } else {
      try {
        const res = await apiAddProduct({
          pharmacyId: "pharmacie-centre-akwa",
          name: form.name,
          category: form.category || categories[0],
          stockQuantity: qty,
          price: prc,
          requiresPrescription: form.requiresPrescription,
        });
        if (res && res.product) {
          setDrugs(prev => [...prev, { id: res.product.id, ...form, quantity: qty, price: prc, status: getStatus(qty) }]);
          setModalOpen(false);
          return;
        }
      } catch (_) {}
      setDrugs(prev => [...prev, { id: Date.now().toString(), ...form, quantity: qty, price: prc, status: getStatus(qty) }]);
    }
    setModalOpen(false);
  };

  // Export handlers
  const headers = [t("stock.colDrug"), t("stock.colCategory"), t("stock.colQty"), t("stock.colPrice"), t("stock.colRx"), t("common.status")];
  const toRows = (list) => list.map(d => [d.name, d.category, d.quantity, `${d.price.toLocaleString()} FCFA`, d.requiresPrescription ? t("stock.rxRequired") : t("stock.rxNot"), t(`status.${d.status}`)]);

  const handleCSV = () => exportToCSV(headers, toRows(filtered), `pharmago_stock_${new Date().toISOString().slice(0,10)}`);
  const handlePDF = () => exportToPDF(t("stock.title"), headers, toRows(filtered), `pharmago_stock_${new Date().toISOString().slice(0,10)}`);

  return (
    <div>
      <PageHeader
        title={t("stock.title")}
        subtitle={`${drugs.length} ${t("stock.subtitle")}`}
        action={<PrimaryButton onClick={openAdd}><Plus size={16} /> {t("stock.addBtn")}</PrimaryButton>}
      />

      <Card>
        <div className="p-4 border-b flex flex-wrap items-center gap-3" style={{ borderColor: "#DCE6E2" }}>
          {/* Search */}
          <div className="relative flex-1 min-w-[200px] max-w-sm">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              placeholder={t("stock.searchPlaceholder")}
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-9 pr-3 py-2 rounded-lg border text-sm outline-none"
              style={{ borderColor: "#DCE6E2", background: "#F6F5EF" }}
            />
          </div>

          {/* Category filter */}
          <select value={catFilter} onChange={e => setCatFilter(e.target.value)}
            className="px-3 py-2 rounded-lg border text-sm outline-none" style={{ borderColor: "#DCE6E2" }}>
            <option value="all">{t("filter.allCategories")}</option>
            {categories.map(c => <option key={c} value={c}>{c}</option>)}
          </select>

          {/* Status filter */}
          <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)}
            className="px-3 py-2 rounded-lg border text-sm outline-none" style={{ borderColor: "#DCE6E2" }}>
            <option value="all">{t("filter.allStatuses")}</option>
            <option value="en_stock">{t("status.en_stock")}</option>
            <option value="stock_faible">{t("status.stock_faible")}</option>
            <option value="rupture">{t("status.rupture")}</option>
          </select>

          <div className="flex-1" />

          {/* Export buttons */}
          <button onClick={handleCSV}
            className="flex items-center gap-1.5 px-3 py-2 rounded-lg border text-sm font-medium hover:bg-gray-50 transition-colors"
            style={{ borderColor: "#DCE6E2", color: "#0D3B36" }}>
            <Download size={14} /> CSV
          </button>
          <button onClick={handlePDF}
            className="flex items-center gap-1.5 px-3 py-2 rounded-lg text-white text-sm font-medium hover:opacity-90 transition-colors"
            style={{ background: "#0F9B8E" }}>
            <FileText size={14} /> PDF
          </button>
        </div>

        <TableWrapper>
          <thead>
            <tr>
              <Th>{t("stock.colDrug")}</Th>
              <Th>{t("stock.colCategory")}</Th>
              <Th>{t("stock.colQty")}</Th>
              <Th>{t("stock.colPrice")}</Th>
              <Th>{t("stock.colRx")}</Th>
              <Th>{t("common.status")}</Th>
              <Th>{t("common.actions")}</Th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(d => (
              <tr key={d.id} className="hover:bg-gray-50 transition-colors">
                <Td><span className="font-medium" style={{ color: "#0D3B36" }}>{d.name}</span></Td>
                <Td><span className="text-xs px-2 py-0.5 bg-gray-100 rounded-full text-gray-600">{d.category}</span></Td>
                <Td>
                  <span className={`font-semibold ${d.quantity === 0 ? "text-red-500" : d.quantity <= 30 ? "text-amber-600" : "text-gray-700"}`}>
                    {d.quantity}
                  </span>
                </Td>
                <Td><span className="font-semibold">{d.price.toLocaleString()}</span></Td>
                <Td>
                  <span className={`text-xs font-medium ${d.requiresPrescription ? "text-purple-600" : "text-gray-400"}`}>
                    {d.requiresPrescription ? t("stock.rxRequired") : t("stock.rxNot")}
                  </span>
                </Td>
                <Td><StatusBadge status={d.status} /></Td>
                <Td>
                  <div className="flex items-center gap-2">
                    <button onClick={() => openEdit(d)} className="p-1.5 rounded-lg hover:bg-blue-50 text-blue-500 transition-colors"><Pencil size={14} /></button>
                    <button onClick={() => deleteDrug(d.id)} className="p-1.5 rounded-lg hover:bg-red-50 text-red-500 transition-colors"><Trash2 size={14} /></button>
                  </div>
                </Td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan={7} className="text-center py-8 text-gray-400 text-sm">{t("common.noData")}</td></tr>
            )}
          </tbody>
        </TableWrapper>
      </Card>

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title={editDrug ? t("stock.modalEdit") : t("stock.modalAdd")}>
        <div className="space-y-4">
          <InputField label={t("stock.fieldName")} value={form.name} onChange={e => setForm(f=>({...f,name:e.target.value}))} placeholder={t("stock.fieldNamePh")} required />
          <SelectField label={t("stock.fieldCategory")} value={form.category}
            onChange={e => setForm(f=>({...f,category:e.target.value}))}
            options={categories.map(c => ({ value: c, label: c }))} required />
          <div className="grid grid-cols-2 gap-4">
            <InputField label={t("stock.fieldQty")} type="number" value={form.quantity} onChange={e => setForm(f=>({...f,quantity:e.target.value}))} placeholder="0" required />
            <InputField label={t("stock.fieldPrice")} type="number" value={form.price} onChange={e => setForm(f=>({...f,price:e.target.value}))} placeholder="0" required />
          </div>
          <label className="flex items-center gap-3 cursor-pointer">
            <div className={`relative w-10 h-5 rounded-full transition-colors`}
              style={{ background: form.requiresPrescription ? "#0F9B8E" : "#e5e7eb" }}
              onClick={() => setForm(f=>({...f,requiresPrescription:!f.requiresPrescription}))}>
              <div className={`absolute top-0.5 w-4 h-4 bg-white rounded-full shadow transition-transform ${form.requiresPrescription ? "translate-x-5" : "translate-x-0.5"}`} />
            </div>
            <span className="text-sm font-medium" style={{ color: "#0D3B36" }}>{t("stock.toggleRx")}</span>
          </label>
          <div className="flex gap-3 pt-2">
            <PrimaryButton onClick={handleSave} className="flex-1 justify-center">
              {editDrug ? t("common.save") : t("common.add")}
            </PrimaryButton>
            <SecondaryButton onClick={() => setModalOpen(false)} className="flex-1 justify-center">{t("common.cancel")}</SecondaryButton>
          </div>
        </div>
      </Modal>
    </div>
  );
}
