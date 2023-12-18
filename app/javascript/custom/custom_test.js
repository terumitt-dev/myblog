const opener = document.getElementById("opener");
const dialog = document.getElementById("dialog");
const closer = document.getElementById("closer");

opener.addEventListener("click", () => {
  dialog.classList.add("inview");
}, false);

closer.addEventListener("click", () => {
  dialog.classList.remove("inview");
}, false);
