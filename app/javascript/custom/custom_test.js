document.addEventListener('turbo:load', () => {
  let dialog = document.getElementById("dialog");
  let noticeElement = document.getElementById("notice");
  let closer = document.getElementById("closer");

  if (!dialog || !noticeElement || !closer) return;

  let noticeText = noticeElement.textContent.trim();
  if (noticeText) {
    console.log("Notice:", noticeText);
    setTimeout(() => {
      dialog.classList.add("inview");
    }, 1000);
  }

  closer.removeEventListener("click", closeDialog);
  closer.addEventListener("click", closeDialog);

  setTimeout(closeDialog, 5000);
});

document.addEventListener("turbo:submit-end", (event) => {
  setTimeout(() => {
    let dialog = document.getElementById("dialog");
    let alertElement = document.getElementById("alert");

    if (!dialog || !alertElement) return;

    let alertText = alertElement.textContent.trim();
    if (alertText) {
      console.log("Alert:", alertText);
      dialog.classList.add("inview");
      setTimeout(closeDialog, 5000);
    }
  }, 50); // 少し待ってから取得
});

function closeDialog() {
  let dialog = document.getElementById("dialog");
  if (dialog) {
    dialog.classList.remove("inview");
  }
}
