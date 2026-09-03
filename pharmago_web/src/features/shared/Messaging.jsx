import React, { useState, useRef, useEffect } from "react";
import { Send, Search, AlertTriangle, Truck, User, Package } from "lucide-react";
import { useRole } from "../../App";
import { useT } from "../../i18n/TranslationContext";
import { PageHeader, Card } from "../../components/shared/UI";

/* ─── Thread data ─────────────────────────────────────────────── */

const disputeThreads = [
  {
    id: "thread-lit101",
    name: "Jean-Paul Mbeki",
    tag: "Litige LIT-101",
    tagColor: "#dc2626", tagBg: "#fee2e2",
    avatar: "JM", avatarBg: "#dc2626",
    preview: "Le médicament reçu ne correspond pas à ma commande.",
    time: "10:05", unread: 2,
    messages: [
      { id: 1, from: "client", text: "Bonjour, j'ai reçu un médicament incorrect avec ma commande CMD-2402.", time: "10:00" },
      { id: 2, from: "client", text: "Amoxicilline 250mg au lieu de 500mg. Comment procéder pour un remplacement ?", time: "10:01" },
    ],
  },
  {
    id: "thread-lit102",
    name: "Paul Atangana",
    tag: "Litige LIT-102",
    tagColor: "#E8A33D", tagBg: "#FEF3DC",
    avatar: "PA", avatarBg: "#E8A33D",
    preview: "Ma livraison CMD-2404 n'est toujours pas arrivée.",
    time: "Hier", unread: 0,
    messages: [
      { id: 1, from: "client", text: "Bonjour, ma commande CMD-2404 était prévue hier. Elle n'est toujours pas arrivée.", time: "14:30" },
      { id: 2, from: "me",     text: "Bonjour M. Atangana, je vérifie la situation immédiatement avec l'agent.", time: "15:10" },
      { id: 3, from: "client", text: "Merci. J'attends votre retour.", time: "15:12" },
    ],
  },
  {
    id: "thread-lit104",
    name: "Sophie Mendo",
    tag: "Litige LIT-104",
    tagColor: "#E8A33D", tagBg: "#FEF3DC",
    avatar: "SM", avatarBg: "#9333ea",
    preview: "Retard de livraison excessif sur ma commande.",
    time: "24 Août", unread: 0,
    messages: [
      { id: 1, from: "client", text: "Ma commande CMD-2395 attendait depuis 3 jours. C'est inacceptable.", time: "14:30" },
      { id: 2, from: "me",     text: "Bonjour Mme Mendo, toutes nos excuses. Un remboursement partiel sera effectué sous 24h.", time: "16:00" },
      { id: 3, from: "client", text: "D'accord, merci.", time: "16:15" },
    ],
  },
];

const agentThreads = [
  {
    id: "thread-agent-roger",
    name: "Roger Kamdem",
    tag: "LIV-501 · En route",
    tagColor: "#2563eb", tagBg: "#dbeafe",
    avatar: "RK", avatarBg: "#0F9B8E",
    preview: "Je suis à 10 minutes de l'adresse client.",
    time: "11:10", unread: 1,
    messages: [
      { id: 1, from: "agent", text: "Bonjour, je viens de prendre en charge la livraison LIV-501 pour Fatima Bello.", time: "10:15" },
      { id: 2, from: "me",    text: "Parfait Roger. L'ordonnance a été validée. Bonne livraison !", time: "10:17" },
      { id: 3, from: "agent", text: "Je suis à 10 minutes de l'adresse client.", time: "11:10" },
    ],
  },
  {
    id: "thread-agent-patrick",
    name: "Patrick Essomba",
    tag: "LIV-502 · Assignée",
    tagColor: "#6b7280", tagBg: "#f3f4f6",
    avatar: "PE", avatarBg: "#7c3aed",
    preview: "Je vais récupérer les médicaments dans 20 min.",
    time: "11:05", unread: 0,
    messages: [
      { id: 1, from: "me",    text: "Patrick, la commande LIV-502 pour Marie Ngono à Bonapriso est prête.", time: "11:00" },
      { id: 2, from: "agent", text: "Oui, je vais récupérer les médicaments dans 20 min.", time: "11:05" },
    ],
  },
  {
    id: "thread-agent-eric",
    name: "Eric Nyamsi",
    tag: "Disponible",
    tagColor: "#16a34a", tagBg: "#dcfce7",
    avatar: "EN", avatarBg: "#16a34a",
    preview: "Bonjour, je suis disponible pour des livraisons.",
    time: "09:00", unread: 0,
    messages: [
      { id: 1, from: "agent", text: "Bonjour, je suis disponible pour des livraisons dans la zone Makepe / Logpom.", time: "09:00" },
    ],
  },
];

/* ─── Auto-reply bank ─────────────────────────────────────────── */

