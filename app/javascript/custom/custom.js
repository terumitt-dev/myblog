document.addEventListener("turbo:load", () => {
  const dialog = document.getElementById("dialog");
  const noticeElement = document.getElementById("notice");
  const closer = document.getElementById("closer");

  if (!dialog || !noticeElement || !closer) return;

  let noticeText = noticeElement.textContent.trim();
  if (noticeText) {
    setTimeout(() => {
      dialog.classList.add("inview");
    }, 1000);
  }

  closer.addEventListener("click", closeDialog);
  setTimeout(closeDialog, 5000);
});

document.addEventListener("turbo:submit-end", () => {
  setTimeout(() => {
    let dialog = document.getElementById("dialog");
    let alertElement = document.getElementById("alert");

    if (!dialog || !alertElement) return;

    let alertText = alertElement.textContent.trim();
    if (alertText) {
      dialog.classList.add("inview");
      setTimeout(closeDialog, 5000);
    }
  }, 50);
});

function closeDialog() {
  document.getElementById("dialog")?.classList.remove("inview");
}
