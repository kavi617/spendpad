import {siteConfig, apkUrl, releaseUrl} from './config.js';

const screens=[
  {title:'Home dashboard',file:'01-home.png',alt:'SpendPad home dashboard with spending summary and recent activity',feature:0},
  {title:'Expense history',file:'02-history.png',alt:'SpendPad expense history screen',feature:0},
  {title:'Spending insights',file:'03-insights.png',alt:'SpendPad analytics and spending insights',feature:1},
  {title:'Settings',file:'04-settings.png',alt:'SpendPad settings and preferences',feature:2},
  {title:'Add an expense',file:'05-add-expense.png',alt:'SpendPad form for adding an expense',feature:0},
];
const featureData=[
  ['Track spending','Add, edit, and review expenses with categories, notes, and dates. A recent activity list keeps the latest entries close.'],
  ['See your patterns','Explore reports with period comparisons, category breakdowns, charts, and spending insights.'],
  ['Make it yours','Create and organize custom categories, choose their icons, and set preferences such as your currency.'],
  ['Keep your data','Your expenses are stored locally. Export a JSON backup to save or share a copy, and import one when you need to restore.'],
];
const shotPath=(file)=>`assets/screenshots/${file}`;
let selected=0;
const galleryImage=document.querySelector('[data-gallery-image]');
const thumbs=document.querySelector('.thumbnails');
const dialog=document.querySelector('.lightbox');
const prefersReduced=matchMedia('(prefers-reduced-motion: reduce)');

function changeScreen(index){selected=(index+screens.length)%screens.length;const screen=screens[selected];galleryImage.style.opacity='0';setTimeout(()=>{galleryImage.src=shotPath(screen.file);galleryImage.alt=screen.alt;galleryImage.style.opacity='1';},prefersReduced.matches?0:120);document.querySelector('[data-gallery-caption]').textContent=screen.title;document.querySelector('[data-gallery-counter]').textContent=`${String(selected+1).padStart(2,'0')} / ${String(screens.length).padStart(2,'0')}`;document.querySelectorAll('.thumb').forEach((el,i)=>el.setAttribute('aria-selected',String(i===selected)));const hero=document.querySelector('#hero-shot');hero.src=shotPath(screen.file);hero.alt=screen.alt;document.querySelector('.preview-note span').textContent=`${String(selected+1).padStart(2,'0')} / ${String(screens.length).padStart(2,'0')}`;}
screens.forEach((screen,index)=>{const button=document.createElement('button');button.className='thumb';button.setAttribute('role','tab');button.setAttribute('aria-label',screen.title);button.setAttribute('aria-selected',String(index===0));button.innerHTML=`<img src="${shotPath(screen.file)}" alt="" loading="lazy">`;button.addEventListener('click',()=>changeScreen(index));thumbs.append(button);});
document.querySelectorAll('.gallery-arrow').forEach(b=>b.addEventListener('click',()=>changeScreen(selected+(b.classList.contains('prev')?-1:1))));
document.querySelector('.preview-next').addEventListener('click',()=>{changeScreen(selected+1);document.querySelector('#screenshots').scrollIntoView({behavior:prefersReduced.matches?'instant':'smooth'});});
const lightboxImage=dialog.querySelector('img');
function openLightbox(){lightboxImage.src=shotPath(screens[selected].file);lightboxImage.alt=screens[selected].alt;dialog.querySelector('p').textContent=screens[selected].title;dialog.showModal();}
document.querySelector('.gallery-image').addEventListener('click',openLightbox);
dialog.querySelector('.lightbox-close').addEventListener('click',()=>dialog.close());
dialog.addEventListener('click',e=>{if(e.target===dialog)dialog.close();});
dialog.querySelectorAll('.lightbox-arrow').forEach(b=>b.addEventListener('click',()=>{changeScreen(selected+(b.classList.contains('prev')?-1:1));openLightbox();}));
document.addEventListener('keydown',e=>{if(!dialog.open)return;if(e.key==='ArrowRight')changeScreen(selected+1);if(e.key==='ArrowLeft')changeScreen(selected-1);});

