import {siteConfig, apkUrl, releaseUrl} from './config.js';

const screens=[
  {title:'Home dashboard',file:'01-home.png',alt:'SpendPad home dashboard with spending summary and recent activity',feature:0},
  {title:'Expense history',file:'02-history.png',alt:'SpendPad expense history screen',feature:0},
  {title:'Spending insights',file:'03-insights.png',alt:'SpendPad analytics and spending insights',feature:1},
  {title:'Settings',file:'04-settings.png',alt:'SpendPad settings and preferences',feature:2},
  {title:'Add an expense',file:'05-add-expense.png',alt:'SpendPad form for adding an expense',feature:0},
];
const featureData=[
  ['Expenses','Log a coffee, grocery run, or bill with an amount, category, date, and note. Find it later in your history.'],
  ['Reports','Check how much you spent this month, compare periods, and see which categories make up the total.'],
  ['Categories','Group purchases your way—like Food, Transport, or Bills—and choose an icon for each category.'],
  ['Backup & restore','Keep your records on your device. Export a JSON backup, then import it later to restore your expenses.'],
];
const shotPath=(file)=>`assets/screenshots/${file}`;
let selected=0;
const dialog=document.querySelector('.lightbox');
const prefersReduced=matchMedia('(prefers-reduced-motion: reduce)');

function changeScreen(index){selected=(index+screens.length)%screens.length;const screen=screens[selected],hero=document.querySelector('#hero-shot'),preview=document.querySelector('.device-screen');if(prefersReduced.matches){hero.src=shotPath(screen.file);}else{preview.classList.add('is-changing');setTimeout(()=>{hero.src=shotPath(screen.file);requestAnimationFrame(()=>preview.classList.remove('is-changing'));},110);}hero.alt=screen.alt;preview.setAttribute('aria-label',`Open ${screen.title} screenshot`);document.querySelector('.preview-note span').textContent=`${String(selected+1).padStart(2,'0')} / ${String(screens.length).padStart(2,'0')}`;}
document.querySelector('.preview-next').addEventListener('click',()=>changeScreen(selected+1));
const demoForm=document.querySelector('#entry-demo'),demoAmount=document.querySelector('#demo-amount'),demoFields=demoForm.querySelector('.demo-fields'),demoSuccess=demoForm.querySelector('.demo-success');
demoForm.querySelectorAll('.demo-categories button').forEach(button=>button.addEventListener('click',()=>{demoForm.querySelectorAll('.demo-categories button').forEach(option=>{const active=option===button;option.classList.toggle('selected',active);option.setAttribute('aria-pressed',String(active));});}));
demoForm.addEventListener('submit',event=>{event.preventDefault();const amount=Number(demoAmount.value);if(!Number.isFinite(amount)||amount<=0){demoAmount.setCustomValidity('Enter an amount greater than zero.');demoAmount.reportValidity();return;}demoAmount.setCustomValidity('');const category=demoForm.querySelector('.demo-categories .selected').textContent;demoForm.querySelector('[data-demo-saved-amount]').textContent=`₹${new Intl.NumberFormat('en-IN',{maximumFractionDigits:2}).format(amount)}`;demoForm.querySelector('[data-demo-saved-category]').textContent=category;demoFields.hidden=true;demoSuccess.hidden=false;demoForm.classList.add('is-saved');});
demoAmount.addEventListener('input',()=>demoAmount.setCustomValidity(''));
demoForm.querySelector('.demo-again').addEventListener('click',()=>{demoForm.reset();demoAmount.value='420';demoForm.querySelector('#demo-note').value='Lunch with friends';demoForm.querySelectorAll('.demo-categories button').forEach((option,index)=>{option.classList.toggle('selected',index===0);option.setAttribute('aria-pressed',String(index===0));});demoSuccess.hidden=true;demoFields.hidden=false;demoForm.classList.remove('is-saved');});
const lightboxImage=dialog.querySelector('img');
function openLightbox(){lightboxImage.src=shotPath(screens[selected].file);lightboxImage.alt=screens[selected].alt;dialog.querySelector('p').textContent=screens[selected].title;dialog.showModal();}
const preview=document.querySelector('.device-screen');
preview.addEventListener('click',openLightbox);
let previewTouchStart=null,swipeChangedScreen=false;
preview.addEventListener('pointerdown',e=>{previewTouchStart={x:e.clientX,y:e.clientY};swipeChangedScreen=false;preview.setPointerCapture(e.pointerId);});
preview.addEventListener('pointerup',e=>{if(!previewTouchStart)return;const dx=e.clientX-previewTouchStart.x,dy=e.clientY-previewTouchStart.y;previewTouchStart=null;if(Math.abs(dx)>36&&Math.abs(dx)>Math.abs(dy)){swipeChangedScreen=true;changeScreen(selected+(dx<0?1:-1));}});
preview.addEventListener('pointercancel',()=>{previewTouchStart=null;});
preview.addEventListener('click',e=>{if(swipeChangedScreen){e.preventDefault();e.stopImmediatePropagation();swipeChangedScreen=false;}},true);
dialog.querySelector('.lightbox-close').addEventListener('click',()=>dialog.close());
dialog.addEventListener('click',e=>{if(e.target===dialog)dialog.close();});
dialog.querySelectorAll('.lightbox-arrow').forEach(b=>b.addEventListener('click',()=>{changeScreen(selected+(b.classList.contains('prev')?-1:1));openLightbox();}));
document.addEventListener('keydown',e=>{if(!dialog.open)return;if(e.key==='ArrowRight')changeScreen(selected+1);if(e.key==='ArrowLeft')changeScreen(selected-1);});