const botRepliesEn = {
  client: [
    "Thank you for your message. A platform representative will handle your request shortly.",
    "Your claim has been registered. We will contact you as soon as possible.",
    "We understand your frustration. We are doing our best to resolve this quickly.",
  ],
  agent: [
    "Understood. Thanks for the quick response!",
    "Got it, keep me updated.",
    "Alright, you can proceed. The client has been notified.",
  ],
};
const botRepliesFr = {
  client: [
    "Merci pour votre message. Un responsable de la plateforme va traiter votre demande sous peu.",
    "Votre réclamation a bien été enregistrée. Nous vous contactons dès que possible.",
    "Nous comprenons votre frustration. Nous faisons le maximum pour résoudre ce problème rapidement.",
  ],
  agent: [
    "Compris. Merci de votre réactivité !",
    "Très bien, tiens-moi informé de l'avancement.",
    "D'accord, tu peux procéder. Le client a été prévenu.",
  ],
};

/* ─── Sub-components ──────────────────────────────────────────── */

function ThreadItem({ thread, active, onClick }) {
  return (
    <button onClick={onClick}
      className={`w-full flex items-start gap-3 px-4 py-3.5 text-left transition-colors ${active ? "bg-primary/10" : "hover:bg-gray-50"}`}
      style={{ background: active ? "#e6f7f6" : undefined }}>
      <div className="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold text-sm shrink-0 font-sora"
        style={{ background: thread.avatarBg }}>
        {thread.avatar}
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between mb-0.5">
          <p className="font-semibold text-sm truncate" style={{ color: "#0D3B36" }}>{thread.name}</p>
          <span className="text-xs text-gray-400 shrink-0 ml-2">{thread.time}</span>
        </div>
        <span className="inline-flex text-xs px-2 py-0.5 rounded-full font-medium mb-1"
          style={{ background: thread.tagBg, color: thread.tagColor }}>
          {thread.tag}
        </span>
        <p className="text-xs text-gray-400 truncate">{thread.preview}</p>
      </div>
      {thread.unread > 0 && (
        <span className="w-5 h-5 rounded-full flex items-center justify-center text-white text-xs font-bold shrink-0"
          style={{ background: "#0F9B8E" }}>
          {thread.unread}
        </span>
      )}
    </button>
  );
}

function MessageBubble({ msg, senderType }) {
  const isMe = msg.from === "me";
  return (
    <div className={`flex items-end gap-2 mb-4 ${isMe ? "flex-row-reverse" : "flex-row"}`}>
      {!isMe && (
        <div className="w-7 h-7 rounded-full flex items-center justify-center text-white text-xs font-bold shrink-0 mb-0.5"
          style={{ background: senderType === "agent" ? "#0F9B8E" : "#9333ea" }}>
          {senderType === "agent" ? <Truck size={13} /> : <User size={13} />}
        </div>
      )}
      <div className={`max-w-xs lg:max-w-md px-4 py-2.5 rounded-2xl text-sm leading-relaxed ${isMe ? "rounded-br-sm text-white" : "rounded-bl-sm bg-white border"}`}
        style={{
          background: isMe ? "#0F9B8E" : undefined,
          borderColor: isMe ? undefined : "#DCE6E2",
          color: isMe ? "white" : "#374151",
          boxShadow: "0 1px 2px rgba(0,0,0,0.06)",
        }}>
        {msg.text}
        <p className={`text-xs mt-1 ${isMe ? "text-white/70 text-right" : "text-gray-400"}`}>{msg.time}</p>
      </div>
    </div>
  );
}

function TypingIndicator() {
  return (
    <div className="flex items-end gap-2 mb-4">
      <div className="w-7 h-7 rounded-full bg-gray-200 flex items-center justify-center">
        <User size={13} className="text-gray-500" />
      </div>
      <div className="px-4 py-3 rounded-2xl rounded-bl-sm bg-white border" style={{ borderColor: "#DCE6E2" }}>
        <div className="flex gap-1 items-center h-4">
          {[0,1,2].map(i => (
            <span key={i} className="w-1.5 h-1.5 rounded-full bg-gray-300 animate-bounce"
              style={{ animationDelay: `${i*0.15}s` }} />
          ))}
        </div>
      </div>
    </div>
  );
}

/* ─── Main page ───────────────────────────────────────────────── */

