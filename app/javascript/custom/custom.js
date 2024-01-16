let dialog = document.getElementById("dialog");
let closer = document.getElementById("closer");

// フラッシュメッセージを取得できれば問題が解決する
let notice = document.getElementById("notice");
let alert = document.getElementById("alert");

console.log(notice);
console.log(alert);

if (notice.textContent || alert.textContent) {
  dialog.classList.add("inview");
}

closer.addEventListener("click", () => {
  dialog.classList.remove("inview");
}, false);
