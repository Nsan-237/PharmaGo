import React, { createContext, useContext, useState } from "react";
import en from "./en";
import fr from "./fr";

const translations = { en, fr };

const TranslationContext = createContext();

export function TranslationProvider({ children }) {
  // Default to French (Cameroon-first)
  const [lang, setLang] = useState("fr");

  // t(key) — look up a translation key, fall back to the key itself
  const t = (key) => translations[lang][key] ?? translations["en"][key] ?? key;

  return (
    <TranslationContext.Provider value={{ lang, setLang, t }}>
      {children}
    </TranslationContext.Provider>
  );
}

// Primary hook — returns the translator function
export function useT() {
  const ctx = useContext(TranslationContext);
  if (!ctx) throw new Error("useT must be used inside <TranslationProvider>");
  return ctx.t;
}

// Language control hook — returns { lang, setLang }
export function useLang() {
  const ctx = useContext(TranslationContext);
  if (!ctx) throw new Error("useLang must be used inside <TranslationProvider>");
  return { lang: ctx.lang, setLang: ctx.setLang };
}
