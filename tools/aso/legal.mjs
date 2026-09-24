#!/usr/bin/env node
/**
 * The subscription terms and the Terms of Use link at the foot of every description.
 *
 *   node tools/aso/legal.mjs <slug>           # write the block into every localization
 *   node tools/aso/legal.mjs <slug> --check   # exit 1 if any localization lacks it
 *
 * Guideline 3.1.2 wants a functional link to the Terms of Use (EULA) in the metadata of any
 * app that sells an auto-renewable subscription. Having it on the paywall and in Settings is
 * not enough: App Review reads the product page, and quizday 1.0 was stopped on 24 Sep 2026
 * by an automated check for exactly this. Apple's standard EULA has no field of its own in
 * App Store Connect, so the link goes in the description.
 *
 * The block is generated, never written by an agent: the renewal wording is legal text, and
 * one place pins it. It is the last paragraph of the description, starting at the localized
 * heading below, so running this again replaces it rather than stacking a second copy.
 * An app with no auto-renewable product is left alone and passes the check.
 */
import fs from "node:fs";
import path from "node:path";

const [slug, ...flags] = process.argv.slice(2);
const check = flags.includes("--check");
if (!slug) {
  console.error("usage: legal.mjs <slug> [--check]");
  process.exit(2);
}

const app = path.join("apps", slug);
const meta = path.join(app, "store", "metadata");

// Only auto-renewable products need it; a one-time unlock does not.
const storekit = path.join(app, "ios", "App", "Products.storekit");
const subscribes = fs.existsSync(storekit) && /"recurringSubscriptionPeriod"/.test(fs.readFileSync(storekit, "utf8"));
if (!subscribes) {
  console.log(`${slug}: no auto-renewable subscription, so no Terms of Use block is needed`);
  process.exit(0);
}

// The same URL the paywall and Settings link to, so the three can never disagree.
const appInfo = path.join(app, "ios", "App", "AppInfo.swift");
const terms = fs.existsSync(appInfo) && fs.readFileSync(appInfo, "utf8").match(/termsURL:\s*URL\(string:\s*"([^"]+)"/)?.[1];
if (!terms) {
  console.error(`${slug}: no termsURL in ${appInfo}; the paywall has nothing to link to either`);
  process.exit(1);
}