function chooseFeature(index){index=(index+featureData.length)%featureData.length;document.querySelectorAll('.feature-tab').forEach((tab,i)=>{tab.classList.toggle('active',i===index);tab.setAttribute('aria-selected',String(i===index));});document.querySelector('[data-feature-count]').innerHTML=`${String(index+1).padStart(2,'0')} <i>/ 04</i>`;document.querySelector('[data-feature-title]').textContent=featureData[index][0];document.querySelector('[data-feature-description]').textContent=featureData[index][1];const screenIndex=screens.findIndex(s=>s.feature===index);if(screenIndex>=0)changeScreen(screenIndex);}
document.querySelectorAll('.feature-tab').forEach(tab=>tab.addEventListener('click',()=>chooseFeature(Number(tab.dataset.index))));
document.querySelector('[data-feature-prev]').addEventListener('click',()=>{const i=Number(document.querySelector('.feature-tab.active').dataset.index);chooseFeature(i-1);});
document.querySelector('[data-feature-next]').addEventListener('click',()=>{const i=Number(document.querySelector('.feature-tab.active').dataset.index);chooseFeature(i+1);});
document.querySelectorAll('.feature-tab').forEach(tab=>tab.addEventListener('keydown',e=>{if(['ArrowRight','ArrowDown'].includes(e.key)){e.preventDefault();const n=(Number(tab.dataset.index)+1)%4;chooseFeature(n);document.querySelector(`[data-index="${n}"]`).focus();}if(['ArrowLeft','ArrowUp'].includes(e.key)){e.preventDefault();const n=(Number(tab.dataset.index)+3)%4;chooseFeature(n);document.querySelector(`[data-index="${n}"]`).focus();}}));

const menu=document.querySelector('.menu-toggle');menu.addEventListener('click',()=>{const nav=document.querySelector('#nav');const open=nav.classList.toggle('open');menu.setAttribute('aria-expanded',String(open));});document.querySelectorAll('#nav a').forEach(a=>a.addEventListener('click',()=>{document.querySelector('#nav').classList.remove('open');menu.setAttribute('aria-expanded','false');}));
document.querySelectorAll('[data-version]').forEach(el=>el.textContent=`Version ${siteConfig.version}`);
document.querySelectorAll('[data-compatibility]').forEach(el=>el.textContent=siteConfig.minAndroid.replace('Android ','')+' and up');
document.querySelector('[data-year]').textContent=new Date().getFullYear();
if(apkUrl){document.querySelectorAll('[data-apk]').forEach(a=>{a.href=apkUrl;a.setAttribute('download',siteConfig.apkAsset);});document.querySelector('[data-release-status]').textContent=`Version ${siteConfig.version} · ${siteConfig.apkSize||'APK download'}`;document.querySelector('[data-release]').href=releaseUrl;document.querySelector('[data-release]').target='_blank';document.querySelector('[data-release]').rel='noopener';}else{document.querySelectorAll('[data-apk]').forEach(a=>{a.setAttribute('aria-disabled','true');a.setAttribute('aria-label','APK release not published yet');a.addEventListener('click',e=>e.preventDefault());});document.querySelector('[data-release]').href=siteConfig.repository+'/releases';document.querySelector('[data-release]').target='_blank';document.querySelector('[data-release]').rel='noopener';document.querySelector('[data-release-status]').textContent='Version 1.0.0 · release not published yet';}
if('IntersectionObserver'in window&&!prefersReduced.matches){const observer=new IntersectionObserver(entries=>entries.forEach(entry=>{if(entry.isIntersecting){entry.target.classList.add('visible');observer.unobserve(entry.target);}}),{threshold:.12});document.querySelectorAll('.reveal').forEach(el=>observer.observe(el));}else document.querySelectorAll('.reveal').forEach(el=>el.classList.add('visible'));