export default function MessagingPage() {
  const { role } = useRole();
  const t = useT();

  const isPlatformAdmin = role === "platform_admin";
  const threads    = isPlatformAdmin ? disputeThreads : agentThreads;
  const senderType = isPlatformAdmin ? "client" : "agent";

  const [activeId,    setActiveId]    = useState(threads[0].id);
  const [allThreads,  setAllThreads]  = useState(threads);
  const [input,       setInput]       = useState("");
  const [typing,      setTyping]      = useState(false);
  const [search,      setSearch]      = useState("");
  const messagesEndRef = useRef(null);

  const activeThread = allThreads.find(th => th.id === activeId);
  const filtered     = allThreads.filter(th =>
    th.name.toLowerCase().includes(search.toLowerCase()) ||
    th.tag.toLowerCase().includes(search.toLowerCase())
  );

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [activeThread?.messages, typing]);

  const sendMessage = () => {
    if (!input.trim()) return;
    const now = new Date();
    const timeStr = `${String(now.getHours()).padStart(2,"0")}:${String(now.getMinutes()).padStart(2,"0")}`;
    const newMsg = { id: Date.now(), from: "me", text: input.trim(), time: timeStr };
    setAllThreads(prev => prev.map(th =>
      th.id === activeId ? { ...th, preview: input.trim(), messages: [...th.messages, newMsg], unread: 0 } : th
    ));
    setInput("");
    setTyping(true);
    setTimeout(() => {
      setTyping(false);
      const bank = isPlatformAdmin ? botRepliesFr.client : botRepliesFr.agent;
      const reply = { id: Date.now()+1, from: senderType, text: bank[Math.floor(Math.random()*bank.length)], time: timeStr };
      setAllThreads(prev => prev.map(th =>
        th.id === activeId ? { ...th, preview: reply.text, messages: [...th.messages, reply] } : th
      ));
    }, 1500);
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); sendMessage(); }
  };

  return (
    <div>
      <PageHeader
        title={t("msg.title")}
        subtitle={isPlatformAdmin ? t("msg.platSubtitle") : t("msg.pharmaSubtitle")}
      />

      <div className="bg-white rounded-2xl border overflow-hidden flex" style={{ borderColor: "#DCE6E2", height: "calc(100vh - 200px)", minHeight: "500px" }}>

        {/* Thread list */}
        <div className="w-72 xl:w-80 flex flex-col border-r shrink-0" style={{ borderColor: "#DCE6E2" }}>
          <div className="p-3 border-b" style={{ borderColor: "#DCE6E2" }}>
            <div className="relative">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                placeholder={isPlatformAdmin ? t("msg.searchDisputePh") : t("msg.searchAgentPh")}
                value={search}
                onChange={e => setSearch(e.target.value)}
                className="w-full pl-8 pr-3 py-2 rounded-lg border text-xs outline-none"
                style={{ borderColor: "#DCE6E2", background: "#F6F5EF" }}
              />
            </div>
          </div>
          <div className="px-4 pt-3 pb-2">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">
              {isPlatformAdmin ? t("msg.activeDisputes") : t("msg.agents")}
            </p>
          </div>
          <div className="flex-1 overflow-y-auto">
            {filtered.map(th => (
              <ThreadItem
                key={th.id} thread={th} active={th.id === activeId}
                onClick={() => {
                  setAllThreads(prev => prev.map(x => x.id === th.id ? {...x, unread: 0} : x));
                  setActiveId(th.id);
                }}
              />
            ))}
          </div>
        </div>

        {/* Chat area */}
        {activeThread && (
          <div className="flex-1 flex flex-col">
            <div className="px-5 py-4 border-b flex items-center gap-3" style={{ borderColor: "#DCE6E2" }}>
              <div className="w-9 h-9 rounded-full flex items-center justify-center text-white font-bold text-sm shrink-0"
                style={{ background: activeThread.avatarBg }}>
                {activeThread.avatar}
              </div>
              <div>
                <p className="font-semibold text-sm" style={{ color: "#0D3B36" }}>{activeThread.name}</p>
                <span className="inline-flex text-xs px-2 py-0.5 rounded-full font-medium"
                  style={{ background: activeThread.tagBg, color: activeThread.tagColor }}>
                  {activeThread.tag}
                </span>
              </div>
              <div className="ml-auto flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-green-400 animate-pulse" />
                <span className="text-xs text-gray-400">{t("msg.online")}</span>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-5" style={{ background: "#F6F5EF" }}>
              {activeThread.messages.length === 0 && (
                <div className="text-center py-12">
                  <Package size={32} className="mx-auto mb-2 text-gray-300" />
                </div>
              )}
              {activeThread.messages.map(msg => (
                <MessageBubble key={msg.id} msg={msg} senderType={senderType} />
              ))}
              {typing && <TypingIndicator />}
              <div ref={messagesEndRef} />
            </div>

            <div className="p-4 border-t bg-white" style={{ borderColor: "#DCE6E2" }}>
              {isPlatformAdmin && activeThread.id === "thread-lit101" && (
                <div className="mb-3 p-2.5 rounded-lg flex items-center gap-2 text-xs border-l-4"
                  style={{ background: "#FEF3DC", borderLeftColor: "#E8A33D" }}>
                  <AlertTriangle size={13} style={{ color: "#E8A33D" }} />
                  <span style={{ color: "#0D3B36" }}>{t("msg.priority")}</span>
                </div>
              )}
              <div className="flex gap-3 items-end">
                <textarea
                  rows={1}
                  value={input}
                  onChange={e => setInput(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder={t("msg.inputPh")}
                  className="flex-1 resize-none px-4 py-2.5 rounded-xl border text-sm outline-none transition-all"
                  style={{ borderColor: "#DCE6E2", background: "#F6F5EF", maxHeight: "100px" }}
                />
                <button onClick={sendMessage} disabled={!input.trim()}
                  className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-all hover:opacity-90 active:scale-95 disabled:opacity-40"
                  style={{ background: "#0F9B8E" }}>
                  <Send size={16} className="text-white" />
                </button>
              </div>
              <p className="text-xs text-gray-400 mt-2 text-right">{t("msg.enterHint")}</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