const TEXT = {
  "en-US": {
    heading: "Subscription terms",
    body: "Payment is charged to your Apple Account when you confirm the purchase. The subscription renews automatically unless you cancel it at least 24 hours before the end of the current period, and your account is charged for the renewal within the 24 hours before it ends. Manage or cancel it any time in your Apple Account settings. If a free trial is offered, any unused part of it ends when you buy a subscription.",
    terms: "Terms of Use (EULA)", privacy: "Privacy Policy",
  },
  "es-MX": {
    heading: "Términos de la suscripción",
    body: "El pago se carga a tu Cuenta de Apple al confirmar la compra. La suscripción se renueva automáticamente a menos que la canceles al menos 24 horas antes de que termine el período actual, y la renovación se cobra dentro de las 24 horas previas a ese final. Puedes gestionarla o cancelarla cuando quieras en la configuración de tu Cuenta de Apple. Si se ofrece una prueba gratuita, la parte que no uses termina al comprar una suscripción.",
    terms: "Términos de uso (EULA)", privacy: "Política de privacidad",
  },
  "fr-FR": {
    heading: "Conditions de l'abonnement",
    body: "Le paiement est débité de votre compte Apple à la confirmation de l'achat. L'abonnement se renouvelle automatiquement, sauf si vous l'annulez au moins 24 heures avant la fin de la période en cours ; le renouvellement est débité dans les 24 heures qui précèdent cette échéance. Vous pouvez le gérer ou l'annuler à tout moment dans les réglages de votre compte Apple. Si un essai gratuit est proposé, la partie non utilisée prend fin à l'achat d'un abonnement.",
    terms: "Conditions d'utilisation (CLUF)", privacy: "Politique de confidentialité",
  },
  "pt-BR": {
    heading: "Termos da assinatura",
    body: "O pagamento é cobrado na sua Conta Apple ao confirmar a compra. A assinatura é renovada automaticamente, a menos que seja cancelada pelo menos 24 horas antes do fim do período atual, e a renovação é cobrada nas 24 horas anteriores a esse fim. Gerencie ou cancele quando quiser nos ajustes da sua Conta Apple. Se houver um teste gratuito, a parte não utilizada termina quando você comprar uma assinatura.",
    terms: "Termos de Uso (EULA)", privacy: "Política de Privacidade",
  },
  ru: {
    heading: "Условия подписки",
    body: "Оплата списывается с вашего Аккаунта Apple при подтверждении покупки. Подписка продлевается автоматически, если не отменить её не позднее чем за 24 часа до конца текущего периода; плата за продление списывается в течение 24 часов до его окончания. Управлять подпиской и отменить её можно в любой момент в настройках Аккаунта Apple. Если предлагается бесплатный пробный период, его неиспользованная часть сгорает при покупке подписки.",
    terms: "Условия использования (EULA)", privacy: "Политика конфиденциальности",
  },
  vi: {
    heading: "Điều khoản gói đăng ký",
    body: "Khoản thanh toán được tính vào Tài khoản Apple của bạn khi bạn xác nhận mua. Gói đăng ký tự động gia hạn trừ khi bạn hủy ít nhất 24 giờ trước khi kỳ hiện tại kết thúc, và phí gia hạn được tính trong vòng 24 giờ trước khi kỳ đó kết thúc. Bạn có thể quản lý hoặc hủy bất cứ lúc nào trong cài đặt Tài khoản Apple. Nếu có dùng thử miễn phí, phần chưa dùng sẽ kết thúc khi bạn mua gói đăng ký.",
    terms: "Điều khoản sử dụng (EULA)", privacy: "Chính sách quyền riêng tư",
  },
  ko: {
    heading: "구독 약관",
    body: "결제 금액은 구입을 확인할 때 Apple 계정으로 청구됩니다. 현재 기간이 끝나기 최소 24시간 전에 취소하지 않으면 구독이 자동으로 갱신되며, 갱신 요금은 기간 종료 전 24시간 이내에 청구됩니다. 언제든지 Apple 계정 설정에서 구독을 관리하거나 취소할 수 있습니다. 무료 체험이 제공되는 경우, 구독을 구입하면 체험 기간의 남은 부분은 소멸됩니다.",
    terms: "이용 약관(EULA)", privacy: "개인정보 처리방침",
  },
  "zh-Hans": {
    heading: "订阅条款",
    body: "确认购买时将从你的 Apple 账户扣款。除非在当前周期结束前至少 24 小时取消，订阅将自动续期，续期费用会在周期结束前 24 小时内扣除。你可以随时在 Apple 账户设置中管理或取消订阅。如提供免费试用，购买订阅后试用期的剩余部分将失效。",
    terms: "使用条款（EULA）", privacy: "隐私政策",
  },
  "zh-Hant": {
    heading: "訂閱條款",
    body: "確認購買時將向你的 Apple 帳號收費。除非在目前週期結束前至少 24 小時取消，訂閱將自動續訂，續訂費用會在週期結束前 24 小時內收取。你可以隨時在 Apple 帳號設定中管理或取消訂閱。如提供免費試用，購買訂閱後試用期的剩餘部分將失效。",
    terms: "使用條款（EULA）", privacy: "隱私權政策",
  },
  "ar-SA": {
    heading: "شروط الاشتراك",
    body: "يُخصم المبلغ من حساب Apple الخاص بك عند تأكيد الشراء. يتجدد الاشتراك تلقائيًا ما لم تُلغه قبل 24 ساعة على الأقل من نهاية الفترة الحالية، ويُحتسب رسم التجديد خلال الـ 24 ساعة السابقة لنهايتها. يمكنك إدارة الاشتراك أو إلغاؤه في أي وقت من إعدادات حساب Apple. إذا توفرت فترة تجريبية مجانية، ينتهي الجزء غير المستخدم منها عند شراء اشتراك.",
    terms: "شروط الاستخدام (EULA)", privacy: "سياسة الخصوصية",
  },
};

const locales = JSON.parse(fs.readFileSync(path.join("tools", "aso", "locales.json"), "utf8")).locales.map((l) => l.code);
let bad = 0;

for (const loc of locales) {
  const t = TEXT[loc];
  const file = path.join(meta, loc, "description.txt");
  if (!t) { console.error(`${loc}: no Terms of Use wording in tools/aso/legal.mjs; add it`); bad++; continue; }
  if (!fs.existsSync(file)) { console.error(`${loc}: no ${file}`); bad++; continue; }
  const privacyFile = path.join(meta, loc, "privacy_url.txt");
  const privacy = fs.existsSync(privacyFile) ? fs.readFileSync(privacyFile, "utf8").trim() : "";

  const block = [t.heading, t.body, "", `${t.terms}: ${terms}`, ...(privacy ? [`${t.privacy}: ${privacy}`] : [])].join("\n");
  const current = fs.readFileSync(file, "utf8").replace(/\r\n/g, "\n").trim();

  if (check) {
    if (current.includes(terms)) console.log(`  ok   ${loc}: links the Terms of Use`);
    else { console.error(`${loc}: description.txt has no link to the Terms of Use (${terms}). Run: node tools/aso/legal.mjs ${slug}`); bad++; }
    continue;
  }

  // Replace a block written earlier; everything above the heading is the agent's copy.
  const at = current.lastIndexOf(`\n${t.heading}\n`);
  const copy = (at >= 0 ? current.slice(0, at) : current).trim();
  const next = `${copy}\n\n${block}`;
  const n = [...next].length;
  if (n > 4000) { console.error(`${loc}: the description would be ${n} characters with the terms, limit 4000; shorten the copy`); bad++; continue; }
  fs.writeFileSync(file, next);
  console.log(`  ${next === current ? "ok   " : "wrote"} ${loc}: ${n}/4000`);
}

if (bad) process.exit(1);