function chooseFeature(index){index=(index+featureData.length)%featureData.length;document.querySelectorAll('.feature-tab').forEach((tab,i)=>{tab.classList.toggle('active',i===index);tab.setAttribute('aria-selected',String(i===index));tab.tabIndex=i===index?0:-1;});document.querySelector('[data-feature-count]').innerHTML=`${String(index+1).padStart(2,'0')} <i>/ 04</i>`;document.querySelector('[data-feature-title]').textContent=featureData[index][0];document.querySelector('[data-feature-description]').textContent=featureData[index][1];const screenIndex=screens.findIndex(s=>s.feature===index);if(screenIndex>=0)changeScreen(screenIndex);}
document.querySelectorAll('.feature-tab').forEach(tab=>tab.addEventListener('click',()=>chooseFeature(Number(tab.dataset.index))));
document.querySelector('[data-feature-prev]').addEventListener('click',()=>{const i=Number(document.querySelector('.feature-tab.active').dataset.index);chooseFeature(i-1);});
document.querySelector('[data-feature-next]').addEventListener('click',()=>{const i=Number(document.querySelector('.feature-tab.active').dataset.index);chooseFeature(i+1);});
document.querySelectorAll('.feature-tab').forEach(tab=>tab.addEventListener('keydown',e=>{if(['ArrowRight','ArrowDown'].includes(e.key)){e.preventDefault();const n=(Number(tab.dataset.index)+1)%4;chooseFeature(n);document.querySelector(`[data-index="${n}"]`).focus();}if(['ArrowLeft','ArrowUp'].includes(e.key)){e.preventDefault();const n=(Number(tab.dataset.index)+3)%4;chooseFeature(n);document.querySelector(`[data-index="${n}"]`).focus();}}));

const menu=document.querySelector('.menu-toggle');menu.addEventListener('click',()=>{const nav=document.querySelector('#nav');const open=nav.classList.toggle('open');menu.setAttribute('aria-expanded',String(open));});document.querySelectorAll('#nav a').forEach(a=>a.addEventListener('click',()=>{document.querySelector('#nav').classList.remove('open');menu.setAttribute('aria-expanded','false');}));
document.querySelectorAll('[data-version]').forEach(el=>el.textContent=`Version ${siteConfig.version}`);
document.querySelectorAll('[data-compatibility]').forEach(el=>el.textContent=siteConfig.minAndroid.replace('Android ','')+' and up');
document.querySelector('[data-year]').textContent=new Date().getFullYear();
if(apkUrl){document.querySelectorAll('[data-apk]').forEach(a=>{a.href=apkUrl;a.setAttribute('download',siteConfig.apkAsset);});document.querySelector('[data-release-status]').textContent=`Version ${siteConfig.version} · ${siteConfig.apkSize||'APK download'}`;document.querySelector('[data-release]').href=releaseUrl;document.querySelector('[data-release]').target='_blank';document.querySelector('[data-release]').rel='noopener';}else{document.querySelectorAll('[data-apk]').forEach(a=>{a.setAttribute('aria-disabled','true');a.setAttribute('aria-label','APK release not published yet');a.addEventListener('click',e=>e.preventDefault());});document.querySelector('[data-release]').href=siteConfig.repository+'/releases';document.querySelector('[data-release]').target='_blank';document.querySelector('[data-release]').rel='noopener';document.querySelector('[data-release-status]').textContent='Version 1.0.0 · release not published yet';}
const mobileDownload=document.querySelector('.mobile-download');
if('IntersectionObserver'in window){let heroVisible=true,downloadVisible=false;const updateStickyCta=()=>{const show=!heroVisible&&!downloadVisible;mobileDownload.classList.toggle('is-visible',show);mobileDownload.setAttribute('aria-hidden',String(!show));mobileDownload.inert=!show;};const ctaObserver=new IntersectionObserver(entries=>{for(const entry of entries){if(entry.target.id==='showcase')heroVisible=entry.isIntersecting;if(entry.target.id==='download')downloadVisible=entry.isIntersecting;}updateStickyCta();},{threshold:0.08});ctaObserver.observe(document.querySelector('#showcase'));ctaObserver.observe(document.querySelector('#download'));}
if('IntersectionObserver'in window&&!prefersReduced.matches){const observer=new IntersectionObserver(entries=>entries.forEach(entry=>{if(entry.isIntersecting){entry.target.classList.add('visible');observer.unobserve(entry.target);}}),{threshold:.12});document.querySelectorAll('.reveal').forEach(el=>observer.observe(el));}else document.querySelectorAll('.reveal').forEach(el=>el.classList.add('visible'));
